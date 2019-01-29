/*************************************
 * You can use this code to test the BlockingQueue class you wrote in BlockingQueue.chpl.
 *
 * Usage: 
 * $ chpl -MYourFolderName testBlockingQueue.chpl
 * $ ./testBlockingQueue --v=true
 * Change the v constant to false to remove all the print statements.
 *
 * Author: Kyle Burke <https://github.com/paithan>
 * Author: Mat Goonan <https://github.com/matgoonan>
 */

use BlockingQueue;
use Time;
use Random;

//short named version
config const v = true;
var verbose = v; //long named-version


//This section tests that the queue can take different types.

writeln("Testing on strings...");
var typeStringTest = false;
begin with (ref typeStringTest) {
    var q = new BlockingQueue(string, 10);
    q.add("");
    q.add("Cookie Monster!");
    typeStringTest = true;
}

writeln("Testing on ints...");
var typeIntTest = false;
begin with (ref typeIntTest) {
    var q = new BlockingQueue(int, 10);
    q.add(17);
    q.add(-4);
    typeIntTest = true;
}

writeln("Testing on Semaphores...");
var typeSemaphoreTest = false;
begin with (ref typeSemaphoreTest) {
    var q = new BlockingQueue(Semaphore, 10);
    q.add(new Semaphore(200));
    q.add(new Semaphore(2));
    typeSemaphoreTest = true;
}




//This section tests that the queue blocks when empty.
//First, starting from empty.
var blockEmptyOnRemoveTestA = true; //Becomes false if it doesn't block
begin with (ref blockEmptyOnRemoveTestA) {
    var q = new BlockingQueue(int, 10);
    //writeln("Running the first test!  Trying to remove from an empty queue.  Nothing should happen.");
    //writeln("Ctrl + C to kill this.");
    q.remove();
    writeln("BlockingQueue.remove() doesn't block when the queue is empty (Test A)!");
    blockEmptyOnRemoveTestA = false;
}

//Second, adding one and removing two.
var blockEmptyOnRemoveTestB = true; //becomes false if it doesn't block
begin with (ref blockEmptyOnRemoveTestB) {
    var q = new BlockingQueue(int, 10);
    q.add(0);
    //writeln("Running the second test!  Trying to remove from an empty queue.  Nothing should happen.");
    //writeln("Ctrl + C to kill this.");
    q.remove();
    q.remove();
    writeln("BlockingQueue.remove() doesn't block when the queue is empty (Test B)!");
    blockEmptyOnRemoveTestB = false;
}

//Third, fill it up, then remove them all.
var blockEmptyOnRemoveTestC = true; //becomes false if it doesn't block
begin with (ref blockEmptyOnRemoveTestC) {
    var size = 10;
    var q = new BlockingQueue(int, size);
    for i in 1..size {
        q.add(0);
    }
    //writeln("Running the third test!  Trying to remove from an empty queue.  Nothing should happen.");
    //writeln("Ctrl + C to kill this.");
    for i in 1..size + 1 {
        q.remove();
    }
    writeln("BlockingQueue.remove() doesn't block when the queue is empty (Test C)!");
    blockEmptyOnRemoveTestC = false;
}


//This section tests that add blocks when the queue is full.
//First test: just fill it up
var blockFullOnAddTestA = true; //becomes false if it doesn't block
begin with (ref blockFullOnAddTestA) {
    var size = 10;
    var q = new BlockingQueue(int, size);
    for i in 1..size {
        q.add(0);
    }
    q.add(5); //should block here
    blockFullOnAddTestA = false; //should never be executed.
}

//Second test: fill it up, remove everything, fill it up again
var blockFullOnAddTestB = true; //becomes false if it doesn't block
begin with (ref blockFullOnAddTestB) {
    var size = 10;
    var q = new BlockingQueue(int, size);
    for i in 1..size {
        q.add(0);
    }
    for i in 1..size {
        q.remove();
    }
    for i in 1..size {
        q.add(0);
    }
    q.add(5); //should block here
    blockFullOnAddTestB = false; //should never be executed.
}


//This section tests that getNumElements works.

var intQueue = new BlockingQueue(int, 10);
var getNumElementsTestA = intQueue.getNumElements(); //should be 0
intQueue.add(5);
intQueue.add(5);
intQueue.remove();
intQueue.add(5);
intQueue.add(5);
var getNumElementsTestB = intQueue.getNumElements(); //should be 3
for i in 4..10 {
    intQueue.add(5);
}
var getNumElementsTestC = intQueue.getNumElements(); //should be 10



