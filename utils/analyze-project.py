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
    timecard_info = parse_timecard_info(info)   # list of (start, end) tuples
    git_commits = get_git_commits(info)         # list of git commit objects
    # # visualize_data()
    
    
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


""" Returns a list of (start, end) tuples """
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
    return res 


""" Returns list of commit objects limited to project dir """
def get_git_commits(info):
    repo = Repo(info['repo_path'])
    assert not repo.bare
    commits = list(repo.iter_commits(paths=info['project_path']))
    print(commits[0].message)
    return commits


if __name__ == "__main__":
    # positional arguments <project's info.json>
    if len(sys.argv) < 2:
        print("Error: Expect json file as input")
        sys.exit(1)
    project_json = sys.argv[1]
    main(project_json)