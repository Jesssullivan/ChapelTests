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

File = "./FileCheck" # chapel to run
File_Bench = "./FileCheck2" # Other chapel to run
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

Default_Benchmark = (File_Bench, R, V)
Default = (File, R, T, V, bug) # default parallel operation
Serial_SE = (File, R, T, V, bug, SE)
Serial_SP = (File, R, T, V, bug, SP)
Serial_SE_SP = (File, R, T, V, bug, SP, SE)


ListOptions = [Default_Benchmark, Default, Serial_SE, Serial_SP, Serial_SE_SP]

loopNum = 10 # iterations of each runTime for an average speed.

# setup output file
file = open("Time_FileCheck_Results.txt", "w")

file.write(str('eval ' + str(loopNum) + ' loops for ' + str(len(ListOptions)) + ' FileCheck Options' + "\n\\"))

def iterateWithArgs(loops, args, runTime):
    for l in range(loops):
        start = time.time()
        subprocess.run(args)
        end = time.time()
        runTime.append(end-start)

for option in ListOptions:
    runTime = []
    iterateWithArgs(loopNum, option, runTime)
    file.write("average runTime for FileCheck with "+ str(option) + "options is " + "\n\\")
    file.write(str(sum(runTime) / loopNum) +"\n\\")
    print("average runTime for FileCheck with " + str(option) + " options is " + "\n\\")
    print(str(sum(runTime) / loopNum) +"\n\\")

file.close()
