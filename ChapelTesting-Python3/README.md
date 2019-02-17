
# to eval:

```

git clone https://github.com/Jesssullivan/ChapelTests

# compile FileCheck:

chpl FileChecking-with-Chapel/FileCheck.chpl

# evaluate 3 different run times:

python3 ChapelTesting-Python3/Timer_FileCheck.py

```

# Timer_FileCheck.py will loop FileCheck and find the average times it takes to complete, with a variety of additional arguments to toggle parallel and serial operation.


Use Timer_PURE_Serial.py to see the default - findfiles(dir, recursive=true) - method used to generate the masterDom, from which dupes are evaluated.  

The idea is to evaluate a "--flag" -in this case, Serial or Parallel in FileCheck.chpl- to see of there are time benefits to parallel processing.  In this case, there really are not any, because that program relies mostly on disk speed.  

# Notes:

```
Timer_FileCheck.py now evaluates all three run types.

TimeChapel.chpl is now archived in favor of python for evaluation.
```
