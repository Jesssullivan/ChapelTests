/**********************************
* Evaluate a Chapel (or any) script by time
* WIP by Jess Sullivan
* Usage: First compile YourScript.chpl to a binary
* chpl TimeChapel.chpl
* ./TimeChapel --F=["yourScript --Args"]
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
var runner1 = spawnshell([go]);
var runnerOpt = spawnshell([Opt]);

module X {
  var avg2 : real(64);
  var avg1 : real(64);
}
writeln("Starting "+F+" for "+L+" loops");
try {
  var firstRun = new Timer;
  for run in 1..#L {
    firstRun.start();
    runner1.wait();
    runner1.close();
    firstRun.stop();
    var total1 = firstRun.elapsed();
    X.avg1 = total1 / L;
    writeln("the average time spent was " + X.avg1);
  }
} catch {
  writeln("");
}
writeln("finished first set of loops.");

if opt {
  try {
  var secondRun = new Timer;
  writeln("starting arg loop");
  for run in 1..#L {
  secondRun.start();
  runnerOpt.wait();
  runnerOpt.close();
  secondRun.stop();
  var total2 = secondRun.elapsed();
  X.avg2 = total2 / L;
  writeln("the average time spent was " + X.avg2);
  }
  } catch {
    writeln("");
  }
}

writeln("complete!!! \n  if --R=true, will open report!");

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
