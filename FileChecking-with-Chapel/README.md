To run:

```
# In Parallel:
chpl FileCheckParallel.chpl && ./FileCheckParallel
```

# Dealing with Dupes in Chapel

These programs will recursively run through all directories from where it starts and generates two text docs, one of same size, same file and another of same size, different file.

# it takes four "--flags" : here are the defaults if none are given:

```
config const R : bool=true;  // recursive or no?

config const Verb : bool=false;  // Verbose output?

config const SameFileOutput = "SameFileOutput.txt";

config const DiffFileOutput = "DiffFileOutput.txt";

```
# General notes:

```
Parallel version is tentatively working again
...
Serial version, not really
# Not in Parallel:
chpl FileCheckSerial.chpl && ./FileCheckSerial
```
