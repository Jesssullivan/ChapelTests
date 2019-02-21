# python3
#
# Evaluating the speed of incorrect, unsynced coforall loops
# VS. corrected solutions using sync variables.
#
# A WIP by Jess Sullivan

import subprocess
import time

file = "./parallelTester4py"
# defaults are all true, make false:
A = "--UnSyncedParallel_Int=true"
B = "--UnSyncedParallel_String=true"
C = "--SyncedParallel_Int=true"
D = "--SyncedParallelS_String=true"
E = "--SerialLoop_Int=true"
F = "--SerialLoop_String=true"

RunA = (file, A)
RunB = (file, B)
RunC = (file, C)
RunD = (file, D)
RunE = (file, E)
RunF = (file, F)

ListOptions = [RunA, RunB, RunC, RunD, RunE, RunF]

loopNum = 25 # iterations of each runTime for an average speed.

# setup output file
file = open("ParallelTester_RESULTS.txt", "w")

file.write(str('Looking at ' + str(loopNum) + ' loops for ' + str(len(ListOptions)) + "\n\\"))

def iterateWithArgs(loops, args, runTime):
    for l in range(loops):
        start = time.time()
        subprocess.run(args)
        end = time.time()
        runTime.append(end-start)

for option in ListOptions:
    runTime = []
    iterateWithArgs(loopNum, option, runTime)

    file.write("total time for "+ str(loopNum) +" iterations was "+ str(sum(runTime))+
    " the average runTime for " + str(option) + " options is " + "\n\\")
    file.write(str(sum(runTime) / loopNum) +"\n\\"+" total:\n\\" + str(sum(runTime))+"\n\\")

    print("total time for "+ str(loopNum) +" iterations was "+str(sum(runTime))+
    " the average runTime for " + str(option) + " options is " + "\n\\")
    print(str(sum(runTime) / loopNum) +"\n\\"+" total:\n\\" +str(sum(runTime))+"\n\\")

file.close()
