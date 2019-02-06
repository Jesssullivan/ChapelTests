
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

are any two files the same size in any directory?
  if so, add them to a suspect list

generate files of results?
  make a easy to read .txt and a space-seperated .txt, the latter for 
  possible data crunching later

Do a fine-grain, character level comb of suspect files?  
  print out results - see files "a" vs "b" in DUPES, this will
  catch if a difference like 00000001 vs 10000000 in two files

...Tell Human?

Each function is a block so one could make some more sophisticated control flow stuff later.
