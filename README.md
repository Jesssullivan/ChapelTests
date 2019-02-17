# ChapelTests

Repo in light of PSU OS course


# Test FileCheck.chpl from this repo:

```

git clone https://github.com/Jesssullivan/ChapelTests

# compile FileCheck:

cd ChapelTests/FileChecking-with-Chapel

chpl FileCheck.chpl

# evaluate 3 different run times:

cd ../ChapelTesting-Python3

python3 Timer_FileCheck.py

```

FileCheck.chpl provides both parallel and serial methods for recursive duplicate file finding in Cray’s Chapel Language.  Both solutions will be “slow”, as they are fundamentally limited by disk speed.   Go to /FileChecking-with-Chapel/ for more information on this script.  Timer_FileCheck.py and other tests evaluate completion times for all Serial and parallel options.  Go to /ChapelTesting-Python3/ for more information on these tests.

To run:

```
# In Parallel:
chpl FileCheck.chpl && ./FileCheck
```

# Dealing with Dupes in Chapel

This program will recursively run through all directories from where it starts and generates two text docs, one of same size, same file and another of same size, different file.  

Please see the python3 evaluation scripts to run these options in a loop.  

# --Flags:

example:  
```
./FileCheck --S --V --T --PURE --debug
```

...Will run a completely(--PURE) Serial(--S) FileCheck with internal timers(--T), which will be displayed with the verbose logs(--V) and all extra debug logging(--debug) from within each loop.

All config --Flags:
```
config const S : bool=false;  // override parallel, use Serial looping?
config const PURE : bool =false;  // compile masterDom in serial?
config const V : bool=false; // Vebose output of actions
// use internal Chapel timers?  default is false, in favor of
//  external Python3 timer scripts, in repo
config const T : bool=false;

// add extra debug options
config const debug : bool=false;  // enable verbose logging from within loops.
config const dir = "."; // start here?
config const ext = ".txt";  // use alternative ext?
config const R : bool=true; // compile report file?
config const SAME = "SAME";
config const DIFF = "DIFF";
```
# General notes:

From inside FileCheck.chpl on use of classes - see below for snippets:

Class Gate is a generic way to maintain thread safety while a coforall loop tries to update one domain (```ref keys```) with many live threads and new entries ```{("", "")}```.  A new borrowed Gate class is made per function that need to be operate on a domain, with the "Gate.keeper".

Safety is (tentatively) achieved with the Gate.keeper() syncing its "keys" - a generic domain from within module "Fs" - with a Sync$ variable used in concert with an atomic integer that may be 1 or 0 - open or closed - go or wait.  

```
//  Chapel-Language //

// class gate, verbatim from FileCheck.chpl:
class Gate {
  var D$ : sync bool=true;
  var Duo : atomic int;
  proc keeper(ref keys, (a,b)) { // use "ref keys" due to constant updating of this domain
    Duo.write(1);
    D$.writeXF(true); // init open
    do {
      if debug then writeln("waiting @ Gate D$...");
      D$;
     } while Duo.read() < 1;
     Duo.sub(1);
     keys += (a,b);
     if debug then writeln("Gate opened! added keys " + (a,b));
     Duo.add(1);
     D$.writeXF(true);
    }
  }

```

Class Cabinet manages the dupe evaluation.  this is a generic way to maintain thread safety by not only sandboxing the read/write operations to a domain, but all evaluations.  class Gate is use inside each Cabinet to preform the actual domain transactions.


# Get some Chapel:

 In a (bash) shell, install Chapel:   
   Mac or Linux here, others refer to:

 https://chapel-lang.org/docs/usingchapel/QUICKSTART.html

```
# For Linux bash:
git clone https://github.com/chapel-lang/chapel
tar xzf chapel-1.18.0.tar.gz
cd chapel-1.18.0
source util/setchplenv.bash
make
make check

#For Mac OSX bash:
# Just use homebrew
brew install chapel # :)
```
# Get atom editor for Chapel Language support:
```
#Linux bash:
cd
sudo apt-get install atom
apm install language-chapel
# atom [yourfile.chpl]  # open/make a file with atom

# Mac OSX (download):
# https://github.com/atom/atom
# bash for Chapel language support
apm install language-chapel
# atom [yourfile.chpl]  # open/make a file with atom

```

# Using the Chapel compiler

To compile with Chapel:
```
chpl MyFile.chpl # chpl command is self sufficient

# chpl one file class into another:

chpl -M classFile runFile.chpl

# to run a Chapel file:
./runFile
```
