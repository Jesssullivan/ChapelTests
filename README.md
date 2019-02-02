# ChapelTests
ala PSU OS course by Kyle Burke
```
git clone https://github.com/Jesssullivan/ChapelTests
```
# Resources:

Chapel docs:
https://chapel-lang.org/docs/users-guide/datapar/forall.html

Semaphore Project:
https://turing.plymouth.edu/~kgb1013/?course=4310&project=0

# In a (bash) shell, install Chapel:  
 Mac or Linux here, others refer to -
 https://chapel-lang.org/docs/usingchapel/QUICKSTART.html

```
# Get some Chapel:

# For Linux bash:
git clone https://github.com/chapel-lang/chapel
tar xzf chapel-1.18.0.tar.gz
cd chapel-1.18.0
source util/setchplenv.bash
make
make check

#For Mac OSX bash:
git clone https://github.com/chapel-lang/chapel
cd chapel
make
make check
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

git clone https://github.com/chapel-lang/chapel
tar xzf chapel-1.18.0.tar.gz
cd chapel-1.18.0
source util/setchplenv.bash
make
make check
#- All is from chapel docs - 
#compile a sample program
chpl -o hello examples/hello.chpl
#run the sample program
./hello
```

# Using the Chapel compiler 

To compile with Chapel:
```
chpl MyFile.chpl # chpl command is self sufficient

# chpl one file class into another:

chpl -M classFile runFile.chpl 

# to run a Chapel file:
./runFile.chpl 
```


