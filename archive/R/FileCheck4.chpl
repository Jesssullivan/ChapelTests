/**********************************
* read check files at line level for duplicates.
* Use --S=true for Serial, defaults to parallel processing.
* WIP by Jess Sullivan
* Usage: chpl FileCheck.chpl && ./FileCheck # to run this file
**********************************/
use FileSystem;
use Time;
var SpeedTest: Timer;

config const S : bool=false;  // override parallel, use Serial looping?
config const dir = "."; // start here?
config const SAME = "SAME";
config const DIFF = "DIFF";
// add extra debug options
config const V : bool=false; // Vebose output of actions
config const ext = ".txt";  // use alternative ext?
// Use module Fs to isolate domains during coforall looping.
// these domains are only modified with a Gate and Cabinet class.
module Fs {
  var sameSizeFiles = {("", "")};
  var same = {("", "")};
  var diff = {("", "")};
}
// add a per-function try-catch counter.
proc runCatch(function : string) {
  if V then writeln("Caught another error, from ", function);
}
/*
class Gate is a generic way to maintain thread safety
while a coforall loop tries to update one domain with
many threads and new keys {("", "")} to enter. a new borrowed
Gate class is made per set of keys that need to be managed.
:)
Safety is  achieved with the Gate.keeper() syncing its
"keys" - a generic domain- any of those kept in module Fs-
...only while inside a Cabinet!  See below for class Cabinet.
*/
class Gate {
  var D$ : sync bool=true;
  proc keeper(ref keys, (a,b)) {
    D$.writeXF(true);
    if V then writeln("waiting on D$");
    do {
      D$;
     } while D$.readXX() != true;
     D$.writeXF(false);
     keys += (a,b);
     D$.writeXF(true);
    }
  }
/*
class Cabinet manages dupe evaluation functions.
this is a generic way to maintain thread safety by not only sandboxing
the read/write operations to a domain, but all evaluations.
class Gate is use inside each Cabinet to preform the actual domain transactions.
a new borrowed Cabinet is created with each set of keys
(e.g. with any function that needs to operate on a domain)
*/
class Cabinet {
  var c$ : sync bool=true;
  proc SizeEval(Gate, (a,b)) {
    c$.writeXF(true);
    do {
      c$;
      if V then writeln("waiting @ c$");
     } while c$.readXX() != true;
    if V then writeln("in SizeEval");
    if (getFileSize(a) == getFileSize(b)) &&
      a != b {
        c$.writeXF(false);
        Gate.keeper(Fs.sameSizeFiles, (a,b));
        c$.writeXF(true);
        if V then writeln(a,b);
      }
      c$.writeXF(true);
    }
  proc ReadWriteManager(Gate, ref lineA, ref lineB, (a,b)) {
    if V then writeln("in ReadWriteManager");
    c$.writeXF(true);
    do {
      c$;
      if V then writeln("waiting @ c$, blocking");
     } while c$.readXX() != true;
     c$.writeXF(false);
     if V then writeln("preformed c$.writeXF(0) - should block");
     try {
     var tmpRead1 = openreader(a);
     var tmpRead2 = openreader(b);
     tmpRead1.readln(lineA);
     tmpRead2.readln(lineB);
     if lineA != lineB {
       if V then writeln("diffs " +lineA+ " and " +lineB);
       if (a,b) != (b,a) {
         Gate.keeper(Fs.diff, (a,b));
         c$.writeXF(true);
       }
       if V then writeln("preformed c$.writeXF(1);");
     } else {
       if V then writeln("sames " +lineA+ " and " +lineB);
       if (a,b) != (b,a) {
       Gate.keeper(Fs.same, (a,b));
       c$.writeXF(true);
     }
       if V then writeln("preformed c$.writeXF(1);");
     }
      c$.writeXF(true);
       tmpRead1.close();
       tmpRead2.close();
     } catch {
        runCatch("ReadWriteManager");
      }
   }
 }
  // SizeCheck() functions must be thread safe...
  /********
proc parallelSizeCheck() {
  if V then writeln("in parallelSizeCheck");
  var paraGate = new borrowed Gate;
  var ParaCab = new borrowed Cabinet;
    coforall folder in walkdirs(dir) {
      //
      this presents a problem.  findfiles is slow, and this way is fast
      because it will create a new task per folder in walkdirs().
      this also means it will not find dupes that live in different
      folders.  default for both SerialRun and paraRun is to size check in
      serial.
       //
      for a in findfiles(folder, recursive=false) {
        for b in findfiles(folder, recursive=false) {
        try {
          ParaCab.SizeEval(paraGate, (a,b));
        } catch {
          runCatch("parallelSizeCheck");
          }
        }
      }
    }
  }
********/

