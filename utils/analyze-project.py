import sys
import csv
import datetime

FILETYPES_CSV = "files.csv"
TIMECARD_CSV = "timecard.csv"

def main(project_dir):
    files_info = get_files_info(project_dir)            # map of categories to list of filenames    
    timecard_info = get_timecard_info(project_dir)      # list of (start, end) tuples
    print(timecard_info)
    
    
""" Returns a map of categories to list of filenames """
def get_files_info(project_dir):
    res = dict()
    with open("%s/%s" %(project_dir, FILETYPES_CSV)) as f:
        csvreader = csv.reader(f, delimiter=',')
        next(csvreader)
        for row in csvreader:
            kind, name = row[0], row[1]
            if kind not in res:
                res[kind] = []
            res[kind].append(name)
    return res


""" Returns a list of (start, end) tuples """
def get_timecard_info(project_dir):
    res = []
    with open("%s/%s" %(project_dir, TIMECARD_CSV)) as f:
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


if __name__ == "__main__":
    # positional arguments <project-directory>
    if len(sys.argv) < 2:
        print("Error: Expect project directory as input")
        sys.exit(1)
    project_dir = sys.argv[1]
    main(project_dir)