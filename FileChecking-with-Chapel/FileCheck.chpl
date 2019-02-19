/**********************************
* read check files at char level for duplicates.
* Use --S=true for Serial, defaults to parallel processing.
* WIP by Jess Sullivan
* Usage: chpl FileCheck.chpl && ./FileCheck # to run this file
**********************************/
use FileSystem;
use Time;


// serial options:
config const SE : bool=false; // use serial evaluation?
config const SP : bool=false; // use findfiles() as mastserDom method?

// logging options
config const V : bool=true; // Vebose output of actions?
config const debug : bool=false;  // enable verbose logging from within loops?
config const T : bool=true; // use internal Chapel timers?
config const R : bool=true; // compile report file?

// file options
config const dir = "."; // start here?
config const ext = ".txt";  // use alternative ext?
config const SAME = "SAME";  // default name ID?
config const DIFF = "DIFF"; // default name ID?

// Use module Fs to isolate domains during coforall looping.
// these domains are only modified with a Gate and Cabinet class.
module Fs {
  // using MasterDom during a "first pass" to find all same size files as (a,b).
  var MasterDom = {("", "")};  // contains same size files as (a,b).
  var same = {("", "")};  // identical files
  var diff = {("", "")};  // sorted files flagged as same size but are not identical
  var sizeZero = {("", "")}; // sort files that are < 8 bytes
}

// add a per-function try-catch catcher.
proc runCatch(function : string, arg1 : string, arg2 : string) {
  if V then writeln("Caught another error, from " + function + " while "+
  "processing \n" + arg1 +" and "+ arg2);
}

class Gate {
  // class Gate is an explicit way to use sync variables in parallel nested loops.
  // Gate is intitialized with Gate.initGate()
  var x$: sync bool;
  var busy : atomic int;
  // Note:  this init does note follow default initializer spec by Chapel
  proc initGate() {
    x$.writeXF(true);
    busy.write(1);
  }
  // lock will wait after atomic busy is 2.
  // this seems redundant, however this far this has been
  // the easiest to understand sync solution for this script
  proc lock() {
    do {
      x$;
      if debug then writeln("Gate is locked");
      } while busy.read() != 1;
      busy.write(2);
  }
  // open / reset lock:
  proc openup() {
    busy.write(1);
    x$.writeXF(true);
    if debug then writeln("Gate is open");
  }
}
/*
** THIS IS DEFAULT **
use DomainAdd() as the function that will be preformed in parallel.
it appears this system-
coforall loop --> for loop -- for loop --> conditions-  will fail if kept
in the same function.
*/
proc DomainAdd(folder, GateType) {
  GateType.lock();
  for a in findfiles(folder, recursive=false) {
    for b in findfiles(folder, recursive=false) {
      if exists(a) && exists(b) && a != b {
        if isFile(a) && isFile(b) {
          if getFileSize(a) == getFileSize(b) {
            if debug then writeln(a+" and "+b+" adding to MasterDom");
            Fs.MasterDom += (a,b);
            }
            if getFileSize(a) < 8 && getFileSize(b) < 8 {
              if debug then writeln(a+" and "+b+" adding to sizeZero Domain");
              Fs.sizeZero += (a,b);
            }
        }
      }
    }
  }
  GateType.openup();
}
/*
  parallel method to run DomainAdd() for every folder.
  because of this, parallelism will vary based on file structure
*/
proc ParallelGenerateDom() {
  var ParaDomGate = new borrowed Gate;
  ParaDomGate.initGate();
  coforall folder in walkdirs(dir) {
    DomainAdd(folder,ParaDomGate);
  }
}
/*
** THIS IS DEFAULT **
  ReadWriteManager evaluates same size files in the MasterDom
  at char level- see use of
  uint --> readln() method
  vs string --> readline method
*/
proc ReadWriteManager(a,b, GateType) {
  GateType.lock();
  try {
      var lineA : string;
      var lineB : string;
      var tmp1 = openreader(a);
      var tmp2 = openreader(b);
      tmp1.readln(lineA);
      tmp2.readln(lineB);
      if lineA != lineB {
        Fs.diff += (a,b);
        } else {
          Fs.same += (a,b);
      }
      tmp1.close();
      tmp2.close();
      } catch {
        runCatch("ReadWriteManager readln", a,b);
      }
    GateType.openup();
}

