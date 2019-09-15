# ChapelTests

Investigating modern concurrent programming ideas with Chapel Language and Python 3

**See here for dupe detection:**
[/FileChecking-with-Chapel](https://github.com/Jesssullivan/ChapelTests/tree/master/FileChecking-with-Chapel)


**Iterating through all files for custom tags / syntax:**

[/GenericTagIterator](https://github.com/Jesssullivan/ChapelTests/tree/master/GenericTagIterator)

added 9/14/19:

The thinking here is one could write a global, shorthand / tag-based note manager making use of an efficient tag gathering tool like the example here.  Gone would the days of actually needing a note manager- when the need presents itself, one could just add a calendar item, todo, etc with a global tag syntax.

The test uses $D for date: ```$D 09/14/19```

```
//  Chapel-Language  //

proc charCheck(aFile, ref choice, sep, sepRange) {
    try {
        var line : string;
        var tmp = openreader(aFile);
        while(tmp.readline(line)) {
            if line.find(sep) > 0 {
                choice += line.split(sep)[sepRange];
                if V then writeln('adding '+ sep + ' ' + line.split(sep)[sepRange]);
            }
        }
    tmp.close();
    } catch {
      if V then writeln("caught err");
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
