/**********************************
* Configs and defaults:  --dir="." --R=true --Verb=false
* WIP by Jess Sullivan
* Usage: chpl FileCheck.chpl && ./FileCheck # to run this file
**********************************/
use FileSystem;
use Time;
var SpeedTestP: Timer;
//
config const dir = ".";
config const R : bool=true;
config const Verb : bool=false;
config const SameFileOutput = "SameFileOutputParallel2.txt";
config const DiffFileOutput = "DiffFileOutputParallel2.txt";
// some vars are easier to use in the global space, at the momment
var Caught, Toes, Elbows = 0;
// Using atomic integers to count down and break coforall loops.
var atomicElbow : atomic int; // Used as a counter.
var atomicToe : atomic int; // This is also a counter.
// catch small errors- walkdirs() is not very smart :(
proc runCatch(s : string) {
  Caught += 1;
  if Verb then writeln("Caught "+ Caught +" error(s), 1 new one from ", s);
}
// SizeCheck() is the initial pass, and once all dirs have been found, will begin
// parallel processing.  This initial walkdirs() appears to be the bottle neck.
//
// do to paraRun() coforall, these vars should not be in FullCheck().
var sameSizeFiles = {("", "")};
var feet = for i in sameSizeFiles do Toes + 1;
atomicToe.add(feet);
if Verb then writeln("Preforming SizeCheck in all dirs, this is a parallel operation");
//  Do an initial size comaprison
proc SizeCheck(folder) {
  atomicElbow.sub(1); // at zero, break
  for file1 in findfiles(folder, recursive=R) {
    for file2 in findfiles(folder, recursive=R) {
      if (getFileSize(file1) == getFileSize(file2)) && (file1 != file2) {
        sameSizeFiles += (file1, file2);
        if atomicToe.read() == 0 then break;
      }
    }
  }
}
// do to paraRun() coforall, these vars should not be in FullCheck().
var same : domain((string,string));
var diff : domain((string,string));
var lineA : string;
var lineB : string;
var Bows = for i in sameSizeFiles do Elbows + 1;
atomicElbow.add(Bows);
//
proc FullCheck(a,b) {
  atomicElbow.sub(1); // at zero, break
  try {
    var tmpRead1 = openreader(a);
    var tmpRead2 = openreader(b);
    tmpRead1.readline(lineA);
    tmpRead2.readline(lineB);
    do {
      if (lineA == lineB) {
        same += (a,b);
      } else {
        diff += (a,b);
      }
      } while atomicElbow.read() > 0;
      } catch {
        runCatch("FullCheck");
      }
      // be careful of letting more than one thread grabbing a non-existant file
      if Verb then writeln("same: ", a, ", ", b);
    }
    // write only need be called once, after all tests are run.
    // same and diff should be available globally.
    proc WriteFiles() {
      var FlagFile = open(SameFileOutput, iomode.cw);
      var SP_File = open(DiffFileOutput, iomode.cw);
      var ChannelF = FlagFile.writer();
      ChannelF.write(same);
      ChannelF.close();
      FlagFile.close();
      var ChannelT = SP_File.writer();
      ChannelT.write(diff);
      ChannelT.close();
      SP_File.close();
    }
    proc paraRun() {
      writeln("starting timer in FileCheckParallel");
      SpeedTestP.start();
      if Verb then writeln("Preforming walkdirs, this is a serial operation");
      var listdirs = walkdirs(dir);
      if Verb then writeln("doing SizeCheck() in parallel");
      coforall folder in listdirs {
        SizeCheck(folder);
      }
      if Verb then writeln("Completed SizeCheck()" +
      " entering FullCheck() in parallel");
      coforall (a,b) in sameSizeFiles {
        FullCheck(a,b);
      }
      if Verb then writeln("Completed FullCheck()" +
      " Beginning WriteFiles()");
      WriteFiles();
      SpeedTestP.stop();
      writeln("FileCheckParallel completed in " +
      SpeedTestP.elapsed());
    }
    //  call the above setup.
    paraRun();
