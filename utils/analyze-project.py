import sys
import csv
import datetime
import json
from git import Repo
import matplotlib.pyplot as plt
from matplotlib.backends.backend_pdf import PdfPages


class Project_Metadata(object):
    def __init__(self):
        self.repo_path = None
        self.repo = None            # GitPython repo object
        self.project_path = None
        self.timecard = None        # list of (start, end) tuples
        self.files_info = None      # map of categories to list of filenames    
        
    def parse_from_json(project_json):
        def check_well_formed(info):
            assert 'repo_path' in info
            assert 'project_rel_path' in info
            assert 'timecard_path' in info
            assert 'protocol_files' in info
            assert 'proof_files' in info
        meta = Project_Metadata()
        with open(project_json) as f:
            info = json.load(f)
            check_well_formed(info)
        meta.repo_path = info['repo_path']
        meta.repo = Repo(meta.repo_path)
        meta.project_path = info['project_rel_path']
        meta.timecard = Project_Metadata.parse_timecard_info(info)       
        meta.files_info = Project_Metadata.parse_files_info(info)      
        assert not meta.repo.bare     
        return meta
    
    
    def parse_files_info(info):
        """ Returns a map of categories to list of filenames """
        res = dict()
        res['protocol'] = info['protocol_files']
        res['proof'] = info['proof_files']
        return res
    
   
    def parse_timecard_info(info):
         """ Returns a list of (start, end) tuples, sorted by start """
        res = []
        with open(info['timecard_path']) as f:
            csvreader = csv.reader(f, delimiter=',')
            next(csvreader)
            started = False
            entry_start = None
            for row in csvreader:
                kind, timestamp = row[0], datetime.datetime.strptime(row[1], '%m/%d/%Y %H:%M:%S %Z')
                if not started:
                    assert kind == 'start' and entry_start is None
                    started = True
                    entry_start = timestamp
                else:
                    assert kind == 'end' and entry_start is not None
                    res.append((entry_start, timestamp))
                    started = False
                    entry_start = None
            assert not started
        res.sort(key=lambda x: x[0])
        return res 
        


def main(project_json):
    meta = Project_Metadata.parse_from_json(project_json)
    git_commits = get_git_commits(meta)     # list of (timestamp, commit) objects
    # sanity_check(meta, git_commits)
    
    # scaled_commits contains all the data I need to draw
    scaled_commits = scale_by_timecard(meta.timecard, git_commits)
    visualize_data(meta, scaled_commits)
    

# """ Asserts that all modifications to protocol and proof files are done while punched-in"""
# def sanity_check(meta, git_commits):
    
    
    

def get_git_commits(meta):
    """ Returns a list of (timestamp, commit) tuples, sorted by timestamp """
    commits = list(meta.repo.iter_commits(paths=meta.project_path))
    
    # Timestamp each commit and sort
    timestamped_commits = []
    for c in commits[::-1]:
        timestamped_commits.append((c.committed_datetime, c))
    timestamped_commits.sort(key=lambda x: x[0])
    return timestamped_commits



def scale_by_timecard(timecard, timestamped_list):
    """ Converts sorted timestamp list of (timestamp, X) into a list of (timedelta, X) list,
        where timedelta is datetime.timedelta since genesis time, using Tony's proprietary 
        scaling algorithm
    """
    timestamped_list = scale_by_timecard_trim(timecard, timestamped_list)
    segment = timecard.pop(0)
    genesis = segment[0]        # the dawn of time
    (start, end) = segment      # start and end of this segment
    cumulative_downtime = datetime.timedelta()     # the zero interval
    res = []
    for i in range(len(timestamped_list)):
        item = timestamped_list[i]
        t = item[0].replace(tzinfo=None)
        if t < start:
            continue
        elif t <= end:
            scaled_time = (t-genesis) - cumulative_downtime
            res.append((scaled_time, item[1]))
            i += 1
        else:
            if len(timecard) == 0:
                break
            old_end = end
            new_segment = timecard.pop(0)
            (start, end) = new_segment
            cumulative_downtime += (new_segment[0]-old_end)
    return res


def scale_by_timecard_trim(timecard, timestamped_list):
    # Trim head and tail of timestamped_list to remove pre-genesis and post-completion entries
    genesis = timecard[0][0]        # the dawn of time
    big_freeze = timecard[-1][1]    # the end of time
    res = []
    for t in timestamped_list:
        ts = t[0].replace(tzinfo=None)
        if genesis <= ts and ts <= big_freeze:
            res.append(t)
    return res
        
            
