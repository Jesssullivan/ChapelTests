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
config const R : bool=true; // enable recursive?
config const V : bool=false; // verbose output?
config const S : bool=false;  // override parallel, use Serial looping?
config const TXT : bool=true;  // use CSV out?
config const SAME = "SameDupeOut";
config const DIFF = "DiffDupeOut";
//
```
# General notes:

```
both Serial and Parallel versions are merged to FileCheck.Chpl
use --S=true to toggle between them

```
