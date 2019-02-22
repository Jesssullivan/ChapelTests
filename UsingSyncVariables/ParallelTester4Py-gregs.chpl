/******************************
* Understanding Sync$ variables and how to use them
* A WIP by Jess Sullivan
******************************/
use Time;
// toggles for python timer:
config const verbose : bool=true;
config const numTasks : int = 10000;
config const useSync : bool = false;

/******************************
Problem A:  integers
Simple Race Condition example:

PrintNum will NOT equal 10000, and will usually be
a different number each time!
******************************/

module A { 
  var num : int = 0;
  var num$ : sync int = 0;
}

coforall i in 1..numTasks {
  var x : int;
  if useSync {
    x = A.num$.readFE();   // wait until gain exclusive access to Num$
    x = x + 1;
    A.num$.writeXF(x);		// release sync var
  } else {
    x = A.num;
    x = x + 1;
    A.num = x;
  }
}
if verbose then {
  write("Following should be " + numTasks + ": ");
  if useSync {
    writeln(A.num$.readXX());
  } else {
    writeln(A.num);
  }
}  
