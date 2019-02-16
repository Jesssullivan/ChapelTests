# python3
#
# Time_PURE-Serial.py
#
# A WIP by Jess Sullivan
#
import subprocess
import time

File = "./FileCheck" # chapel to run
opt = "--S" # flag to eval against (serial)
noFile = "--R=false"  #  do not let chapel compile a report per run
PURE = "--PURE=true"
loopNum = 5
runTime = []

for l in range(loopNum):
    start = time.time()
    subprocess.run([File, opt, noFile, PURE])
    end = time.time()
    runTime.append(end-start)

print("With PURE serial operation, the average runTime is ", sum(runTime2) / loopNum)
