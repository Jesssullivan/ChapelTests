/******************************
* Understanding Sync$ variables and how to use them
* A WIP by Jess Sullivan
******************************/
use Time;
// toggles for python timer:
config const V : bool=false;
config const UnSyncedParallel_Int : bool=false;
config const UnSyncedParallel_String : bool=false;
config const SyncedParallel_Int : bool=false;
config const SyncedParallelS_String : bool=false;
config const SerialLoop_Int : bool=false;
config const SerialLoop_String : bool=false;

var he = "he", ll = "ll", o = "o ", wo = "wo", rl = "rl", d = "d!";
var listChars = (he,ll,o,wo,rl,d);
/******************************
Problem A:  integers
Simple Race Condition example:

PrintNum will NOT equal 10000, and will usually be
a different number each time!
******************************/

  var t1 = new Timer; // time each version
  t1.start();

  module A { // use a module to remove the "lvalue" or shadow variable errors.
    var Num = 0;
  }
  if UnSyncedParallel_Int {
  coforall i in 1..100000 {
    A.Num += 1;
  }
  t1.stop();
  if V then writeln("The below number should be 100000 \n " + A.Num);
  if V then writeln("...but it probably was not, this took " + t1.elapsed() + " secs");
}
/******************************
Problem B: Strings
A more sophisticated (and more likely) scenario
using strings- race conditions and and other  "parallel snafus"
are everywhere!
******************************/
  var t2 = new Timer; // time each version
  t2.start();

  module char {
    var group = ("");
  }
  if UnSyncedParallel_String {
  coforall i in listChars {
    char.group += (i);
  }
  t2.stop();
  if V then writeln("The phrase below should say  'hello world!'\n" + char.group);
  if V then writeln("...but it probably does not, this took " + t2.elapsed() + " secs");
}
/******************************
Fix Problem A:
******************************/
var t3 = new Timer; // time each version
t3.start();

module Aa {
    var Num = 0;
}
var s1$ : sync bool;
s1$ = true;

  proc TaskToAdd() {
    s1$;
    Aa.Num += 1;
    s1$ = true;
  }
  if SyncedParallel_Int {
  coforall i in 1..100000 {
    TaskToAdd();
  }
  t3.stop();
  if V then writeln("The below number should be 100000 \n " + Aa.Num);
  if V then writeln("...AND it SHOULD, this took " + t3.elapsed() + " secs");
}
/******************************
Fix Problem B with a Gate class:
******************************/

module char2 {
  var group = ("");
}
var x$: sync bool;
x$ = true;
proc TaskToDo(i) {
  x$;
  char2.group += (i);
  x$ = true;
}

var t4 = new Timer; // time each version
t4.start();

  if SyncedParallelS_String {
  coforall i in listChars {
    TaskToDo(i);
  }
  t4.stop();
  if V then writeln("The phrase below should say 'hello world!'\n" + char2.group);
  if V then writeln("...And I hope it does. this took " + t4.elapsed() + " secs");
}


module Aaa { // use a module to remove the "lvalue" or shadow variable errors.
  var Num = 0;
}
var t5 = new Timer; // time each version
t5.start();
  if SerialLoop_Int {
  for i in 1..100000 {
    Aaa.Num += 1;
  }
  t5.stop();
  if V then writeln("The below number should be 100000 \n " + Aaa.Num);
  if V then writeln("above is completely serial operation, it took " + t5.elapsed() + " secs");
}
var t6 = new Timer; // time each version
t6.start();

module charxx {
    var group = ("");
  }
  if SerialLoop_String {
  for i in listChars {
    charxx.group += (i);
  }
  t6.stop();
  if V then writeln("The phrase below should say 'hello world!'\n" + charxx.group);
  if V then writeln("above is completely serial operation, it took " + t6.elapsed() + " secs");
}
