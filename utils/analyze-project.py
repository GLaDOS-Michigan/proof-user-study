import sys
import csv
import datetime
import json
from git import Repo


def main(project_json):
    with open(project_json) as f:
        info = json.load(f)
        check_well_formed(info)
    files_info = parse_files_info(info)         # map of categories to list of filenames    
    timecard = parse_timecard_info(info)   # list of (start, end) tuples
    git_commits = get_git_commits(info)         # list of (timestamp, commit) objects
    
    # scaled_commits contains all the data I need to draw
    scaled_commits = scale_by_timecard(timecard, git_commits)
    visualize_data(scaled_commits)
    
    
def check_well_formed(info):
    assert 'project_path' in info
    assert 'timecard_path' in info
    assert 'repo_path' in info
    assert 'protocol_files' in info
    assert 'proof_files' in info
        
    
""" Returns a map of categories to list of filenames """
def parse_files_info(info):
    res = dict()
    res['protocol'] = info['protocol_files']
    res['proof'] = info['proof_files']
    return res


""" Returns a list of (start, end) tuples, sorted by start """
def parse_timecard_info(info):
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


""" Returns a list of (timestamp, commit) tuples, sorted by timestamp """
def get_git_commits(info):
    repo = Repo(info['repo_path'])
    assert not repo.bare
    commits = list(repo.iter_commits(paths=info['project_path']))
    
    # Timestamp each commit and sort
    timestamped_commits = []
    for c in commits[::-1]:
        timestamped_commits.append((c.committed_datetime, c))
    timestamped_commits.sort(key=lambda x: x[0])
    return timestamped_commits



""" Converts sorted timestamp list of (timestamp, X) into a list of (scaled_time, X) list,
    where scaled_time is seconds of work since genesis time, using Tony's proprietary 
    scaling algorithm
"""
def scale_by_timecard(timecard, timestamped_list):
    timestamped_list = scale_by_timecard_trim(timecard, timestamped_list)
    segment = timecard.pop(0)
    genesis = segment[0]        # the dawn of time
    next_end = segment[1]
    cumulative_downtime = 0     # downtime in seconds
    res = []
    for i in range(len(timestamped_list)):
        item = timestamped_list[i]
        t = item[0].replace(tzinfo=None)
        if t <= next_end:
            scaled_time = (t-genesis).total_seconds() - cumulative_downtime
            res.append((scaled_time, item[1]))
            i += 1
        else:
            if len(timecard) == 0:
                break
            old_end = next_end
            new_segment = timecard.pop(0)
            next_end = new_segment[1]
            cumulative_downtime += (new_segment[0]-old_end).total_seconds()
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
        
            
            
"""
    scaled_commits: list of (scaled_time, commit_object) tuple
"""
def visualize_data(scaled_commits):    
    
    
    
    


if __name__ == "__main__":
    # positional arguments <project's info.json>
    if len(sys.argv) < 2:
        print("Error: Expect json file as input")
        sys.exit(1)
    project_json = sys.argv[1]
    main(project_json)