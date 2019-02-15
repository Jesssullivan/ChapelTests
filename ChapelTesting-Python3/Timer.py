import subprocess
import time

File = "./FileCheck"
opt = "--S"

loopNum = 10

runTime1 = []
runTime2 = []

def iterateScript(loops, F, runTime):
    for l in range(loops):
        start = time.time()
        subprocess.run([F])
        end = time.time()
        runTime.append(end-start)

def iterateWithArgs(loops, F, arg, runTime):
    for l in range(loops):
        start = time.time()
        subprocess.run([F, arg])
        end = time.time()
        runTime.append(end-start)

iterateScript(loops=loopNum, F=File, runTime=runTime1)
iterateWithArgs(loops=loopNum, F=File, arg=str(opt), runTime=runTime2)

print("average runTime for no args is ", sum(runTime1) / loopNum)
print("average runTime with args is ", sum(runTime2) / loopNum)
