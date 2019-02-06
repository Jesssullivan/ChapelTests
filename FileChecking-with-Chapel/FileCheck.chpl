/**********************************
Configs: --dir"." --R=true --HumanFile="HumanFile.txt" --SpSepFile="SpSepFile.txt"
*   WIP by Jess Sullivan
*   chpl FileCheck.chpl && ./FileCheck # to run this file
**********************************/
use FileSystem;

config const dir = ".";
config const R : bool=true;
config const HumanFile = "Flagged_Dupes.txt";
config const  SpSepFile = "SpSepFile.txt";

var listFiles = findfiles(dir, recursive=R);
var NumFiles = 0;
var DupeFound, SizeChecked = false;
var FlaggedList = "";
var sameSizeFiles : domain((string,string));
var tmp1, tmp2 : uint(64);  // used for checking at char level in FullCheck()
var didFile = (".");

proc SizeCheck() {
  writeln("entering SizeCheck");
  SizeChecked = true;
  for file1 in listFiles {
    for file2 in listFiles {
      if (getFileSize(file1) == getFileSize(file2)) &&
      (file1 != file2) {
        DupeFound = true;
        sameSizeFiles += (file1,file2);
        FlaggedList += ("Size dupe match found for: " + file1 + " , " + file2 + "\r\n");
      }
    }
  }
}
proc FullCheck() {
  if DupeFound && SizeChecked {
    writeln("entering FullCheck");
    for i in (sameSizeFiles) do NumFiles += 1;
    for (a,b) in sameSizeFiles {
      if exists(a) && exists(b) && a!=didFile && b!=didFile {
        var o1 = open(a, iomode.r);
        var o2 = open(b, iomode.r);
        writeln("opened "+ a +" and " + b);
        var tmpRead1 = o1.reader(kind=ionative);
        var tmpRead2 = o2.reader(kind=ionative);
        tmpRead1.readln(tmp1);
        tmpRead2.readln(tmp2);
        if tmp1 == tmp2 {
          writeln("Are equal at line / char resolution \n");
          } else {
            // see cool results with /CheckCharLevel/a vf /CheckCharLevel/b
            writeln("Are not equal, are individual files!! \n");
          }
          tmpRead1.close();
          o1.close();
          tmpRead2.close();
          o2.close();
          didFile = (b);  // avoid duplicates
        }
      }
    }
  }
  proc WriteFiles() {
    writeln("entering Write files, writing to " + HumanFile +" and "+ SpSepFile);
    if DupeFound && SizeChecked {
      {
        var CompFLag = compile(FlaggedList);
        var FlagFile = open(HumanFile, iomode.cw);
        var ChannelF = FlagFile.writer();
        ChannelF.write(CompFLag);
        ChannelF.close();
        FlagFile.close();
      }
      {
        var SP_File = open(SpSepFile, iomode.cw);
        var ChannelT = SP_File.writer();
        ChannelT.write(SpSepFile);
        ChannelT.close();
        SP_File.close();
      }
      writeln("all files written and channels closed.");
    }
  }
  proc ShowHuman() {
    if DupeFound && SizeChecked {
      writeln("\n open a txt file to see dupes! open @  " + HumanFile);
      writeln("  -  Complete - ");
    }
  }
  // TODO : make some kind of control flow
  SizeCheck();
  FullCheck();
  WriteFiles();
  ShowHuman();
