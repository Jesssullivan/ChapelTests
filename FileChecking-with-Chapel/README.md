To run:

```
# In Parallel:
chpl FileCheck.chpl && ./FileCheck
```

# Dealing with Dupes in Chapel

This program will recursively run through all directories from where it starts and generates two text docs, one of same size, same file and another of same size, different file.

# it takes the following "--flags" : here are the defaults if none are given:

example:  
```
./FileCheck --S --V
```
...Will run a Serial FileCheck with Verbose Logging.

Flags:
```
//
cconfig const S : bool=false;  // override parallel, use Serial looping?
config const dir = "."; // start here?
// add extra debug options
config const V : bool=false; // Vebose output of actions
config const R : bool=true; // compile report file?  use false for time eval
config const PURE : bool =false;  // compile masterDom in serial?
//  there are serious limitations to findfile() in the current layout.
config const ext = ".txt";  // use alternative ext?
config const SAME = "SAME";
config const DIFF = "DIFF";
//
```
# General notes:

From inside FileCheck.chpl on use of classes - see below for snippets:

Class Gate is a generic way to maintain thread safety while a coforall loop tries to update one domain (```ref keys```) with many live threads and new entries ```{("", "")}```.  A new borrowed Gate class is made per function that need to be operate on a domain, with the "Gate.keeper".

Safety is (tentatively) achieved with the Gate.keeper() syncing its "keys" - a generic domain from within module "Fs" - with a Sync$ variable used in concert with an atomic integer that may be 1 or 0 - open or closed - go or wait.  

Class Cabinet manages the dupe evaluation.  this is a generic way to maintain thread safety by not only sandboxing the read/write operations to a domain, but all evaluations.  class Gate is use inside each Cabinet to preform the actual domain transactions. 
```
//  Chapel-Language, annotated //

class Gate {
  var D$ : sync bool=true; 
  proc keeper(ref keys, (a,b)) {
    var Duo : atomic int;   
    Duo.write(1);          // init lock as "open"
    D$.writeXF(true);     // init sync as "open"
    do {
      D$;              // wait, read varible while we wait
     } while Duo.read() < 1;  
     D$.writeXF(true);   // re open sync
     Duo.sub(1);        // lock, preforming a domain transaction
     keys += (a,b);
     Duo.add(1);      // re open lock
    }
  }
```
