
to run:

```
chpl FileCheck.chpl && ./FileCheck
```

# Dealing with Dupes in Chapel
FileCheck will by default recursively run through all directories from where it starts and make generate two files- a .txt file that is easy to read as a human and a csv file, assuming the next step would involve some other scripts or something that need a csv.  

Then it automatically opens the easy to read file in nano.  

# it takes two flags- here are the defaults if none are given:
--dir= .  // this is the directory where it starts
--R=true // it will default to going through child directories, "recursive"

# These are the blocks:
are they the same file in same directory?  
should these be removed automatically?
are they the same size in any directory?
generate files of results?
automatically show the results in nano?

each function / test is a block so one could make some more sophisticated control flow stuff later.
