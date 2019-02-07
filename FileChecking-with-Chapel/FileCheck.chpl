/**********************************
 * Configs and defaults:  --dir="." --R=true --Verb=false
 *   --HumanFile="Flagged_Dupes.txt" --SpSepFile="SpSepFile.txt"
 * WIP by Jess Sullivan
 * Usage: chpl FileCheck.chpl && ./FileCheck # to run this file
**********************************/

use FileSystem;

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
  if Verb then writeln("entering FullCheck");
  try {
    label filePairLoop for (a, b) in sameSizeFiles {
      if isFile(a) && isFile(b) { // GTS: why needed?
	if Verb then writeln("opened "+ a +" and " + b);
	for line1 in open(a, iomode.r).lines() {
	  if Verb then writeln("line1: "+ line1);
	  for line2 in open(b, iomode.r).lines() {
	    if Verb then writeln("line2: "+ line2);
	    if (line1 == line2) {
	      if Verb then writeln("equal so far");
	    } else {		// files differ
	      if Verb then writeln("differ");
	      diff += (a, b);
	      // "(%s, %s)".format(a, b);
	      if Verb then writeln("Diff: ", a, ", ", b);
	      continue filePairLoop;
	    }
	  }
	}
	same += (a, b);
	// "(%s, %s)".format(a, b);
      }
    }
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

// WriteFiles();
// ShowHuman();