// parallel method to run ReadWriteManager()
proc parallelFullCheck() {
  var ParaFullGate = new borrowed Gate;
  ParaFullGate.initGate();
  coforall (a,b) in Fs.MasterDom {
    ReadWriteManager(a,b, ParaFullGate);
  }
}
/*
// end of Parallel functions //

** THIS IS --SP FLAG **

relies on findfiles(dir, recursive-true)
recursive findfiles() is not a great solution- use --T to see
how badly it fares
*/
proc serialGenerateDom() {
  var FindFilesTime = new Timer;
  if V then writeln("staring to populate Fs.MasterDom with findfiles(dir, recursive=true) \n" +
  " will print time elapsed for this operation, please wait...");
  if T then FindFilesTime.start();
  var files = findfiles(dir, recursive=true);
  if T then FindFilesTime.stop();
  if V then writeln("findfiles(dir, recursive=true) completed in " + FindFilesTime.elapsed());
  for a in files{
    for b in files {
      if exists(a) && exists(b) && a != b {
        if isFile(a) && isFile(b) {
          if getFileSize(a) == getFileSize(b) {
            if debug then writeln(a+" and "+b+" adding to MasterDom");
            Fs.MasterDom += (a,b);
            }
            if getFileSize(a) < 8 && getFileSize(b) < 8 {
              if debug then writeln(a+" and "+b+" adding to sizeZero Domain");
              Fs.sizeZero += (a,b);
            }
        }
      }
    }
  }
}
/*

** THIS IS --SE FLAG **

// Serial for-loop version of FullCheck
*/
proc serialFullCheck() {
  for (a,b) in Fs.MasterDom {
    try {
        var lineA : string;
        var lineB : string;
        var tmp1 = openreader(a);
        var tmp2 = openreader(b);
        tmp1.readln(lineA);
        tmp2.readln(lineB);
        if lineA != lineB {
          Fs.diff += (a,b);
          } else {
            Fs.same += (a,b);
        }
        tmp1.close();
        tmp2.close();
        } catch {
          runCatch("serialFullCheck() ", a,b);
        }
  }
}

// find options used for --V and NameScheme()
proc FindOps() : string {
  var opt = "";
  if SP then opt+=" --SP ";
  if SE then opt+=" --SE ";
  return opt;
}
// configure a naming scheme
proc NameScheme(name : string) : string {
  var RunName : string;
  if SP != true && SE != true {
    RunName = "Parallel";
  } else {
    RunName = "Serial";
  }
  return "FileCheck-"+name+FindOps()+ext;
}

// generic write function for any domain
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
  WriteAll("LessThan_8_Byte", Fs.sizeZero);
}

// switch for simpler RunStyle()
proc DomSwitch() {
if SP {
  if V then writeln("doing SerialGenerateDom()");
  serialGenerateDom();
  } else {
    if V then writeln("doing ParallelGenerateDom()");
    ParallelGenerateDom();
  }
}

// verbose run:
proc RunStyle() {
  var SerialTime = new Timer;
  var Dom1Time = new Timer;
  if V then writeln("starting FindFiles with "+ FindOps() +" options");
  if SE {
  SerialTime.start();
  if V then writeln("started timer!");
  if T then Dom1Time.start();
  DomSwitch();
  if T then Dom1Time.stop();
    if V {
      if T {
        writeln("MasterDom generated in "+ Dom1Time.elapsed());
      }
    }
    if V then writeln("entering FullCheck()");
    var serialFullCheckSpeed = new Timer;
    if T then serialFullCheckSpeed.start();
    serialFullCheck();
    if T then serialFullCheckSpeed.stop();
    if T {
      if V {
        writeln("Completed FullCheck() "+ FindOps() +" in "+serialFullCheckSpeed.elapsed()+
    " Beginning WriteFiles");
        }
      }
    if R then serialWrite();
    if T then SerialTime.stop();
    if T {
      if V {
        writeln("FileCheck completed in " +
    SerialTime.elapsed());
      }
    }
  }
  var Dom2Time = new Timer;
  var ParaTime = new Timer;
  if SE != true {
    if T then ParaTime.start();
    if V then writeln("started timer!");
    Dom2Time.start();
  DomSwitch();
  Dom2Time.stop();
    if T {
      if V {
        writeln("MasterDom generated in "+ Dom2Time.elapsed());
      }
    }
    var parallelFullCheckSpeed = new Timer;
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
      writeln("FileCheck with "+ FindOps() +" completed in " +
  ParaTime.elapsed());
      }
    }
  }
}
// call everything in a mildly more organized way:
RunStyle();
