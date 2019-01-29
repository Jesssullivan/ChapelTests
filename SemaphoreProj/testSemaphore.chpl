/*************************************
 * You can use this to test the Semaphore class you wrote in semaphore.chpl.
 *
 * Authors: Kyle Burke <https://github.com/paithan> and Mat Goonan
 * Usage: (for testing a semaphore with 7 tokens, being queried by 15 threads, each of which uses it for a max of 12 seconds.
 * $ chpl testSemaphore.chpl
 * $ ./testSemaphore --k=7 --t=15 --m=12
 * Also, you can keep Semaphore.chpl in a subdirectory, then run by using it as a module (this is how Kyle will be testing your code):
 * $ chpl -M<subfolderName> testSemaphore.chpl
 * $ ./testSemaphore --k=7 --t=15 --m=12
 * , where <subfolderName> is replaced by name of the folder your Semaphore.chpl is in.  (Yes, replace the carrots too.)
 **/
use Semaphore;
use Time;
use Random;

//test the Semaphore!

//configurable constants with short variable names
config const t: int = 2000; //numThreads
config const k : int = 8; //numTokens
config const m : real = .5; //maxTime

//rename these for clearer code below
var threads = t;
var tokens = k;
var maxTime = m;


//Test: We can get all the available tokens without waiting.
proc testSemaphoreNoWait(semaphore : Semaphore) : bool {
    var freeTokens = semaphore.getNumTokens();
    writeln("Testing that ", semaphore, " doesn't wait or block when requesting ", (freeTokens), " tokens...");
    var timer : Timer;
    timer.start();
    for i in 1..freeTokens {
        semaphore.p();
    }
    timer.stop();
    for i in 1..freeTokens {
        semaphore.v();
    }

    var success = (timer.elapsed() < .001);

    if (success) {
        writeln("Test passed!");
    } else {
        writeln("Test failed.  I waited " + timer.elapsed() + " seconds.");
    }
    return success;

}

var successNoWaitA = testSemaphoreNoWait(new Semaphore(20));
var successNoWaitB = testSemaphoreNoWait(new Semaphore(200));
var successNoWaitC = testSemaphoreNoWait(new Semaphore(2000));


//Test: Create a new Semaphore with zero tokens and make sure you can't claim
proc testSemaphoreBlocks(semaphore : Semaphore) : bool {
    var freeTokens = semaphore.getNumTokens();
    writeln("Testing that ", semaphore, " blocks after requesting ", (freeTokens + 1), " tokens...");
    for i in 1..freeTokens {
        semaphore.p();
    }
    var blockedCorrectly = false;
    var success = false;
    begin with(ref blockedCorrectly) {
        sleep(1); //sleep for one second
        semaphore.v();
        blockedCorrectly = true;
    }
    semaphore.p();
    if (blockedCorrectly) {
        writeln("The Semaphore with " + freeTokens + " blocked correctly!");
        success = true;
    } else {
        writeln("The Semaphore with " + freeTokens + " did not block correctly..");
        writeln("Test failed!");
    }
    for i in 1..freeTokens {
        semaphore.v();
    }
    if (success) {
        writeln("Test completed successfully!");
    }
    return success;
}

var successBlocksA = testSemaphoreBlocks(new Semaphore(0));
var successBlocksB = testSemaphoreBlocks(new Semaphore(1));
var successBlocksC = testSemaphoreBlocks(new Semaphore(7));


