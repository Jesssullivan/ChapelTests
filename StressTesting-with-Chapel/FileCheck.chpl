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
// add extra debug options
config const V : bool=false; // Vebose output of actions
config const ext = ".txt";  // use alternative ext?
config const SAME = "SAME";
config const DIFF = "DIFF";
// Use module Fs to isolate domains during coforall looping.
// these domains are only modified with a Gate and Cabinet class.
module Fs {
  // using MasterDom during a "first pass" to find all same size files as (a,b).
  // this must be known before evaluation!
  var MasterDom = {("", "")};  // contains same size files as (a,b).
  var same = {("", "")};  // identical files
  var diff = {("", "")};  // sorted files flagged as same size but are not identical
}
// add a per-function try-catch catcher.
proc runCatch(function : string, arg1 : string, arg2 : string) {
  if V then writeln("Caught another error, from " + function + " while "+
  "processing \n" + arg1 +" and "+ arg2);
}
/*
Class Gate is a {generic class, no init()} way to maintain thread safety while
a coforall loop tries to update one domain (ref keys) with many
live threads and new entries {("", "")}. A new borrowed Gate class is made per
function that need to be operate on a domain, with the "Gate.keeper".
Safety is (tentatively) achieved with the Gate.keeper()
syncing its "keys" - a generic domain from within module "Fs" -
with a Sync$ variable used in concert with an atomic integer that may be
1 or 0 - open or closed - go or wait.
*/
class Gate {
  var D$ : sync bool=true;
  proc keeper(ref keys, (a,b)) { // use "ref keys" due to constant updating of this domain
    var Duo : atomic int;
    Duo.write(1);
    D$.writeXF(true); // init open
    do {
      if V then writeln("waiting @ Gate D$");
      D$;
     } while Duo.read() < 1;
     Duo.sub(1);
     keys += (a,b);
     Duo.add(1);
     D$.writeXF(true);
    }
  }
/*
Class Cabinet manages the dupe evaluation.
this is a {generic class, no init()} way to maintain thread safety by not only
sandboxing the read/write operations to a domain,
but all evaluations. class Gate is use inside each Cabinet
to preform the actual domain transactions.
 */
class Cabinet {
  var c3$ : sync bool=true;
  var PFCtasks : atomic int;
  proc ReadWriteManager(Gate, ref lineA, ref lineB, (a,b)) {
    if V then writeln("in ReadWriteManager");
    PFCtasks.write(1);
    c3$.writeXF(true);
    do {
      if V then writeln("waiting @ Cabinet c3$");
      c3$;
        } while PFCtasks.read() < 1;
     PFCtasks.sub(1);  // close
     try {
       var tmpRead1 = openreader(a);
       var tmpRead2 = openreader(b);
       tmpRead1.readln(lineA); // used in favor of readline() method ~ accuracy?
       tmpRead2.readln(lineB);
       } catch {
         runCatch("readEval()", a,b);
       }
      if lineA != lineB {
        if V then writeln("diffs " +lineA+ " and " +lineB);
         Gate.keeper(Fs.diff, (a,b));
         c3$.writeXF(true);
         PFCtasks.add(1);
         } else {
           if V then writeln("sames " +lineA+ " and " +lineB);
             Gate.keeper(Fs.same, (a,b));
             c3$.writeXF(true);
             PFCtasks.add(1);
        }
      }
    }

// globally find all files. this may take a while.
var files = findfiles(dir, recursive=true);

// populates Fs.MasterDom using coforall
proc ParallelGenerateDom() {
    var ParallelGenDomGate = new Gate;
      coforall a in files {
        coforall b in files {
          if exists(a) && exists(b) && a != b {
            if isFile(a) && isFile(b) {
              if getFileSize(a) == getFileSize(b) {
                  try {
        ParallelGenDomGate.keeper(Fs.MasterDom, (a,b));
              } catch {
                runCatch("parallelGenerateDom", a,b);
                    }
                  }
                }
              }
            }
          }
        }

// populates Fs.MasterDom using for loops, only used with --S
proc SerialGenerateDom() {
    var serialGenDomGate = new Gate;
      for a in files {
        for b in files {
          if exists(a) && exists(b) && a != b {
            if isFile(a) && isFile(b) {
              if getFileSize(a) == getFileSize(b) {
                  try {
      serialGenDomGate.keeper(Fs.MasterDom, (a,b));
            } catch {
              runCatch("SerialGenerateDom", a,b);
              }
            }
          }
        }
      }
    }
  }
  // populates Fs.MasterDom using for loops, only used with --S
proc parallelFullCheck() {
  if V then writeln("in parallelFullCheck");
  var paraFullGate = new Gate;
  var paraCabinet = new Cabinet;
  coforall (a,b) in Fs.MasterDom {
      var lineA : string;
      var lineB : string;
            try {
          paraCabinet.ReadWriteManager(paraFullGate, lineA, lineB, (a,b));
              } catch {
                runCatch("parallelFullCheck", a,b);
            }
          }
        }
proc serialFullCheck() {
  if V then writeln("in serialFullCheck");
  var serialFullGate = new Gate;
  var serialCabinet = new Cabinet;
  for (a,b) in Fs.MasterDom {
    var lineX : string;
    var lineY : string;
      try {
        serialCabinet.ReadWriteManager(serialFullGate, lineX, lineY, (a,b));
        } catch {
          runCatch("parallelFullCheck", a,b);
      }
    }
  }
// configure a naming scheme, used more if dates / zip are going to be a thing
proc NameScheme(name : string) : string {
  var RunName : string;
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
//no real need (write to disk is way slower than me threads)
proc serialWrite() {
  WriteAll(SAME, Fs.same);
  WriteAll(DIFF, Fs.diff);
}
// verbose run things.
SpeedTest.start();
writeln("starting FileCheck, started timer...");
if S {
  if V then writeln("doing SerialGenerateDom()");
  var SerialGenerateDomSpeed: Timer;
  SerialGenerateDomSpeed.start();
  SerialGenerateDom();
  SerialGenerateDomSpeed.stop();
  writeln("completed SerialGenerateDom() in "+SerialGenerateDomSpeed.elapsed());
  if V then writeln("entering FullCheck()");
  var serialFullCheckSpeed: Timer;
  serialFullCheckSpeed.start();
  serialFullCheck();
  serialFullCheckSpeed.stop();
  writeln("Completed FullCheck() in "+serialFullCheckSpeed.elapsed()+
  " Beginning WriteFiles");
  serialWrite();
  SpeedTest.stop();
  writeln("Serial FileCheck completed in " +
  SpeedTest.elapsed());
    } else {
      if V then writeln("doing ParallelGenerateDom()");
      var paraGenerateDomSpeed2: Timer;
      paraGenerateDomSpeed2.start();
      ParallelGenerateDom();
      paraGenerateDomSpeed2.stop();
      writeln("completed ParallelGenerateDom() in "+paraGenerateDomSpeed2.elapsed());
      if V then writeln("entering FullCheck()");
      var parallelFullCheckSpeed: Timer;
      parallelFullCheckSpeed.start();
      parallelFullCheck();
      parallelFullCheckSpeed.stop();
      writeln("Completed FullCheck() in "+parallelFullCheckSpeed.elapsed()+
      " Beginning WriteFiles");
      serialWrite();
      SpeedTest.stop();
      writeln("FileCheck completed in " +
      SpeedTest.elapsed());
}
