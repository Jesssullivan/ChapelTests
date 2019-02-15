
# This test will loop any script and find the average time it takes to complete.  

The idea is to evaluate a "--flag" -in this case, Serial or Parallel in FileCheck.chpl- to see of there are time benefits to parallel processing.  In this case, there really are not any, because that program relies mostly on disk speed.  

here are the "--flag" defaults: 
```
config const F = "FileCheck"; // script
config const A = " --S"; // optional args to try also
config const opt : bool=true; // use args?
config const R : bool=true; // compile a report?
config const L : int=10; // # loops, repeated for additional arg if listed
```
