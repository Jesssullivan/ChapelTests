
# This test will loop any script and find the average time it takes to complete.  

The idea is to evaluate a "--flag" -in this case, Serial or Parallel in FileCheck.chpl- to see of there are time benefits to parallel processing.  In this case, there really are not any, because that program relies mostly on disk speed.  

# Basic Run with Filecheck:

```
# cd directory to evaluate with
git clone https://github.com/Jesssullivan/ChapelTests
chpl ChapelTests/FileChecking-with-Chapel/FileCheck.chpl
chpl ChapelTests/StressTesting-with-Chapel/TimeChapel.chpl
./TimeChapel 
#  ...or configure with ./TimeChapel --F="FileCheck" --A="--S" --L=10 --opt --R --N
```

here are the "--flag" defaults: 

```
config const F = "FileCheck"; // script
config const A = " --S"; // optional args to try also
config const opt : bool=true; // use args?
config const R : bool=true; // compile a report?
config const N : bool=false;  // do not open report in nano by default
config const L : int=10; // # loops, repeated for additional arg if listed
```
