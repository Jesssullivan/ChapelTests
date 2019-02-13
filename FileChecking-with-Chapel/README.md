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
preforming an initial SizeCheck in parallel may not be an option.

parallelFullCheck(): fixed varied results, but very slow due to serial SizeCheck bottleneck.

```
From inside FileCheck.chpl on use of classes: 

"class Gate is a generic way to maintain thread safety
while a coforall loop tries to update one domain with
many threads and new keys {("", "")}. a new borrowed
Gate class is made per set of keys that need to be managed.
:)
Safety is (tentatively) achieved with the Gate.keeper() syncing its
"keys" - a generic domain- any of those kept in module Fs-
...only while inside a Cabinet!  See below for class Cabinet."

"class Cabinet manages dupe evaluation functions.
this is a generic way to maintain thread safety by not only sandboxing
the read/write operations to a domain, but all evaluations.
class Gate is use inside each Cabinet to preform the actual domain transactions.
a new borrowed Cabinet is created with each set of keys
(e.g. with any function that needs to operate on a domain)"
