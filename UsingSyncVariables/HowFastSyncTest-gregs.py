#!/usr/bin/env python3
#
# Evaluating the speed of incorrect, unsynced coforall loops
# VS. corrected solutions using sync variables.
#
# A WIP by Jess Sullivan

import subprocess
import time

n = 10
chapelExe = "./parallelTester4py-gregs"
outputFileName = "ParallelTester_RESULTS.txt"

# defaults are all true, make false:
options = ["UnSyncedParallel_Int=true",
           "UnSyncedParallel_String=true",
           "SyncedParallel_Int=true",
           "SyncedParallelS_String=true",
           "SerialLoop_Int=true",
           "SerialLoop_String=true"]

# returns total time
def iterateWithArgs(args):
    totalTime = 0
    for l in range(n):
        start = time.time()
        subprocess.run([chapelExe] + args)
        end = time.time()
        totalTime = totalTime + (end - start)
    return totalTime

with open(outputFileName, "w") as file:
    for option in options:
        totalTime = iterateWithArgs(["--{}".format(option)])
        results = "{} X {}: total time = {}; average time = {}.\n".format(
            option, n, totalTime, totalTime / n)
        file.write(results)
        print(results)
