/**
 * Implements a multi-token semaphore.
 * 
 * Authors: XXXXXXXXX
 */

use Time;

class Semaphore {
  //the number of tokens available
  var numTokens : atomic int;

  proc Semaphore() {
    this.numTokens.write(1);
  }

  proc Semaphore(n : int) {
    this.numTokens.write(n);
  }

  proc writeThis(writer) {
    writer.write("Semaphore(" + this.numTokens.read() + ")");
  }

  proc getNumTokens() : int {
    return this.numTokens.read();
  }

  // p for proberen, "to try"
  proc p() {
    while(this.numTokens.read() <= 0) {
      sleep(2);
    }
    this.numTokens.sub(1); //removes one token
  }

  // v for verhogen, "increase"
  proc v() {
    this.numTokens.add(1);
  }

}

