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
./FileCheck --V --T --debug
```

...Will run FileCheck with internal timers(--T), which will be displayed with the verbose logs(--V) and all extra debug logging(--debug) from within each loop.

All config --Flags:

```
// serial options:
config const SE : bool=false; // use serial evaluation?
config const SP : bool=false; // use findfiles() as mastserDom method?

// logging options
config const V : bool=true; // Vebose output of actions?
config const debug : bool=false;  // enable verbose logging from within loops?
config const T : bool=true; // use internal Chapel timers?
config const R : bool=true; // compile report file?

// file options
config const dir = "."; // start here?
config const ext = ".txt";  // use alternative ext?
config const SAME = "SAME";  // default name ID?
config const DIFF = "DIFF"; // default name ID?

```

# General notes:

From inside FileCheck.chpl on use of classes - see below for snippets:

```

class Gate {
  // class Gate is an explicit way to use sync variables in parallel nested loops.
  // Gate is initialized with Gate.initGate()
  var x$: sync bool;
  var busy : atomic int;
  // Note:  this init does note follow default initializer spec by Chapel
  proc initGate() {
    x$.writeXF(true);
    busy.write(1);
  }
  // lock will wait after atomic busy is 2.
  // this seems redundant, however this far this has been
  // the easiest to understand sync solution for this script
  proc lock() {
    do {
      x$;
      if debug then writeln("Gate is locked");
      } while busy.read() != 1;
      busy.write(2);
  }
  // open / reset lock:
  proc openup() {
    busy.write(1);
    x$.writeXF(true);
    if debug then writeln("Gate is open");
  }
}

```

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
