# Usage Guide

## Tracking a Project

### Project Info File
Each project to be analyzed must include a json file containing:

```json
{
    "repo_path" : "absolute path to directory containing git repo",
    "project_rel_path" : "project root dir relative to repo_path",
    "timecard_path" : "absolute path to timecard",
    "protocol_files" : ["list of protocol files relative to repo_path"],
    "proof_files" : ["list of proof files relative to repo_path"]
}
```

The script analyze-project.py uses:

* `repo_path` to find the .git file containing version control information for the project,
* `project_rel_path` to filter commits related to the project to be analyzed,
* `timecard_path` to track the think time for the project,
* `protocol_files` to identify files that count towards protocol code,
* `proof_files` to identify files that count towards proof code.

### Keeping Track of Think Time 
A project to be tracked must have a timecard.csv file logging the time spent on the project.
It contains timestamp information on when the user starts a period of work, and when the user 
ends a period of work, much like punching-in and -out of an office. To do so, one uses the 
scripts:

* `./utils/punch-in [path-to-timecard]` logs a timestamp in the timecard csv file
* `./utils/punch-out [path-to-timecard]` logs a timestamp in the timecard csv file

### Keeping Track of File Changes
To keep track of all changes in the project at a fine granularity, we automatically commit
to version control every time the verifier is invoked. Hence, whenever the user wishes to
verify a project file, they should use the script

```
verify-and-commit -tag=[ "other" | "protocol" | "proof" ] [ commit message ] [files]
```

This script is a dafny wrapper that 
1. commits all files in the repo with the tag and commit message, 
2. verifies the files in Dafny

Note that analyze-project.py script will complain if a change to a protocol or proof file is
made outside of work time logged in the project timecard.

## Analyzing a Project

The script analyze-project.py, called as

```
python3 analyze-project.py [project's info.json]
```

plots a graph illustrating the project's protocol and proof changes relative to think time, 
and prints a text summary of such changes.