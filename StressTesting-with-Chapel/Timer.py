''''
Python3 method to evaluate script times.
WIP by Jess Sullivan.
''''
import subprocess
import time

File = "./FileCheck"
opt = " --S"
loopNum = 10

runTime1 = []
runTime2 = []

def iterateScript(loops, F, A, runTime):
    for l in range(loops):
        start = time.time()
        subprocess.run([F,A])
        end = time.time()
        runTime.append(end-start)

iterateScript(loopNum, File, "", runTime1)
iterateScript(loopNum, File, "", runTime2)

print("average runTime for no args is ", sum(runTime1) / loops)
print("average runTime with args is ", sum(runTime2) / loops)