//This section tests that the queue adds and removes things in the proper order.
var testDomainMax = 5;
intQueue = new BlockingQueue(int, testDomainMax);
var testDomain = 1..testDomainMax * 2;
begin { //use a new thread so that some of the removes can happen too.
    for i in testDomain {
        intQueue.add(i);
    }
}
var orderTest : [testDomain] int;
for i in testDomain {
    orderTest[i] = intQueue.remove();
}







//time for stress tests!
//numRounds is the
proc blockingQueueStressTest(capacity : int, initialNumElements : int, maxAddWait : real, maxRemoveWait : real, numRounds : int, verbose : bool = true) {
    var inOrder : bool = true;
    var sizeRestricted : atomic bool;
    sizeRestricted.write(true);
    if (initialNumElements > capacity) {
        writeln("Stress test launched with bigger initial number of elements than the capacity!  Quitting!");
        return -1.0;
    }
    writeln("Stress test launched!");
    var timer : Timer;
    timer.start();
    var q = new BlockingQueue(int, capacity);
    for i in 1..initialNumElements {
        q.add(i);
    }
    sync {
        //the thread that adds elements
        begin with (ref sizeRestricted) {
            var rng = new NPBRandomStream(real);
            for i in initialNumElements + 1..initialNumElements + (capacity * numRounds) {
                var waitSeconds = rng.getNext() * maxAddWait;
                sleep(waitSeconds);
                q.add(i % capacity);
                //print out the queue or the size
                if(verbose) {
                  writeln(q);
                } else {
                  writeln(q.getNumElements());
                }
                //check that it's not too big
                if (q.getNumElements() > capacity) {
                    sizeRestricted.write(false);
                }
            }
        }
        //the thread that removes elements
        var rng = new NPBRandomStream(real);
        for i in initialNumElements + 1..initialNumElements + (capacity * numRounds) {
            var waitSeconds = rng.getNext() * maxRemoveWait;
            sleep(waitSeconds);
            q.remove();
            //print out the queue or the size
            if(verbose) {
              writeln(q);
            } else {
              writeln(q.getNumElements());
            }
            if (q.getNumElements() > capacity) {
                sizeRestricted.write(false);
            }
        }
    }
    writeln("Stress test completed!");
    timer.stop();

    //make sure all the elements are in the right place.
    for i in 1..initialNumElements {
        if (q.remove() != i) {
            inOrder = false;
        }
    }

    //return the results
    if (!sizeRestricted.read()) {
        return -1.0; //the size is not properly restricted
    } else if (!inOrder) {
        return -2.0; //the elements are not in the right place
    } else {
        //everything's okay!  Return the time the test took.
        return timer.elapsed();
    }
}
var stressTestA = blockingQueueStressTest(10, 5, .0001, .0001, 200, verbose);
var stressTestB = blockingQueueStressTest(20, 10, .09, .01, 20, verbose);
var stressTestC = blockingQueueStressTest(40, 20, .02, .09, 20, verbose);
var stressTestD = blockingQueueStressTest(200, 50, .01, .02, 20, false);

/*
var newQueue = new BlockingQueue(int, 13);

begin{
    for i in 0..299 {
        forall j in 1..500 {
            newQueue.add(i);
        }
    }
}

var i = 0;
while (i < 299)  {
    var y = newQueue.remove();
    if (y == i) {
        //it's cool
    } else if (y == i + 1) {
        if (i % 20 == 0) { writeln("Finished with i = ", i); }
        i += 1;
    } else if (y == i - 1) {
        //it's cool
    } else {
        writeln("Not cool!  Got a ", y, ", but was expecting something like ", i);
    }
}
writeln("Finished the stress test!");


writeln("Test for remove...");

var allCorrect = true;
for i in outputs.domain {
    allCorrect = allCorrect && outputs[i] == i;
}
if (allCorrect) {
    writeln("Correct!");
} else {
    writeln("Incorrect!!!!!!!!!!!!!!  -8 ");
}
*/



//Tests have finished.  Print out the report
writeln("******************************");
writeln("* Here is the report:");
writeln("*");

