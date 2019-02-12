To run:

```
# In Parallel:
chpl FileCheck.chpl && ./FileCheck
```

# Dealing with Dupes in Chapel

This program will recursively run through all directories from where it starts and generates two text docs, one of same size, same file and another of same size, different file.

# it takes the following "--flags" : here are the defaults if none are given:

```
//
config const dir = ".";  // starting dir
config const V : bool=false; // verbose output?
config const S : bool=false;  // override parallel, use Serial looping?
config const ext : ".txt" 
//
```
# General notes:

```
both Serial and Parallel versions are merged to FileCheck.Chpl
use --S to toggle between them
reading files in parrallel is completely broken at the moment
 - frequently will get unsynced results, if any (each run has different results)
 :(
```
