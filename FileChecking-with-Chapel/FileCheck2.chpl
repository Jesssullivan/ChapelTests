/**********************************
* read check files at char level for duplicates.
* Use --S=true for Serial, defaults to parallel processing.
* WIP by Jess Sullivan
* Usage: chpl FileCheck.chpl && ./FileCheck # to run this file
**********************************/
use FileSystem;
use Time;

// logging options
config const V : bool=true; // Vebose output of actions?
config const R : bool=true; // compile report file?
config const SAME = "SAME";  // default name ID?
config const DIFF = "DIFF"; // default name ID?
module Fs {
  var MasterDom = {("", "")};  // contains same size files as (a,b).
  var same = {("", "")};  // identical files
  var diff = {("", "")};  // sorted files flagged as same size but are not identical
  var sizeZero = {("", "")}; // sort files that are < 8 bytes
}
var sync1$ : sync bool;
sync1$ = true;

proc ParallelRun(a,b) {
  if exists(a) && exists(b) && a != b {
    if isFile(a) && isFile(b) {
      if getFileSize(a) == getFileSize(b) {
        sync1$;
        Fs.MasterDom += (a,b);
        sync1$ = true;
        }
        if getFileSize(a) < 8 && getFileSize(b) < 8 {
          sync1$;
          Fs.sizeZero += (a,b);
          sync1$ = true;
      }
    }
  }
}
coforall folder in walkdirs(".") {
  for a in findfiles(folder, recursive=false) {
    for b in findfiles(folder, recursive=false) {
      ParallelRun(a,b);
    }
  }
}
var sync2$ : sync bool;
sync2$ = true;
coforall (a,b) in Fs.MasterDom {
  try {
      var lineA : string;
      var lineB : string;
      var tmp1 = openreader(a);
      var tmp2 = openreader(b);
      tmp1.readln(lineA);
      tmp2.readln(lineB);
      if lineA != lineB {
        sync2$;
        Fs.diff += (a,b);
        sync2$ = true;
        } else {
          sync2$;
          Fs.same += (a,b);
          sync2$ = true;
      }
      tmp1.close();
      tmp2.close();
      } catch {
        if V then writeln("catch");
      }
}
proc WriteAll(N : string, content) {
  var OFile = open(N, iomode.cw);
  var Ochann = OFile.writer();
  Ochann.write(content);
  Ochann.close();
  OFile.close();
}
WriteAll("SAME.txt", Fs.same);
WriteAll("DIFF.txt", Fs.diff);
WriteAll("LessThan_8_Byte", Fs.sizeZero);