//report about the type tests
if (typeStringTest && typeIntTest && typeSemaphoreTest) {
    writeln("* All of the type tests passed!");
} else {
    if (!typeStringTest) {
        writeln("* Does not work with strings.");
    }
    if (!typeIntTest) {
        writeln("* Does not work with ints.");
    }
    if (!typeSemaphoreTest) {
        writeln("* Does not work with Semaphores.");
    }
}
writeln("* ");

//report about the blocking on remove tests
if (blockEmptyOnRemoveTestA && blockEmptyOnRemoveTestB && blockEmptyOnRemoveTestC) {
    writeln("* Blocks on remove when empty, good!");
} else {
    if (!blockEmptyOnRemoveTestA) {
        writeln("* The queue did not block on remove in Test A.");
    }
    if (!blockEmptyOnRemoveTestB) {
        writeln("* The queue did not block on remove in Test B.");
    }

    if (!blockEmptyOnRemoveTestC) {
        writeln("* The queue did not block on remove in Test C.");
    }
}
writeln("* ");

//report about the blocking on add tests
if (blockFullOnAddTestA && blockFullOnAddTestB) {
    writeln("* Blocks on add when full, great!");
} else {
    if (!blockFullOnAddTestA) {
        writeln("* The queue did not block on add in Test A.");
    }
    if (!blockFullOnAddTestB) {
        writeln("* The queue did not block on add in Test B.");
    }
}
writeln("* ");

//report about getNumElements
if (getNumElementsTestA == 0 && getNumElementsTestB == 3 && getNumElementsTestC == 10) {
    writeln("* getNumElements tests all passed!");
} else {
    if (getNumElementsTestA != 0) {
        writeln("* getNumElements returned ", getNumElementsTestA, " when it should have returned 0.");
    }
    if (getNumElementsTestB != 3) {
        writeln("* getNumElements returned ", getNumElementsTestB, " when it should have returned 3.");
    }
    if (getNumElementsTestC != 10) {
        writeln("* getNumElements returned ", getNumElementsTestC, " when it should have returned 10.");
    }
}
writeln("* ");

//report about FIFO-ness of Queue
if (orderTest[1] == 1 && orderTest[2] == 2 && orderTest[3] == 3 && orderTest[4] == 4 && orderTest[5] == 5 && orderTest[6] == 6 && orderTest[7] == 7 && orderTest[8] == 8 && orderTest[9] == 9 && orderTest[10] == 10) {
    writeln("* The queue is FIFO, good.");
} else {
    writeln("* After the order test, the queue should be [1, 2, 3, 4, 5, 6, 7, 8, 9, 10], but instead is ", orderTest, ".");
}
writeln("* ");

//report about Stress Tests
if (stressTestA >= 0 && stressTestB >= 0 && stressTestC >= 0 && stressTestD >= 0) {
    writeln("* Stress tests all passed!");
}
if (stressTestA < 0) {
    writeln("* Stress Test A failed.");
    if (stressTestA == -1.0) {
        writeln("  Sometimes there were more than the allowed number of elements.");
    } else if (stressTestA == -2.0) {
        writeln("  The final array was out of order!  Something went wrong!");
    }
} else {
    writeln("* Stress Test A ran in ", stressTestA, " seconds.");
}
if (stressTestB < 0) {
    writeln("* Stress Test B failed.");
    if (stressTestB == -1.0) {
        writeln("  Sometimes there were more than the allowed number of elements.");
    } else if (stressTestB == -2.0) {
        writeln("  The final array was out of order!  Something went wrong!");
    }
} else {
    writeln("* Stress Test B ran in ", stressTestB, " seconds.");
}
if (stressTestC < 0) {
    writeln("* Stress Test C failed.");
    if (stressTestC == -1.0) {
        writeln("  Sometimes there were more than the allowed number of elements.");
    } else if (stressTestC == -2.0) {
        writeln("  The final array was out of order!  Something went wrong!");
    }
} else {
    writeln("* Stress Test C ran in ", stressTestC, " seconds.");
}
if (stressTestD < 0) {
    writeln("* Stress Test D failed.");
    if (stressTestD == -1.0) {
        writeln("  Sometimes there were more than the allowed number of elements.");
    } else if (stressTestD == -2.0) {
        writeln("  The final array was out of order!  Something went wrong!");
    }
} else {
    writeln("* Stress Test D ran in ", stressTestD, " seconds.");
}

writeln("******************************");
writeln("If all the tests passed, you will need to hit Ctrl + C to kill the extra threads.");
