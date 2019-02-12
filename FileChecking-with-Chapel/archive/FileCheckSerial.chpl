/**********************************
* Configs and defaults:  --dir="." --R=true --Verb=false
*   --HumanFile="Flagged_Dupes.txt" --SpSepFile="SpSepFile.txt"
* WIP by Jess Sullivan
* Usage: chpl FileCheck.chpl && ./FileCheck # to run this file
**********************************/
use FileSystem;
use Time;
var SpeedTestS: Timer;

config const dir = ".";
config const R : bool=true;
config const Verb : bool=false;
config const SameFileOutput = "SameFileOutputSerial.txt";
config const DiffFileOutput = "DiffFileOutputSerial.txt";
var Caught = 0;
proc runCatch(s : string) {
  Caught += 1;
  writeln("Caught "+ Caught +" error from ", s);
}
var sameSizeFiles = {("", "")};
proc SizeCheck() {
  var listFiles = findfiles(dir, recursive=R);
  if Verb then writeln("entering SizeCheck");
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
  }
  var same : domain((string,string));
  var diff : domain((string,string));
  //  check at char level
  proc FullCheck(a,b) {
    var lineA : string;
    var lineB : string;
    if Verb then writeln("entering FullCheck");
    if isFile(a) && isFile(b) { // GTS: why needed?
      try {
      var chanA = openreader(a);
      var chanB = openreader(b);
      if Verb then writeln("Checking ", a, ", ", b, " line by line.");
      do {
        var gotA = chanA.readline(lineA);
        var gotB = chanB.readline(lineB);
        if gotA {
          if gotB {
            if (lineA == lineB) {
              if Verb then write(".");
              } else {		// lines differ
                if Verb then writeln("Diff (", lineA.strip(), ") != (", lineB.strip(), ")");
                diff += (a, b);
              }
              } else {		// gotA but not gotB
                if Verb then writeln("Diff: file ", a, " longer than file ", b);
                diff += (a, b);
              }
              } else {		// not gotA
                if gotB {		// not gotA but gotB
                  if Verb then writeln("Diff: file ", a, " shorter than file ", b);
                  diff += (a, b);
                }
              }
              } while (gotA && gotB);
              if Verb then writeln("same: ", a, ", ", b);
              same += (a, b);
            } catch {
              runCatch("FullCheck");
            }
          }
        }

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
      proc SerialRun() {
        writeln("starting timer in FileCheckSeries");
        SpeedTestS.start();
        var listdirs = walkdirs(dir);
        if Verb then writeln("doing SizeCheck() - Serial");
        SizeCheck();
        if Verb then writeln("Completed SizeCheck()" +
        " entering FullCheck() - Serial");
        for (a,b) in sameSizeFiles {
        FullCheck(a,b);
      }
        if Verb then writeln("Completed FullCheck()" +
        " Beginning WriteFiles()");
        WriteFiles();
        SpeedTestS.stop();
        writeln("FileCheckPSeries completed in " +
        SpeedTestS.elapsed());
      }

      SerialRun();