def visualize_data(meta, scaled_commits):    
    """
    meta: Project_Metadata object
    scaled_commits: list of (timedelta, commit_object) tuples
    """
    time_vals_minutes = [t[0].total_seconds()/60 for t in scaled_commits]
    commits = [t[1] for t in scaled_commits]
    sha_labels = [c.name_rev[:6] for c in commits]  # label with commit sha
    
    # Get SLOC counts
    protocol_sloc_vals, proof_sloc_vals = extract_sloc(meta, commits)
    
    # Get diff stats, as list of (insertions, deletions, lines) tuples
    protocol_stats, proof_stats = extract_diff_stats(meta, commits)
        
    # Compute insertions and deletions
    protocol_inser = [t[0] for t in protocol_stats]
    protocol_dels = [t[1] for t in protocol_stats]
    proof_inser = [t[0] for t in proof_stats]
    proof_dels = [t[1] for t in proof_stats]
    
    # Draw graph
    with PdfPages("graph.pdf") as pp:
        fig, ax = plt.subplots(1, 1, figsize=(8.5, 6), sharex=True)
        fig.tight_layout()
        fig.subplots_adjust(left=0.08, top=0.9,bottom=0.1)
        fig.suptitle("Lines of Code", fontsize=12, fontweight='bold')
        ax.set_xlabel('time (minutes)')
        ax.set_ylabel('lines of code')
        ax.grid()
              
        # Plot proof insertions and deletions
        ax.bar(time_vals_minutes, proof_dels, 0.7, label='proof deletions', color='darkred')
        ax.bar(time_vals_minutes, proof_inser, 0.7, bottom=proof_dels, label='proof insertions', color='limegreen')
        ax.bar(time_vals_minutes, protocol_dels, 0.7, label='protocol deletions', color='orange')
        ax.bar(time_vals_minutes, protocol_inser, 0.7, bottom=proof_dels, label='protocol insertions', color='turquoise')
        
        # Plot sloc values
        ax.plot(time_vals_minutes, protocol_sloc_vals, label='protocol sloc', color='navy', linestyle='dashed', marker='o')
        ax.plot(time_vals_minutes, proof_sloc_vals, label='proof sloc', color='firebrick', linestyle='dashed', marker='o')

        # Add labels
        for i, sha in enumerate(sha_labels):
            ax.annotate(sha, (time_vals_minutes[i]-0.5, protocol_sloc_vals[i]+2), rotation='vertical')
        
        plt.legend()
        plt.close(fig)
        pp.savefig(fig)
        
    
    
def extract_sloc(meta, commits):
    """ Returns two lists, first contains the sloc of protocol code,
        and second contains the sloc of proof code.  """
    def count_lines(sha, f):
        git_show_arg = "%s:%s" %(sha, f)
        try: 
            file_snapshot = git.show(git_show_arg)
            return count_sloc(file_snapshot)  # does not count whitespace
            # return file_snapshot.count('\n')  # count whitespace
        except:
            return 0
    git = meta.repo.git
    protocol_res, proof_res = [], []
    for c in commits:
        protocol_lines = 0
        proof_lines = 0
        commit_sha = c.name_rev.split(' ')[0]
        for f in meta.files_info['protocol']:
            protocol_lines += count_lines(commit_sha, f)
        for f in meta.files_info['proof']:
            proof_lines += count_lines(commit_sha, f)
        protocol_res.append(protocol_lines)
        proof_res.append(proof_lines)
    return protocol_res, proof_res  


def extract_diff_stats(meta, commits):    
    """ Returns two lists, first contains the (insertions, deletions, lines) of protocol code,
        and second contains that of proof code.  """
    protocol_stats, proof_stats = [], []
    for c in commits:
        proof_inser, proof_del, proof_mod = 0, 0, 0
        proto_inser, proto_del, proto_mod = 0, 0, 0        
        stats = c.stats.files
        
        for f in meta.files_info['protocol']:
            if f in stats:
                proto_inser += stats[f]['insertions']
                proto_del += stats[f]['deletions']
                proto_mod += stats[f]['lines']
        for f in meta.files_info['proof']:
            if f in stats:
                proof_inser += stats[f]['insertions']
                proof_del += stats[f]['deletions']
                proof_mod += stats[f]['lines']
        protocol_stats.append((proto_inser, proto_del, proto_mod))
        proof_stats.append((proof_inser, proof_del, proof_mod))
    return protocol_stats, proof_stats
    


def count_sloc(program_str):
    """ Given the string representation of a program, return the SLOC """
    lines = program_str.split('\n')
    lines = [l.strip() for l in lines if len(l.strip()) > 0]
    physical_lines = []

    physical_mode = True
    for l in lines:
        # Strip comment lines
        if physical_mode:
            if "/*" in l:
                if "*/" not in l:   
                    # Begin multi-line comment
                    physical_mode = False
                else:
                    continue
            elif len(l) >= 2 and l[:2] == "//":
                continue
            else:
                physical_lines.append(l)
        else:
            if "*/" in l:
                # End multi-line comment
                physical_mode = True    
    # for l in physical_lines:
    #     print(l)
    return len(physical_lines)
    
    
if __name__ == "__main__":
    # positional arguments <project's info.json>
    if len(sys.argv) < 2:
        print("Error: Expect json file as input")
        sys.exit(1)
    project_json = sys.argv[1]
    main(project_json)