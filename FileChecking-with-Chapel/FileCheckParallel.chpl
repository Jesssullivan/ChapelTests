/**********************************
* Configs and defaults:  --dir="." --R=true --Verb=false
* WIP by Jess Sullivan
* Usage: chpl FileCheck.chpl && ./FileCheck # to run this file
**********************************/
use FileSystem;
use Time;
config const dir = ".";
config const R : bool=true;
config const Verb : bool=false;
config const SameFileOutput = "SameFileOutput.txt";
config const DiffFileOutput = "DiffFileOutput.txt";
// some vars are easier to use in the global space, at the momment
var sameSizeFiles = {("", "")};
var Caught, counted = 0;
var atomicElbow : atomic int; // Used as a counter.
var SpeedTestP: Timer;  // timed during run in paraRun()
// catch small errors- walkdirs is not very smart
proc runCatch(s : string) {
  Caught += 1;
  if Verb then writeln("Caught "+ Caught +" error(s), 1 new one from ", s);
}
//  folder will be used to speed up SizeCheck()
//  for each dir found in listdirs at run, start a new thread doing that folder only
proc SizeCheck(folder) : int {
  var listFiles = findfiles(folder);
  try {
    for file1 in listFiles {
      for file2 in listFiles {
        if (getFileSize(file1) == getFileSize(file2)) &&
        isFile(file1) && isFile(file2) && (file1 != file2) {
          sameSizeFiles += (file1, file2);
        }
      }
    }
    } catch {
      runCatch("SizeCheck");
    }
    return 1;
  }
  // global vars seem to make coforall / parallel simpler- unclear what
  // other way to do this, with minimal hassle
  var BigNum = for i in sameSizeFiles do counted + 1;
  atomicElbow.add(BigNum);
  var same : domain((string,string));
  var diff : domain((string,string));
  //  check at char level
  proc FullCheck(a,b) : int {
    var lineA : string;
    var lineB : string;
    atomicElbow.sub(1); // at zero, break
    try {
      var chanA = openreader(a);
      var chanB = openreader(b);
      do {
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
              if atomicElbow.read() == 0 then break;
              } while (gotA && gotB);
              if Verb then writeln("same: ", a, ", ", b);
              same += (a,b);
              } catch {
                runCatch("FullCheck");
              }
              return 1;
            }
            // write only need be called once, after all tests are run.
            // same and diff should be available globally.
            proc WriteFiles() : int {
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
              return 1;
            }
            proc paraRun() {
              writeln("starting timer in FileCheckParallel");
              SpeedTestP.start();
              writeln("walking directories, please wait..." +
              " This is a series / single thread operation!");
              // chapel does not offer a simple method for reading directories
              // in a proper parallel way.
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
