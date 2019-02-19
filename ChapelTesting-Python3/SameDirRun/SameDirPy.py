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

import subprocess
import time

File = "./FileCheck"

# default false, use for evaluation
SE = "--SE=true"

# default false, use for evaluation
SP = "--SP=true" # no coforall looping anywhere

# default true, make it false:
R = "--R=false"  #  do not let chapel compile a report per run

# default true, make it false:
T = "--T=false" # no internal chapel timers

# default true, make it false:
V = "--V=false"  #  use verbose logging?

# default is false
bug = "--debug=false"

Default = (File, R, T, V, bug) # default parallel operation
Serial_SE = (File, R, T, V, bug, SE)
Serial_SP = (File, R, T, V, bug, SP)
Serial_SE_SP = (File, R, T, V, bug, SP, SE)


ListOptions = [Default, Serial_SE, Serial_SP, Serial_SE_SP]

loopNum = 5 # iterations of each runTime for an average speed.

def iterateWithArgs(loops, args, runTime):
    for l in range(loops):
        start = time.time()
        subprocess.run(args)
        end = time.time()
        runTime.append(end-start)

for option in ListOptions:
    runTime = []
    iterateWithArgs(loopNum, option, runTime)
    print("average runTime for FileCheck with ", str(option), " options is ")
    print(sum(runTime) / loopNum)
