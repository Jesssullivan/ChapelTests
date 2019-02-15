/**********************************
DEPRECIATED
**********************************/
config const F = "FileCheck"; // script
config const A = " --S"; // optional args to try also
config const opt : bool=true; // use args?
config const R : bool=true; // compile a report?
config const N : bool=false;  // do not open nano by default
config const L : int=10; // loops, repeated for additional arg if listed

use Spawn;
use Time;
use FileSystem;

var go = "./"+F;
var Opt = go + " " + A;

module X {
  var avg2 : real(64);
  var avg1 : real(64);
  var total1 : real(64);
  var total2 : real(64);
}

var Ldone : int;
var DoDone : int;

if opt {
  DoDone = L*2;
  } else {
    DoDone = L;
  }
writeln("Starting "+F+" for "+L+" loops");
var t = new Timer;
for run in 1..L {
  writeln("run #"+run);
  try {
    t.start();
    spawnshell([go]);
    } catch {
      writeln("");
    }
    Ldone += 1;
    t.stop();
    X.total1 += t.elapsed();
    if Ldone == DoDone {
      break;
      } else {
        continue;
      }
    }
    X.avg1 = X.total1 / L;
    writeln("finished first set of loops.");
    writeln("the average time spent was " + X.avg1);

if opt {
  var Tt = new Timer;
  for run2 in 1..L {
    writeln("run2 #"+run2);
    try {
      Tt.start();
      spawnshell([Opt]);
      } catch {
        writeln("");
      }
      Ldone += 1;
      Tt.stop();
      X.total2 += Tt.elapsed();
      if Ldone == DoDone {
        break;
        }
      }
      X.avg2 = X.total2 / L;
      writeln("finished first set of loops.");
      writeln("the average time spent was " + X.avg2);
      writeln("complete!!! \n  if --R=true, will open report!");
    }
if Ldone == DoDone {
  if R {
    var avgs = {("")};
    avgs += ("the average time without args was " + X.avg1);
    if opt then avgs += ("the average time with args was " + X.avg2);
    var OFile = open("StressChapel_Results.txt", iomode.cw);
    var Ochann = OFile.writer();
    Ochann.write(avgs);
    Ochann.close();
    OFile.close();
    if N {
      var nano = spawnshell(["nano StressChapel_Results.txt"]);
      nano.wait();
      nano.close();
    }
  }
}
