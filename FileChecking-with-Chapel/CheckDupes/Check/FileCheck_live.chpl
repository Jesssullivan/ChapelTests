/**********************************
* Parallel dupe checking in Chapel.
* WIP by Jess Sullivan
* Usage: chpl FileCheck_live.chpl && ./FileCheck_live
**********************************/
use FileSystem;
use Time;

// add "if V then writeln(...)" to debug
// currently logs "catch"
config const V : bool=false;

// FileCheck2 File system (Fs)
module Fs {
  var sizeEqual = '';
  var sizeZero = {("")}; // sort files that are < 8 bytes
  var same = ('','');
  var diff = {("", "")};
}

// declare some sync$ vars
var sync1$ : sync bool=true;

// char (a,b) match?
proc CharMatch(a,b) {
  if exists(a) && exists(b) && a != b {
    if isFile(a) && isFile(b) {
      if getFileSize(a) == getFileSize(b) {
  // recyclable vars (a,b)
  try {
    var lineA : string;
    var lineB : string;
    var tmp1 = openreader(a);
    var tmp2 = openreader(b);
    tmp1.readln(lineA);
    tmp2.readln(lineB);
      if lineA != lineB {
      sync1$;
      Fs.diff += (a,b);
      sync1$ = true;
      tmp1.close();
      tmp2.close();
    } else {
      sync1$;
    Fs.same += (a,b);
    sync1$ = true;
    }
    } catch {
      if V then writeln("catch");
        }
      }
    }
  }
}

coforall folder in walkdirs(".") {
  for a in findfiles(folder, recursive=false) {
    for b in findfiles(folder, recursive=false) {
      CharMatch(a,b);
    }
  }
}

// write information to files
proc WriteAll(N : string, content) {
  var OFile = open(N, iomode.cw);
  var Ochann = OFile.writer();
  Ochann.write(content);
  Ochann.close();
  OFile.close();
}

WriteAll("Evaluated_Same.csv", Fs.same);
WriteAll("Evaluated_Diff.csv", Fs.diff);
