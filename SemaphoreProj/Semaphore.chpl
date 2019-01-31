/*
Jess Sullivan Semaphore attempts
//
35-40 secs fo first (20) test.  Does not change with code changes...  :(
compiled and run with:
$ chpl Semaphore.chpl -M testSemaphore.chpl && ./testSemaphore
*/
// Make a sync variable:  true and false!
var lock: sync bool;
// is atomic needed if a sync variable is doing the syncing?
var numTokens: atomic int;
proc p() {
  begin {
    lock = true;
    numTokens.sub(1);
    var unlock = lock;
  }
}
proc v() {
  begin {
    lock = true;
    numTokens.add(1);
    var unlock = lock;
  }
}
/*
Class / proc p() and v() are taken out of context to fiddle with
loops, cobegin, etc.  This does not appear to be at all useful for a semaphore's
job.
*/
class Semaphore {
  proc Semaphore() {
    // for loops appear to need a function to function, not just a class
    // also begin needs a something better than a class
    cobegin {  // this is useless for a switch, YOLO?
      p;
      v;
    }
  }
}
