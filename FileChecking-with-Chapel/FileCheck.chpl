/**********************************
* read check files at line level for duplicates.
* Use --S=true for Serial, defaults to parallel processing.
* WIP by Jess Sullivan
* Usage: chpl FileCheck.chpl && ./FileCheck # to run this file
**********************************/
use FileSystem;
use Time;
var SpeedTest: Timer;
config const T : int = 1; // default min token?    ?
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
  var numThreads = 0;
}
// add a per-function try-catch catcher.
proc runCatch(function : string) {
  if V then writeln("Caught another error, from ", function);
}
//
proc readEval(ref lineA, ref lineB, (a,b)) {
  try {
    var tmpRead1 = openreader(a);
    var tmpRead2 = openreader(b);
    tmpRead1.readln(lineA);
    tmpRead2.readln(lineB);
    } catch {
      runCatch("readEval()");
    }
    return (lineA,lineB);
  }
class Gate {
  var D$ : sync bool=true;
  proc keeper(ref keys, (a,b)) {
    var tasks : atomic int;
    tasks.write(T);
    D$.writeXF(true);
    if V then writeln("waiting on D$");
    do {
      D$;
     } while tasks.read() < 1;
     D$.writeXF(true);
     tasks.sub(1);
     keys += (a,b);
     tasks.add(1);
    }
  }
class Cabinet {
  var c1$ : sync bool=true;
  var c3$ : sync bool=true;
  // this method adds filenames to a domain
  proc UpdateMasterDom(Gate, (a,b)) {
    var SGDtasks : atomic int;
    SGDtasks.write(T);
    c1$.writeXF(true);
    do {
      c1$;
      if V then writeln("waiting @ c1$");
      } while SGDtasks.read() < 1;
      if V then writeln("in UpdateMasterDom");
          SGDtasks.sub(1);
          Fs.MasterDom += (a,b);
          Fs.numThreads += 1;
          SGDtasks.add(1);
          c1$.writeXF(true);
        }
  proc ReadWriteManager(Gate, ref lineA, ref lineB, (a,b)) {
    if V then writeln("in ReadWriteManager");
    var PFCtasks : atomic int;
    PFCtasks.write(T);
    c3$.writeXF(true);
    do {
      c3$;
      if V then writeln("waiting @ c3$, blocking");
      } while PFCtasks.read() < 1;
     PFCtasks.sub(1);
     readEval(lineA, lineB, (a,b));
     if lineA != lineB {
     if V then writeln("diffs " +lineA+ " and " +lineB);
         Gate.keeper(Fs.diff, (a,b));
         PFCtasks.add(1);
         c3$.writeXF(true);
         } else {
           if V then writeln("sames " +lineA+ " and " +lineB);
             Gate.keeper(Fs.same, (a,b));
             PFCtasks.add(1);
             c3$.writeXF(true);
        }
      }
    }
// get files
var files = for i in findfiles(dir, recursive=true) do i;

proc SerialGenerateDom() {
  var SerialGenDomGate = new borrowed Gate;
  var SerialGenDomCab = new borrowed Cabinet;
      for a in files {
        for b in files {
          if exists(a) && exists(b) && a != b {
            if isFile(a) && isFile(b) {
              if getFileSize(a) == getFileSize(b) {
                try {
      SerialGenDomCab.UpdateMasterDom(SerialGenDomGate, (a,b));
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
  var paraFullGate = new borrowed Gate;
  var paraCabinet = new borrowed Cabinet;
  // this doesn't make it go any faster
  coforall (a,b) in Fs.MasterDom {
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
  var serialFullGate = new borrowed Gate;
  var serialCabinet = new borrowed Cabinet;
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
if S {
  writeln("starting FileCheck in Serial, started timer...");
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
      writeln("\n As of this message, there is no real difference between \n"+
      "serial and parallel versions.  SerialGenerateDom is many times slower \n"+
      "than and diff checks tried thus far. \n");
      writeln("starting FileCheck, started timer...");
      if V then writeln("doing SerialGenerateDom()");
      var SerialGenerateDomSpeed2: Timer;
      SerialGenerateDomSpeed2.start();
      SerialGenerateDom();
      SerialGenerateDomSpeed2.stop();
      writeln("completed SerialGenerateDom() in "+SerialGenerateDomSpeed2.elapsed());
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
