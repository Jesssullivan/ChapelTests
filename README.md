# ChapelTests

Repo in light of PSU OS course


# Test FileCheck.chpl from this repo:

```

git clone https://github.com/Jesssullivan/ChapelTests

cd chapeltests/ChapelTesting-Python3/

chpl ../FileChecking-with-Chapel/FileCheck.chpl

python3 Timer.py

```

FileCheck.chpl provides both parallel and serial methods for recursive duplicate file finding in Cray’s Chapel Language.  Both solutions will be “slow”, as they are fundamentally limited by disk speed.   Go to /FileChecking-with-Chapel/ for more information on this script.  Timer.py evaluates completion time for both Serial and parallel options.  Go to /ChapelTesting-Python3/ for more information on this test.

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
