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
config const T : int = 30; // default min thread?
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
class Cabinet {
  var c1$ : sync bool=true;
  var c2$ : sync bool=true;
  var c3$ : sync bool=true;
  // this method adds filenames to a domain
  proc UpdateMasterDom(Gate, (a,b)) {
    c1$.writeXF(true);
    do {
      c1$;
      if V then writeln("waiting @ c$");
     } while c1$.readXX() != true;
      if V then writeln("in UpdateMasterDom");
          c1$.writeXF(false);
          Fs.MasterDom += (a,b);
          c1$.writeXF(true);
        }
  proc ReadWriteManager(Gate, ref lineA, ref lineB, (a,b)) {
    if V then writeln("in ReadWriteManager");
    c3$.writeXF(true);
    do {
      c3$;
      if V then writeln("waiting @ c$, blocking");
     } while c3$.readXX() != true;
     c3$.writeXF(false);
     if V then writeln("preformed c$.writeXF(0) - should block");
     try {
     var tmpRead1 = openreader(a);
     var tmpRead2 = openreader(b);
     tmpRead1.readln(lineA);
     tmpRead2.readln(lineB);
     if lineA != lineB {
     if V then writeln("diffs " +lineA+ " and " +lineB);
         Gate.keeper(Fs.diff, (a,b));
         c3$.writeXF(true);
         } else {
           if V then writeln("sames " +lineA+ " and " +lineB);
             Gate.keeper(Fs.same, (a,b));
             c3$.writeXF(true);
           }
           c3$.writeXF(true);
            tmpRead1.close();
            tmpRead2.close();
         } catch {
        runCatch("ReadWriteManager");
      }
   }
 }
proc ParaGenerateDom() {
  var paraGenDomGate = new borrowed Gate;
  var paraGenDomCab = new borrowed Cabinet;
  coforall Banana in 1..#T {
      for a in findfiles(dir, recursive=true) {
        for b in findfiles(dir, recursive=true) {
          try {
            paraGenDomCab.UpdateMasterDom(paraGenDomGate, (a,b));
          } catch {
            runCatch("ParaGenerateDom");
          }
        }
      }
    }
  }
proc SerialGenerateDom() {
  var SerialGenDomGate = new borrowed Gate;
  var SerialGenDomCab = new borrowed Cabinet;
      for a in findfiles(dir, recursive=true) {
        for b in findfiles(dir, recursive=true) {
          try {
            SerialGenDomCab.UpdateMasterDom(SerialGenDomGate, (a,b));
          } catch {
            runCatch("SerialGenerateDom");
          }
        }
      }
    }
proc parallelFullCheck() {
  if V then writeln("in parallelFullCheck");
  var paraFullGate = new borrowed Gate;
  var paraCabinet = new borrowed Cabinet;
  coforall Banana in 1..#T {
      coforall (a,b) in Fs.MasterDom {
        var lineA : string;
        var lineB : string;
        if exists(a) && exists(b) && a != b {
          if isFile(a) && isFile(b) {
            if getFileSize(a) == getFileSize(b) {
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
    }
proc serialFullCheck() {
  if V then writeln("in serialFullCheck");
  var serialFullGate = new borrowed Gate;
  var serialCabinet = new borrowed Cabinet;
  for (a,b) in Fs.MasterDom {
    var lineX : string;
    var lineY : string;
        if exists(a) && exists(b) && a != b {
          if isFile(a) && isFile(b) {
            if getFileSize(a) == getFileSize(b) {
              try {
                serialCabinet.ReadWriteManager(serialFullGate, lineX, lineY, (a,b));
                } catch {
                  runCatch("serialFullCheck");
                }
              }
            }
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
  writeln("doing SerialGenerateDom()");
  SerialGenerateDom();
  if V then writeln("entering FullCheck()");
  serialFullCheck();
  if V then writeln("Completed FullCheck() \n" +
  " Beginning WriteFiles");
  serialWrite();
  SpeedTest.stop();
  writeln("Serial FileCheck completed in " +
  SpeedTest.elapsed());
    } else {
    writeln("starting FileCheck in Parallel, started timer...");
    writeln("doing paraGenerateDom()");
    ParaGenerateDom();
    //ParaGenerateDom();
    if V then writeln("entering FullCheck()");
    parallelFullCheck();
    if V then writeln("Completed FullCheck() \n" +
    " Beginning WriteFiles()");
    serialWrite();
    SpeedTest.stop();
    writeln("Parallel FileCheck completed in " +
    SpeedTest.elapsed());
}
