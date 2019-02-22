# ChapelTests

Investigating modern concurrent programming ideas with Chapel Language and Python 3

Repo in light of PSU OS course :)

# Test FileCheck.chpl from this repo:

```

git clone https://github.com/Jesssullivan/ChapelTests

cd ChapelTests/FileChecking-with-Chapel

# compile fastest / most up to date script:

chpl FileCheck2.chpl  # not annotated / no extra --args

# compile all options (old sync method):

chpl FileCheck.chpl

# evaluate 5 different run times:

python3 Timer_FileCheck.py

```

These two FileCheck scripts provide both parallel and serial methods for recursive duplicate file finding in Cray’s Chapel Language.  All solutions will be “slow”, as they are fundamentally limited by disk speed.

Revision 2 uses standard sync$ variable form.

 Use Timer_FileCheck.py to evaluate completion times for all Serial and parallel options.  Go to /ChapelTesting-Python3/ for more information on these tests.

To run:

```
# In Parallel:
chpl FileCheck.chpl && ./FileCheck
# or:
chpl FileCheck2.chpl && ./FileCheck2

```

# Dealing with Dupes in Chapel

Generate three text docs:

- Same size, same file another
- Same size, different file
- Same size, less than 8 bytes

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

From inside FileCheck2.chpl on updated sync$ syntax:

```
//  Chapel-Language  //

module Fs {
  var MasterDom = {("", "")};  // contains same size files as (a,b).
  var same = {("", "")};  // identical files
  var diff = {("", "")};  // sorted files flagged as same size but are not identical
  var sizeZero = {("", "")}; // sort files that are < 8 bytes
}

var sync1$ : sync bool;
sync1$ = true;

proc ParallelRun(a,b) {
  if exists(a) && exists(b) && a != b {
    if isFile(a) && isFile(b) {
      if getFileSize(a) == getFileSize(b) {
        sync1$;
        Fs.MasterDom += (a,b);
        sync1$ = true;
        }
        if getFileSize(a) < 8 && getFileSize(b) < 8 {
          sync1$;
          Fs.sizeZero += (a,b);
          sync1$ = true;
      }
    }
  }
}
coforall folder in walkdirs(".") {
  for a in findfiles(folder, recursive=false) {
    for b in findfiles(folder, recursive=false) {
      ParallelRun(a,b);
    }
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
