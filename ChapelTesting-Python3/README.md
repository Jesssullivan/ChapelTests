
# to eval:

```
git clone https://github.com/Jesssullivan/ChapelTests

cd chapeltests/ChapelTesting-Python3/

chpl ../FileChecking-with-Chapel/FileCheck.chpl

python3 Timer.py
```

# Timer.py will loop a script and find the average time it takes to complete, with and without an additional argument.

The idea is to evaluate a "--flag" -in this case, Serial or Parallel in FileCheck.chpl- to see of there are time benefits to parallel processing.  In this case, there really are not any, because that program relies mostly on disk speed.  

# Notes:

default settings:
```
# Python3- language #

File = "./FileCheck" # compiled chapel binary
opt = "--S"  # flag to add on second round
loopNum = 10  # times to repeat
```
# method to loop:
```
#
runTime2 = []  # creates an empty list

# Using subprocess.run() to loop:

def iterateWithArgs(loops, F, arg, runTime):
    for l in range(loops):
        start = time.time()
        subprocess.run([F, arg])
        end = time.time()
        runTime.append(end-start)
        
# Run this function- there is a near identical one sans "arg".  
# The final averages are logged once all subprocesses have completed.

iterateWithArgs(loops=loopNum, F=File, arg=str(opt), runTime=runTime2)
```

Notes:
```
TimeChapel.chpl is now archived in favor of python for evaluation.
```
