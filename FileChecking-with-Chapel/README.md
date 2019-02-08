
to run:

```
# in parallel:
chpl FileCheckParallel.chpl && ./FileCheckParallel
# in series:
chpl FileCheck.chpl && ./FileCheck 
```

# Dealing with Dupes in Chapel

These programs will recursively run through all directories from where it starts and make generate two text docs (a .txt file that is easy to read as a human and a space seperated .txt file) for any two files with equal size.  

Then it will go through these suspiciously similar files at the character level and evaluate for any differences.

# it takes four "--flags" : here are the defaults if none are given:

```

// this is the directory where it starts

--dir= .  

// it will default to going through child directories, as "recursive"

--R=true 

// there are the two file names it will use for output too
```

# These are the blocks:

# are any two files the same size in any directory?

  if so, add them to a suspect list

# generate files of results?

  make a easy to read .txt and a space-seperated .txt, the latter for 
  possible data crunching later

# Do a fine-grain, character level comb of suspect files?  
  print out results - see files "a" vs "b" in DUPES, this will
  catch if a difference like 00000001 vs 10000000 in two files

...Tell Human?

Each function is a block so one could make some more sophisticated control flow stuff later.
