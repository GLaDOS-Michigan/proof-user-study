* `punch-in [path-to-timecard]` logs a timestamp in the timecard csv file
* `punch-out [path-to-timecard]` logs a timestamp in the timecard csv file
* `verify-and-commit -tag=[ "other" | "protocol" | "proof" ] [ commit message ] [files]` commits all files in the repo with the tag and commit message, and then verifies the files in Dafny


Each project should contain a json file that includes the following:

```json
{
    "repo_path" : path to git repo,
    "project_rel_path" : project path relative to repo_path,
    "timecard_path" : path to timecard,
    "protocol_files" : list of protocol files,
    "proof_files" : list of proof files
}
```