/**********************************
Configs:  --dir"." --R=true --Verb=true
--HumanFile="HumanFile.txt" --SpSepFile="SpSepFile.txt"
*   WIP by Jess Sullivan
*   chpl FileCheck.chpl && ./FileCheck # to run this file
**********************************/
use FileSystem;

config const dir = ".";
config const R : bool=true;
config const Verb : bool=false;
config const HumanFile = "Flagged_Dupes.txt";
config const  SpSepFile = "SpSepFile.txt";

var Caught = 0;
var DupeFound, SizeChecked = false;
var FlaggedList, SepFile, initlist, RefinedList = "";
var tmp1, tmp2 : uint(64);  // used for checking at char level in FullCheck()
var Tasks : atomic int;
var n$ : sync bool;
proc runCatch() {
  Caught += 1;
    writeln("Caught "+ Caught +" errors ");
  }
var sameSizeFiles : domain((string,string));
proc SizeCheck() {
  var listFiles = findfiles(dir, recursive=R);
  if Verb then writeln("entering SizeCheck");
  SizeChecked = true;
  try {
    for file1 in listFiles {
      try {
        for file2 in listFiles {
          if (getFileSize(file1) == getFileSize(file2)) &&
          isFile(file1) && isFile(file2) && (file1 != file2) {
            sameSizeFiles += (file1, file2);
            initlist += ("Size dupe match found for: " + file1 + " , " + file2 + "\r\n");
          }
        }
        } catch {
          runCatch();
        }
      }
      } catch {
        runCatch();
      }
    }

    // TODO : evaluate repeats, ala (a,b) and (b,a)
    proc FullCheck() {
      if Verb then writeln("entering FullCheck");
      try {
        for (a,b) in sameSizeFiles {
          if isFile(a) && isFile(b) {
            var o2 = open(b, iomode.r);
            var o1 = open(a, iomode.r);
            if Verb then writeln("opened "+ a +" and " + b);
            var tmpRead1 = o1.reader(kind=ionative);
            var tmpRead2 = o2.reader(kind=ionative);
            tmpRead1.readln(tmp1);
            tmpRead2.readln(tmp2);
            if tmp1 == tmp2 {
              if Verb {
                 writeln(a + " AND "+b+" Are equal at line / char resolution \n");
                 FlaggedList += ("SAME: FullCheck evals " + a + " is different then " + b + "\r\n");
               }
            } else {
                sameSizeFiles -= (a,b);
                FlaggedList += ("different: FullCheck evals " + a + " is different then " + b + "\r\n");
                if Verb then writeln(a + " AND "+b+"Are not equal, are individual files!! \n");
              }
              tmpRead1.close();
              o1.close();
              tmpRead2.close();
              o2.close();
          }
        }
      } catch {
        runCatch();
      }
    }
      proc WriteFiles() {
        if Verb then writeln("entering Write files, writing to " + HumanFile +" and "+ SpSepFile);
        if SizeChecked {
          for (a,b) in sameSizeFiles {
            SepFile += (a+" "+b+" \n");
          }
          {
            var CompFLag = compile(FlaggedList);
            var FlagFile = open(HumanFile, iomode.cw);
            var ChannelF = FlagFile.writer();
            ChannelF.write(CompFLag);
            ChannelF.close();
            FlagFile.close();
          }
          {
            var CompSep = compile(SepFile);
            var SP_File = open(SpSepFile, iomode.cw);
            var ChannelT = SP_File.writer();
            ChannelT.write(CompSep);
            ChannelT.close();
            SP_File.close();
          }
          if Verb then writeln("all files written and channels closed.");
        }
      }
      proc ShowHuman() {
        if SizeChecked {
          writeln("\n open a txt file to see dupes! open @  " + HumanFile);
          writeln("  -  Completed with " + Caught + " Errors - ");
        }
      }
      // TODO : make some kind of control flow
      SizeCheck();
      FullCheck();
      WriteFiles();
      ShowHuman();