// default method
proc serialSizeCheck() {
  if V then writeln("in serialSizeCheck");
  var serialGate = new borrowed Gate;
  var serialCab = new borrowed Cabinet;
  var listall = findfiles(dir, recursive=true);
    for a in listall {
      for b in listall {
      try {
        serialCab.SizeEval(serialGate, (a,b));
      } catch {
        runCatch("serialSizeCheck");
      }
    }
  }
}
// FullCheck() functions must be thread safe.
proc parallelFullCheck() {
  if V then writeln("in parallelFullCheck");
  var paraFullGate = new borrowed Gate;
  var paraCabinet = new borrowed Cabinet;
  coforall (a,b) in Fs.sameSizeFiles {
    var lineA : string;
    var lineB : string;
    for a in (a,b) {
      for b in (a,b) {
        if isFile(a) && isFile(b) &&
        exists(a) && exists(b) &&
        a != b {
          try {
            paraCabinet.ReadWriteManager(paraFullGate, lineA, lineB, (a,b));
            } catch {
              runCatch("parallelFullCheck");
            }
          }
        }
      }
    }
  }
proc serialFullCheck() {
  if V then writeln("in serialFullCheck");
  var serialFullGate = new borrowed Gate;
  var serialCabinet = new borrowed Cabinet;
  for (a,b) in Fs.sameSizeFiles {
        var lineX : string;
        var lineY : string;
        if isFile(a) && isFile(b) &&
        exists(a) && exists(b) &&
        a != b {
        try {
          serialCabinet.ReadWriteManager(serialFullGate, lineX, lineY, (a,b));
          } catch {
          runCatch("serialFullCheck");
        }
      }
    }
  }
// configure a naming scheme, used more if dates / zip are going to be a thing
proc NameScheme(name : string) : string {
  var RunName : string;
  var opt : string;
  if S {
    RunName = "Serial";
    } else {
      RunName = "Parallel";
    }
      return RunName+name+ext;
    }
// generic write function for either domain
proc WriteAll(N : string, content) {
  var OFile = open(NameScheme(N), iomode.cw);
  var Ochann = OFile.writer();
  Ochann.write(content);
  Ochann.close();
  OFile.close();
}
// could write in parrallel
//no real need (write to disk is way slower than threads)
proc serialWrite() {
  WriteAll(SAME, Fs.same);
  WriteAll(DIFF, Fs.diff);
}
// verbose run functions.
proc SerialRun() {
  writeln("starting FileCheck in Serial, beginning timer...");
  SpeedTest.start();
  if V then writeln("entering SizeCheck()");
  serialSizeCheck();
  if V then writeln("Completed SizeCheck() \n" +
  " entering FullCheck()");
  serialFullCheck();
  if V then writeln("Completed FullCheck() \n" +
  " Beginning WriteFiles");
  serialWrite();
  SpeedTest.stop();
  writeln("Serial FileCheck completed in " +
  SpeedTest.elapsed());
}
proc paraRun() {
  writeln("starting FileCheck in Parallel, beginning timer...");
  SpeedTest.start();
  if V then writeln("entering SizeCheck()");
  //  parallelSizeCheck() needs a smart thing, can't check dupes in different dirs
  // .....yet
  //  parallelFullCheck();
    serialSizeCheck();
  if V then writeln("Completed SizeCheck() \n" +
  " entering FullCheck()");
  parallelFullCheck();
  if V then writeln("Completed FullCheck() \n" +
  " Beginning WriteFiles()");
  serialWrite();
  SpeedTest.stop();
  writeln("Parallel FileCheck completed in " +
  SpeedTest.elapsed());
}
// call an above setup.
if S {
  SerialRun();
  } else {
      paraRun();
  }
