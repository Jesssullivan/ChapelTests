/**********************************
* read check files at line level for duplicates.
* Use --S=true for Serial, defaults to parallel processing.
* WIP by Jess Sullivan
* Usage: chpl FileCheck.chpl && ./FileCheck # to run this file
**********************************/
use FileSystem;
use Time;
var SpeedTestP: Timer;
//
config const dir = ".";  // starting dir
config const R : bool=true; // enable recursive?
config const V : bool=false; // verbose output?
config const S : bool=false;  // override parallel, use Serial looping?
config const TXT : bool=true;  // use CSV out?
config const SAME = "SameDupeOut";
config const DIFF = "DiffDupeOut";
// some vars are easier to use in the global space, at the momment
var Caught, Toes, Elbows, Size = 0;
// Using atomic integers to count down and break coforall loops.
var atomicElbow : atomic int; // Used as a counter.
var atomicSizeFile : atomic int; // This is also a counter.
// catch small errors- walkdirs() is not very smart :(
proc runCatch(s : string) {
  Caught += 1;
  if V then writeln("Caught "+ Caught +" error(s), 1 new one from ", s);
}
// SizeCheck() is the initial pass, and once all dirs have been found, will begin
// parallel processing.  This initial walkdirs() appears to be the bottle neck.
if V then writeln("Preforming SizeCheck in all dirs, this is a parallel operation");
//  Do an initial size comaprison
var listdirs = walkdirs(dir);
// isolate sameSizeFiles due to different coforall behavior from for loop
module FileKeeper {
  var sameSizeFiles = {("", "")};
}
proc SizeCheck() {
  if S {
    var listfiles = findfiles(dir, recursive=R);
    for file1 in listfiles {
      for file2 in listfiles {
        if (getFileSize(file1) == getFileSize(file2)) && (file1 != file2) {
          FileKeeper.sameSizeFiles += (file1, file2);
        }
      }
    }
    } else {
      var listdirs = walkdirs(dir);
      coforall folder in listdirs {
        proc Check() {
          for file1 in findfiles(folder, recursive=R) {
            for file2 in findfiles(folder, recursive=R) {
              if (getFileSize(file1) == getFileSize(file2)) && (file1 != file2) {
                FileKeeper.sameSizeFiles += (file1, file2);  // under module
              }
            }
          }
        }
        Check();  // isolated as a function
      }
    }
  }
    // do to paraRun() coforall, these vars should not be in FullCheck().
    var same : domain((string,string));
    var diff : domain((string,string));
    var lineA : string;
    var lineB : string;
    proc FullCheck(a,b) {
      try {
        var o2 = open(b, iomode.r);
        var o1 = open(a, iomode.r);
        var tmpRead1 = o1.reader(kind=ionative);
        var tmpRead2 = o2.reader(kind=ionative);
        tmpRead1.readline(lineA);
        tmpRead2.readline(lineB);
        if (lineA == lineB) {
          same += (a,b);
          } else {
            diff += (a,b);
          }
          tmpRead1.close();
          o1.close();
          tmpRead2.close();
          o2.close();
          //
          } catch {
            runCatch("FullCheck");
          }
          if V then writeln("same: ", a, ", ", b);
        }
        // configure a naming scheme
        var RunName : string;
        var ext : string;
        var name : string;
        proc NameScheme(name) {
          if S {
            RunName = "Serial";
            } else {
              RunName = "Parallel";
            }
            if TXT {
              ext = ".txt";
              } else {
                ext = ".csv";
              }
              return name+RunName+ext;
            }
            proc WriteFiles() {
              var FlagFile = open(NameScheme(SAME), iomode.cw);
              var SP_File = open(NameScheme(DIFF), iomode.cw);
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
              writeln("starting timer in Parallel");
              SpeedTestP.start();
              if V then writeln("Preforming walkdirs, this is a serial operation");
              var listdirs = walkdirs(dir);
              if V then writeln("doing SizeCheck() in parallel");
              SizeCheck();
              if V then writeln("Completed SizeCheck()" +
              " entering FullCheck() in parallel");
              coforall (a,b) in FileKeeper.sameSizeFiles {
                FullCheck(a,b);
              }
              if V then writeln("Completed FullCheck()" +
              " Beginning WriteFiles()");
              WriteFiles();
              SpeedTestP.stop();
              writeln("Parallel FileCheck completed in " +
              SpeedTestP.elapsed());
            }
            proc SerialRun() {
              writeln("starting timer in Serial");
              SpeedTestP.start();
              if V then writeln("Preforming walkdirs");
              if V then writeln("entering SizeCheck()");
              SizeCheck();
              if V then writeln("Completed SizeCheck()" +
              " entering FullCheck()");
              for (a,b) in FileKeeper.sameSizeFiles {
                FullCheck(a,b);
              }
              if V then writeln("Completed FullCheck()" +
              " Beginning WriteFiles()");
              WriteFiles();
              SpeedTestP.stop();
              writeln("Serial FileCheck completed in " +
              SpeedTestP.elapsed());
            }
            //  call an above setup.
            if S != true {
                paraRun();
              } else {
                SerialRun();
              }
