# ChapelTests
For PSU OS course by Kyle Burke

Resources:

Chapel docs:
https://chapel-lang.org/docs/users-guide/datapar/forall.html

Semaphore Project:
https://turing.plymouth.edu/~kgb1013/?course=4310&project=0

In a (bash) shell:
'''
git clone https://github.com/chapel-lang/chapel
tar xzf chapel-1.18.0.tar.gz
cd chapel-1.18.0
source util/setchplenv.bash
make
make check
#  - All is from chapel docs - 
# compile a sample program
chpl -o hello examples/hello.chpl
# run the sample program
./hello
'''

# Configure atom editor for chapel

'''
# if this hasn't already been done:
cd
sudo apt-get install atom
# then get chapel formatting:
apm install language-chapel
'''
