
# Python Evaluation

```

# Ajacent to compiled FileCheck.chpl binary:

python3 Timer_FileCheck.py

```

Timer_FileCheck.py will loop FileCheck and find the average times it takes to complete, with a variety of additional arguments to toggle parallel and serial operation.  The iterations are:

```
ListOptions = [Default, Serial_SE, Serial_SP, Serial_SE_SP]
```

- Default - full parallel

- Serial evaluation (--SE) but parallel domain creation

- Serial domain creation (--SP) but parallel evaluation

- Full serial (--SE --SP)

# Output is saved as Time_FileCheck_Results.txt

- Output is also logged after each of the (default 10) loops.

The idea is to evaluate a "--flag" -in this case, Serial or Parallel in FileCheck.chpl- to see of there are time benefits to parallel processing.  In this case, there really are not any, because that program relies mostly on disk speed.  

# Notes:

```
Timer_FileCheck.py now evaluates all four run types.

TimeChapel.chpl is now archived in favor of python for evaluation.
```
