# python3
#
# Time_FileCheck.py
#
# A WIP by Jess Sullivan
#
# evaluate average run speed of both serial and parallel versions
# of FileCheck.chpl  --  NOTE: coforall is used in both BY DEFAULT.
# This is to bypass the slow findfiles() method by dividing file searches
# by number of directories.
# use arg PURE for all serial in the iterateWithArgs() function.
#

import subprocess
import time

File = "./FileCheck" # chapel to run
opt = "--S" # flag to eval against (serial)
noFile = "--R=false"  #  do not let chapel compile a report per run

# additional args from FileCheck.chpl:
Verb = "--V"  #  use verbose logging?
#  default DOES NOT USE ALL SERIAL. using a coforall to create masterDomself.
#  add PURE to arg list in the iterate scripts do see no coforall used at all.
#  (generally fails)
PURE = "--PURE=true"

loopNum = 10

runTime1 = []
runTime2 = []

def iterateScript(loops, F, runTime):
    for l in range(loops):
        start = time.time()
        subprocess.run([F, noFile])
        end = time.time()
        runTime.append(end-start)

def iterateWithArgs(loops, F, arg, runTime):
    for l in range(loops):
        start = time.time()
        subprocess.run([F, arg, noFile])
        end = time.time()
        runTime.append(end-start)

iterateScript(loops=loopNum, F=File, runTime=runTime1)
iterateWithArgs(loops=loopNum, F=File, arg=str(opt), runTime=runTime2)

print("average runTime for no args is ", sum(runTime1) / loopNum)
print("average runTime with args is ", sum(runTime2) / loopNum)
