/**********************************
  * !!! Serial version !!!
  * Configs and defaults:  --dir="." --R=true --Verb=false
  *   --HumanFile="Flagged_Dupes.txt" --SpSepFile="SpSepFile.txt"
  * WIP by Jess Sullivan
  * Usage: chpl FileCheck.chpl && ./FileCheck # to run this file
**********************************/

use FileSystem;
use Time;

config const dir = ".";
config const R : bool=true;
config const Verb : bool=false;
config const HumanFile = "Flagged_Dupes.txt";
config const SpSepFile = "SpSepFile.txt";

var Caught = 0;
proc runCatch(s : string) {
  Caught += 1;
  writeln("Caught "+ Caught +" error from ", s);
}
writeln("starting timer in FileCheck, Serial");
var SpeedTestS: Timer;
SpeedTestS.start();

proc SizeCheck() : domain((string, string)) {
  var sameSizeFiles = {("", "")};
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
  return sameSizeFiles;
}

// TODO : evaluate repeats, ala (a,b) and (b,a)
// return ("list of pairs of same files", "list of pairs of diff files")
proc FullCheck(sameSizeFiles) : ( domain((string, string))  ,  domain((string, string)) ) {
  var same = {("", "")};
  var diff = {("", "")};
  var lineA : string;
  var lineB : string;
  if Verb then writeln("entering FullCheck");
  try {
    label filePairLoop for (a, b) in sameSizeFiles {
      if isFile(a) && isFile(b) { // GTS: why needed?
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
		continue filePairLoop;
	      }
	    } else {		// gotA but not gotB
	      if Verb then writeln("Diff: file ", a, " longer than file ", b);
	      diff += (a, b);
	      continue filePairLoop;
	    }
	  } else {		// not gotA
	    if gotB {		// not gotA but gotB
	      if Verb then writeln("Diff: file ", a, " shorter than file ", b);
	      diff += (a, b);
	      continue filePairLoop;
	    }
	  }
	} while (gotA && gotB);
	if Verb then writeln("same: ", a, ", ", b);
	same += (a, b);
      }
    } // for (a, b) in sameSizeFiles
  } catch {
    runCatch("FullCheck");
  }
  return (same, diff);
}

/*
proc WriteFiles() {
  if Verb then writeln("entering Write files, writing to " + HumanFile +" and "+ SpSepFile);
  if SizeChecked {
    for (a,b) in sameSizeFiles {
      SepFile += (a+" "+b+" \n");
    }
    var CompFLag = compile(FlaggedList);
    var FlagFile = open(HumanFile, iomode.cw);
    var ChannelF = FlagFile.writer();
    ChannelF.write(CompFLag);
    ChannelF.close();
    FlagFile.close();
    var CompSep = compile(SepFile);
    var SP_File = open(SpSepFile, iomode.cw);
    var ChannelT = SP_File.writer();
    ChannelT.write(CompSep);
    ChannelT.close();
    SP_File.close();
    if Verb then writeln("all files written and channels closed.");
  }
}


proc ShowHuman() {
  if SizeChecked {
    writeln("\n open a txt file to see dupes! open @  " + HumanFile);
    writeln("  -  Completed with " + Caught + " Errors - ");
  }
}
*/

var sameSizeFiles = SizeCheck();
writeln("Files with the same size: ", sameSizeFiles);

var (sameFiles, diffFiles) = FullCheck(sameSizeFiles);
writeln("File line-by-line the same: ", sameFiles);
writeln("Files the same size but different: ", diffFiles);
SpeedTestS.stop();
writeln("FileCheck() completed in " +
SpeedTestS.elapsed());// WriteFiles();
// ShowHuman();
