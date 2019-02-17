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

File = "../FileChecking-with-Chapel/FileCheck" # chapel to run

# default false, use for evaluation
S = "--S" # flag to eval against (serial)

# default false, use for evaluation
PURE = "--PURE=true" # no coforall looping anywhere

# default true, make it false:
noReport = "--R=false"  #  do not let chapel compile a report per run

# default true, make it false:
T = "--T=false" # no internal chapel timers

# default true, make it false:
V = "--V=false"  #  use verbose logging?

# default is false
bug = "--debug=false"

Default = (File, noReport, T, V, bug) # default parallel operation
Serial = (File, noReport, T, V, bug, S)
Serial_PURE = (File, noReport, T, V, bug, S, PURE)

ListOptions = [Default, Serial, Serial_PURE]

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
    print("average runTime for FileCheck with ", str(option), " options is ", sum(runTime) / loopNum)