proc semaphoreStressTest(numTokens : int, numThreads : int, maxSeconds : real) : real {
    var timer = new Timer();
    timer.start();
    var numWaiting : atomic int;
    numWaiting.write(numThreads);
    var quittingTime : atomic bool;
    quittingTime.write(false);
    var semaphore = new Semaphore(numTokens);
    var rng = new NPBRandomStream(real);
    var timeToWaitBeforeQuitting = 2 * (maxSeconds * numThreads / numTokens) / 5;
    sync {
        //the thread to test that things finished
        begin with (ref numWaiting, ref quittingTime) {
            while (true) {
                var lastNumWaiting = numWaiting.read();
                sleep (timeToWaitBeforeQuitting);
                if (lastNumWaiting == 0) {
                    break;
                } else if (lastNumWaiting - numWaiting.read() == 0) {
                    writeln("None completed in the last ", timeToWaitBeforeQuitting, " seconds!  I want to quit!  There were ", numWaiting.read(), " threads still waiting to complete.");
                    quittingTime.write(true);
                    break;
                }
            }
        } //end of the timing thread

        coforall i in 0..(numThreads-1)  {
            var stuck : atomic bool;
            stuck.write(true);
            var randomReal = rng.getNext();
            //writeln("randomReal: " + randomReal);
            var sleepTime = randomReal * maxSeconds;
            //writeln("Iteration ", i, " is ready for the semaphore.");
            begin with (ref stuck, ref quittingTime) {
                sleep(maxTime);
                while (stuck.read() && !quittingTime.read()) {
                    writeln("Iteration ", i, " is waiting...");
                    sleep((1 + maxTime));
                }
            }
            if (!quittingTime.read()) {
                semaphore.p();
                stuck.write(false);
                //writeln("Iteration ", i, " is using the semaphore for ", sleepTime, " seconds...");
                sleep(sleepTime);
                semaphore.v();
                //writeln("Iteration ", i, " is done with the semaphore!");
                numWaiting.sub(1);
                writeln(numWaiting.read(), " threads left running!");
            }
        }
        writeln("Finished tests with ", numWaiting.read(), " threads still running!");
        timer.stop();
        writeln("Stress test ran in ", timer.elapsed(), " seconds.");
        writeln("Waiting for the monitoring thread(s) to close.  Could take ", timeToWaitBeforeQuitting, " seconds...");
    }
    if (numWaiting.read() == 0) {
        writeln("Monitoring thread has completed.");
        return timer.elapsed();
    } else {
        writeln("Stress test had ", numWaiting.read(), " threads still running!");
        return -1.0;
    };
}

/* These really shouldn't have to be in sync blocks, right? */
var successStressA = -1.0;
var successStressB = -1.0;
var successStressC = -1.0;
sync {
    writeln();
    writeln("Starting the first stress test (1 token, 20 threads, 2-second max wait time)...");
    successStressA = semaphoreStressTest(1, 20, 2.0);
    //writeln("First stress test completed.");
    writeln();
}
sleep(2);
sync {
    writeln();
    writeln("Starting the second stress test (3 tokens, 100 threads, 1-second max wait time)...");
    successStressB = semaphoreStressTest(3, 100, 1.0);
    //writeln("Second stress test completed.");
    writeln();
}
sleep(2);
sync {
    writeln();
    writeln("Starting the third stress test (k tokens (default 8), t threads (default 2000), m-seconds max time (default .5))...");
    successStressC = semaphoreStressTest(tokens, threads, maxTime);
    //writeln("Third stress test completed.");
    writeln();
}

//print out the report
writeln("******************************");
writeln("* Here is the report:");
writeln("*");

//print a report about the no-waiting tests.
if (successNoWaitA && successNoWaitB && successNoWaitC) {
    writeln("* All of the no-waiting tests completed successfully!");
} else {
    if (!successNoWaitA) {
        writeln("* No Waiting Test A failed.");
    }
    if (!successNoWaitB) {
        writeln("* No Waiting Test B failed.");
    }
    if (!successNoWaitC) {
        writeln("* No Waiting Test C failed.");
    }
}

//print a report about the blocking tests.
if (successBlocksA && successBlocksB && successBlocksC) {
    writeln("* All of the blocking tests completed successfully!");
} else {
    if (!successBlocksA) {
        writeln("* Blocking Test A failed.");
    }
    if (!successBlocksB) {
        writeln("* Blocking Test B failed.");
    }
    if (!successBlocksC) {
        writeln("* Blocking Test C failed.");
    }
}

//print a report about the stress tests.
if ((successStressA != -1.0) && (successStressB != -1.0) && (successStressC != -1.0)) {
    writeln("* All Stress Tests completed successfully!");
}

if (successStressA == -1.0) {
    writeln("* Stress Test A failed.");
} else {
    writeln("* Stress Test A ran in ", successStressA, " seconds.");
}
if (successStressB == -1.0) {
    writeln("* Stress Test B failed.");
} else {
    writeln("* Stress Test B ran in ", successStressB, " seconds.");
}
if (successStressC == -1.0) {
    writeln("* Stress Test C failed.");
} else {
    writeln("* Stress Test C ran in ", successStressC, " seconds.");
}

writeln("******************************");
