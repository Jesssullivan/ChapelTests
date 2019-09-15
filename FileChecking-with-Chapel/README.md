
# Test FileCheck2.chpl from this repo:

```

git clone https://github.com/Jesssullivan/ChapelTests

cd ChapelTests/FileChecking-with-Chapel

# compile fastest / most up to date script:
chpl FileCheck2.chpl  # not annotated / no extra --args

# compile all options (old sync method, now archived):
chpl FileCheck.chpl

# evaluate 5 different run times:
python3 Timer_FileCheck.py

```

# Dealing with Dupes in Chapel

Generate three text docs:

- Same size, same file another
- Same size, different file
- Same size, less than 8 bytes

Please see the python3 evaluation scripts to run these options in a loop.  

# --Flags:


...Will run FileCheck with internal timers(--T), which will be displayed with the verbose logs(--V) and all extra debug logging(--debug) from within each loop.

# General notes:

From inside FileCheck2.chpl on updated sync$ syntax:

```
//  Chapel-Language  //

module Fs {
  var MasterDom = {("", "")};  // contains same size files as (a,b).
  var same = {("", "")};  // identical files
  var diff = {("", "")};  // sorted files flagged as same size but are not identical
  var sizeZero = {("", "")}; // sort files that are < 8 bytes
}

var sync1$ : sync bool;
sync1$ = true;

proc ParallelRun(a,b) {
  if exists(a) && exists(b) && a != b {
    if isFile(a) && isFile(b) {
      if getFileSize(a) == getFileSize(b) {
        sync1$;
        Fs.MasterDom += (a,b);
        sync1$ = true;
        }
        if getFileSize(a) < 8 && getFileSize(b) < 8 {
          sync1$;
          Fs.sizeZero += (a,b);
          sync1$ = true;
      }
    }
  }
}
coforall folder in walkdirs(".") {
  for a in findfiles(folder, recursive=false) {
    for b in findfiles(folder, recursive=false) {
      ParallelRun(a,b);
    }
  }
}

```
