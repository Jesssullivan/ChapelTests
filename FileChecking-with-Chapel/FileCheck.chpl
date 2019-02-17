/**********************************
* read check files at line level for duplicates.
* Use --S=true for Serial, defaults to parallel processing.
* WIP by Jess Sullivan
* Usage: chpl FileCheck.chpl && ./FileCheck # to run this file
**********************************/
use FileSystem;
use Time;

// standard --flags
config const S : bool=false;  // override parallel, use Serial looping?
config const PURE : bool =false;  // compile masterDom in serial?
config const V : bool=false; // Vebose output of actions
// use internal Chapel timers?  default is false, in favor of
//  external Python3 timer scripts, in repo
config const T : bool=false;

// add extra debug options
config const debug : bool=false;  // enable verbose logging from within loops.
config const dir = "."; // start here?
config const ext = ".txt";  // use alternative ext?
config const R : bool=true; // compile report file?
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
  var Duo : atomic int;
  proc keeper(ref keys, (a,b)) { // use "ref keys" due to constant updating of this domain
    Duo.write(1);
    D$.writeXF(true); // init open
    do {
      if debug then writeln("waiting @ Gate D$...");
      D$;
     } while Duo.read() < 1;
     Duo.sub(1);
     keys += (a,b);
     if debug then writeln("Gate opened! added keys " + (a,b));
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
    if debug then writeln("in ReadWriteManager");
    PFCtasks.write(1);
    c3$.writeXF(true);
    do {
      if debug then writeln("waiting @ Cabinet c3$...");
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
        if debug then writeln("diffs " +lineA+ " and " +lineB);
         Gate.keeper(Fs.diff, (a,b));
         c3$.writeXF(true);
         PFCtasks.add(1);
         } else {
           if debug then writeln("sames " +lineA+ " and " +lineB);
             Gate.keeper(Fs.same, (a,b));
             c3$.writeXF(true);
             PFCtasks.add(1);
        }
      }
    }
// populates Fs.MasterDom using coforall
var ParallelGenDomGate = new Gate;
proc PGD(folder) {
for a in findfiles(folder, recursive=false) {
  for b in findfiles(folder, recursive=false) {
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
// use the above function PGD for each directory listed by walkdirs(dir)
proc ParallelGenerateDom() {
  // TODO: evaluate accuracy with larger sets of files/subdirs
  // this method may yield different results then the pure serial version.
  coforall folder in walkdirs(dir) {
      PGD(folder);
      }
    }
// populates Fs.MasterDom using for loops, only used with --S --PURE
proc serialGenerateDom() {  // relies on findfiles(dir, recursive-true)
  if PURE {
    // recursive findfiles() is not a great solution- using a timer to see
    // how badly it fares
    var FindFilesTime = new Timer;
    if V then writeln("staring to populate Fs.MasterDom with findfiles(dir, recursive=true) \n" +
    " will print time elapsed for this operation, please wait...");
    FindFilesTime.start();
    var files = findfiles(dir, recursive=true);
    FindFilesTime.stop();
    if V then writeln("findfiles(dir, recursive=true) completed in " + FindFilesTime.elapsed());
       for a in files {
        for b in files {
          if exists(a) && exists(b) && a != b {
            if isFile(a) && isFile(b) {
              if getFileSize(a) == getFileSize(b) {
                  try {
                    // no need for Gate or Cabinet class during serial
                    Fs.MasterDom += (a,b);
                    } catch {
              runCatch("serialGenerateDom", a,b);
              }
            }
          }
        }
      }
    }
  } else {
    ParallelGenerateDom();
    if V then writeln("used parallel ParallelGenerateDom() due to findfile() limitations");
  }
}

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
        var tmpRead1 = openreader(a);
        var tmpRead2 = openreader(b);
        tmpRead1.readln(lineX); // used in favor of readline() method ~ accuracy?
        tmpRead2.readln(lineY);
        } catch {
          runCatch("readEval()", a,b);
        }
        if lineX != lineY {
          Fs.diff += (a,b);
          } else {
          Fs.same += (a,b);
    }
  }
}
// configure a naming scheme
proc NameScheme(name : string) : string {
  var RunName : string;
  if S {
    if PURE {
      RunName = "Serial--PURE";
    } else {
      RunName = "Serial";
        }
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

proc EnterEnder(run : string) {
  if S {
    if PURE {
      writeln(run + " FileCheck with complete serial operation...");
    } else {
    writeln(run + " FileCheck with serial duplicate evaluation...");
  }
  } else {
    writeln(run + " FileCheck in full parallel");
  }
}
proc RunStyle() {
  if S {
    if V then writeln("doing SerialGenerateDom()");
    var SerialTime = new Timer;
    if T then SerialTime.start();
    var serialGenerateDomSpeed: Timer;
    if T then serialGenerateDomSpeed.start();
    serialGenerateDom();  // if PURE is handled in this function
    if T then serialGenerateDomSpeed.stop();
    if T {
      if V {
        writeln("completed all of SerialGenerateDom() in "+serialGenerateDomSpeed.elapsed());
      }
    }
    if V then writeln("entering FullCheck()");
    var serialFullCheckSpeed: Timer;
    if T then serialFullCheckSpeed.start();
    serialFullCheck();
    if T then serialFullCheckSpeed.stop();
    if T {
      if V {
        writeln("Completed FullCheck() in "+serialFullCheckSpeed.elapsed()+
    " Beginning WriteFiles");
        }
      }
      if R then serialWrite();
    SerialTime.stop();
    if T {
      if V {
        writeln("Serial FileCheck completed in " +
    SerialTime.elapsed());
          }
        }
      } else {  //  full parallel default
        var ParaTime = new Timer;
        if T then ParaTime.start();
        if V then writeln("doing ParallelGenerateDom()");
        var paraGenerateDomSpeed2: Timer;
        if T then paraGenerateDomSpeed2.start();
        ParallelGenerateDom();
        if T then paraGenerateDomSpeed2.stop();
        if T {
          if V {
            writeln("completed ParallelGenerateDom() in "+paraGenerateDomSpeed2.elapsed());
          }
        }
        if V then writeln("entering FullCheck()");
        var parallelFullCheckSpeed: Timer;
        if T then parallelFullCheckSpeed.start();
        parallelFullCheck();
        if T then parallelFullCheckSpeed.stop();
        if T {
          if V {
        writeln("Completed FullCheck() in "+parallelFullCheckSpeed.elapsed()+
        " Beginning WriteFiles");
      }
    }
        if R then serialWrite();
        if T then ParaTime.stop();
        if T {
          if V {
            writeln("Serial FileCheck completed in " +
        ParaTime.elapsed());
              }
            }
  }
}
// call everything in a mildly more organized way:
EnterEnder("Starting");
RunStyle();
EnterEnder("completed");
