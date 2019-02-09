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
config const SameFileOutput = "SameFileOutputParallel.txt";
config const DiffFileOutput = "DiffFileOutputParallel.txt";
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
  for file1 in findfiles(folder) {
    for file2 in findfiles(folder) {
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
var Bows = for i in sameSizeFiles do Elbows + 1;
atomicElbow.add(Bows);
// now check suspects check at char level
proc FullCheck(a,b) {
  var lineA : string;
  var lineB : string;
  atomicElbow.sub(1); // at zero, break
  try {
    var chanA = openreader(a);
    var chanB = openreader(b);
    do {
      if atomicElbow.read() == 0 then break;
      var gotA = chanA.readline(lineA);
      var gotB = chanB.readline(lineB);
      if gotA {
        if gotB {
          if (lineA == lineB) {
            } else {		// lines differ
              //    if Verb then writeln("Diff (", lineA.strip(), ") != (", lineB.strip(), ")");
              diff += (a,b);
            }
            } else {		// gotA but not gotB
              //   if Verb then writeln("Diff: file ", a, " longer than file ", b);
              diff += (a,b);
            }
            } else {		// not gotA
              if gotB {		// not gotA but gotB
                // if Verb then writeln("Diff: file ", a, " shorter than file ", b);
                diff += (a,b);
              }
            }
            // be careful of letting more than one thread grabbing a non-existant file
            } while (gotA && gotB);
            if Verb then writeln("same: ", a, ", ", b);
            same += (a,b);
            } catch {
              runCatch("FullCheck");
            }
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
