use FileSystem;
use IO;
use Time;

config const V : bool=true;  // verbose logging

module charMatches {
  var dates = {("")};
}

var sync1$ : sync bool=true;

proc charCheck(aFile, ref choice, sep, sepRange) {
    try {
        var line : string;
        var tmp = openreader(aFile);
        while(tmp.readline(line)) {
            if line.find(sep) > 0 {
                choice += line.split(sep)[sepRange];
                if V then writeln('adding '+ sep + ' ' + line.split(sep)[sepRange]);
            }
        }
    tmp.close();
    } catch {
      if V then writeln("caught err");
    }
}

coforall folder in walkdirs('check/') {
    for file in findfiles(folder) {
        charCheck(file, charMatches.dates, '$D ', 1..8);
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

// WriteAll("dates.csv", charMatches.dates);
