/**********************************
* read check files at line level for duplicates.
* Use --S=true for Serial, defaults to parallel processing.
* WIP by Jess Sullivan
* Usage: chpl FileCheck.chpl && ./FileCheck # to run this file
**********************************/
use FileSystem;
use Time;
//use DateTime;
var SpeedTest: Timer;

config const S : bool=false;  // override parallel, use Serial looping?
config const dir = "."; // start here?
config const SAME = "SAME";
config const DIFF = "DIFF";
config const ext = ".txt";  // use alternative ext?

// add extra debug options
config const V : bool=false; // Vebose output of actions
config const debug : bool=false;  // add inside loop read out?

// Use module Fs to isolate domains during coforall looping.
// these domains are only modified via the GateKeeper() sync function.
module Fs {  // FileKeeper module, accessed as "keys" in GateKeeper()
  var sameSizeFiles = {("", "")};
  var same = {("", "")};
  var diff = {("", "")};
}
//    add a per-function try-catch counter.  Uses atomic due to thread possible
//    "thread collisions", don't want the error counter to also be wrong.
proc runCatch(function : string) {
  if V then writeln("Caught another error(s), from ", function);
}
 // keys() is a generic way to
 // maintain thread safety while a coforall tries to update one domain
 // with multiple threads / strings.

var keys : domain((string,string));
proc keeper(ref keys, (a,b), atom, s$) {
 do {
   s$;
 } while atom.read() < 1;
  s$.writeXF(true);
  atom.sub(1);
  keys += (a,b);
  s$.writeXF(true);
  atom.add(1);
}
// SizeCheck() is a generic function that can be run in Serial or Parrallel.
// it takes a folder and its files as an iterator
proc SizeCheck((a,b), used, atom, s$) {
      if debug then writeln("looping in", used);
      try {
      if (getFileSize(a) == getFileSize(b)) &&
      (a != b)  {
        keeper(Fs.sameSizeFiles, (a,b), atom, s$);
        }
      } catch {
        runCatch(used);
      }
    }
proc parallelSizeCheck() {
  var PSCtomic : atomic int;
  PSCtomic.add(1);
  var PSCsync$ : sync bool;
  PSCsync$.writeXF(true);
    coforall folder in walkdirs(dir) {
      for a in findfiles(folder) {
        for b in findfiles(folder) {
        SizeCheck((a,b), "parallelSizeCheck", PSCtomic, PSCsync$);
      }
    }
  }
}

proc serialSizeCheck() {
  var SSCtomic : atomic int;
  SSCtomic.add(1);
  var SSCsync$ : sync bool;
  SSCsync$.writeXF(true);
  for (a,b) in findfiles(dir) {
  SizeCheck((a,b), "serialSizeCheck", SSCtomic, SSCsync$);
  }
}
// add arbitrary (and different) types to use while reading files
//  var lineU : uint;
//  var lineI : uint;
var lineA : string;
var lineB : string;
// FullCheck() is a generic function that can be run in Serial or Parrallel.
// it takes files (a,b) from Fs.sameSizeFiles and evaluates each file line by line.
proc FullCheck((a,b), used, atom, s$) {
    if isFile(a) && isFile(b) && exists(a) && exists(b) {
          try {
    var tmpRead1 = openreader(a);
    var tmpRead2 = openreader(b);
    //  ????????????????????
    do {
      tmpRead1.readln(lineA);
      tmpRead2.readln(lineB);
      } while lineA == lineB;
      if lineA != lineB {
        keeper(Fs.diff, (a,b), atom, s$);
      } else {
      keeper(Fs.same, (a,b), atom, s$);
    }
    //  ????????????????????
    if debug then writeln(used + "wrote "+a+" and "+ b +"  to "+ Fs.diff);
      tmpRead1.close();
      tmpRead2.close();
      } catch {
        runCatch(used);
      }
    }
  }
proc parallelFullCheck() {
  var PFCtomic : atomic int;
  PFCtomic.add(1);
  var PFCsync$ : sync bool;
  PFCsync$.writeXF(true);
  coforall (a,b) in Fs.sameSizeFiles {
    FullCheck((a,b), "parallelFullCheck", PFCtomic, PFCsync$);
  }
}
proc serialFullCheck() {
  var SFCtomic : atomic int;
  SFCtomic.add(1);
  var SFCsync$ : sync bool;
  SFCsync$.writeXF(true);
  for (a,b) in Fs.sameSizeFiles {
    FullCheck((a,b), "serialSizeCheck", SFCtomic, SFCsync$);
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
// writers:  Aside from disk being vastly slower than...! and there is not a
// good reason, Why not have a parallel here too?
// gatekeeper is not needed, there are two seperate domains and two seperate files to write.
proc WriteAll(N : string, content) {
  var OFile = open(NameScheme(N), iomode.cw);
  var Ochann = OFile.writer();
  Ochann.write(content);
  Ochann.close();
  OFile.close();
}
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
  parallelSizeCheck();
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
//  call an above setup.
if S {
  SerialRun();
  } else {
      paraRun();
  }
