
# These tests will loop a script and find the average time it takes to complete, with and without additional arguments.

The idea is to evaluate a "--flag" -in this case, Serial or Parallel in FileCheck.chpl- to see of there are time benefits to parallel processing.  In this case, there really are not any, because that program relies mostly on disk speed.  

# Notes:

```
TimeChapel.chpl is now archived in favor of python for evaluation.
```
