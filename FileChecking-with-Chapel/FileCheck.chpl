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
  var MasterDom = {("", "")};
  var same = {("", "")};
  var diff = {("", "")};
}
// add a per-function try-catch catcher.
proc runCatch(function : string) {
  if V then writeln("Caught another error, from ", function);
}
class Gate {
  var D$ : sync bool=true;
  proc keeper(ref keys, (a,b)) {
    var Duo : atomic int;
    Duo.write(1);
    D$.writeXF(true);
    if V then writeln("waiting on D$");
    do {
      D$;
     } while Duo.read() < 1;
     D$.writeXF(true);
     Duo.sub(1);
     keys += (a,b);
     Duo.add(1);
    }
  }
class Cabinet {
  proc ReadWriteManager(Gate, ref lineA, ref lineB, (a,b)) {
    var c3$ : sync bool=true;
    if V then writeln("in ReadWriteManager");
    var PFCtasks : atomic int;
    PFCtasks.write(1);
    c3$.writeXF(true);
    do {
      c3$;
      break;
        } while PFCtasks.read() < 1;
     PFCtasks.sub(1);
     try {
       var tmpRead1 = openreader(a);
       var tmpRead2 = openreader(b);
       tmpRead1.readln(lineA);
       tmpRead2.readln(lineB);
       } catch {
         runCatch("readEval()");
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
var files = findfiles(dir, recursive=true);
proc ParallelGenerateDom() {
    var ParallelGenDomGate = new Gate;
      coforall (a) in files {
        coforall (b) in files {
          if exists(a) && exists(b) && a != b {
            if isFile(a) && isFile(b) {
              if getFileSize(a) == getFileSize(b) {
                  try {
        ParallelGenDomGate.keeper(Fs.MasterDom, (a,b));
              } catch {
                runCatch("parallelGenerateDom");
                    }
                  }
                }
              }
            }
          }
        }
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
              runCatch("SerialGenerateDom");
              }
            }
          }
        }
      }
    }
  }
proc parallelFullCheck() {
  if V then writeln("in parallelFullCheck");
  var paraFullGate = new Gate;
  var paraCabinet = new Cabinet;
  coforall (a,b) in Fs.MasterDom {
      try {
        paraFullGate.keeper(Fs.MasterDom, (a,b));
      } catch {
        runCatch("Eval coforall loop - parallelFullCheck");
      }
      var lineA : string;
      var lineB : string;
            try {
          paraCabinet.ReadWriteManager(paraFullGate, lineA, lineB, (a,b));
              } catch {
                runCatch("parallelFullCheck");
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
          runCatch("parallelFullCheck");
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
      if V then writeln("doing SerialGenerateDom()");
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
