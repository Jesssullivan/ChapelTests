use FileSystem;
use Spawn;
config const dir = ".";
config const R : bool=true;
config const FileF = "Flagged_Dupes.txt";
config const  FileT = "Flagged_Dupes-CSV-VERSION.csv";
var listFiles = findfiles(dir, recursive=R);
//var sameSizeFiles : domain((string,string));
var sameSizeFiles = " ";
var FlaggedList = " ";
proc SizeCheck() {
  for file1 in listFiles {
    for file2 in listFiles {
      if (getFileSize(file1) == getFileSize(file2)) &&
      (file1 != file2) {
        sameSizeFiles += file1 +" "+ file2;
        FlaggedList += ("Size dupe match found for: " + file1 + " , " + file2 + "\r\n");
      }
    }
  }
}
proc FullCheck() {
  for file1 in sameSizeFiles {
    for file2 in sameSizeFiles {
      if (file1 != file2) {
        var tmp1 = open(sameSizeFiles[file1], iomode.r);
        var tmp2 = open(sameSizeFiles[file2], iomode.r);
        var tmpRead1 = tmp1.reader();
        var tmpRead2 = tmp2.reader();
        if tmp1.length() != tmp2.length() {
          if tmpRead1.read(string) != tmpRead2.read(string) {
            writeln("headCheck found diffs in samesized files" +
            file1+" - against - "+file2);
          }
        }
        tmpRead1.close();
        tmp1.close();
        tmpRead2.close();
        tmp2.close();
      }
    }
  }
}
proc dirSameFileRM() {
  for file1 in listFiles {
    for file2 in listFiles {
      if (sameFile(file1, file2)) && file1 != file2 {
        writeln("sameFile for " +file1 +" "+ file2+ "shows identical");
      }
    }
  }
}
proc WriteFiles() {
  if exists(sameSizeFiles[1]) {
    {  // write to some files to make life easier.
      // this is the human / verbose .txt file
      var CompFLag = compile(FlaggedList);
      var FlagFile = open(FileF, iomode.cw);
      var ChannelF = FlagFile.writer();
      ChannelF.write(CompFLag);  // file and channel close() is crucial, clean up processes
      ChannelF.close();  // both must be closed.
      FlagFile.close();  //  otherwise asking for non-reproducible troubles...?
    }
    {
      var TupleFile = open(FileT, iomode.cw);
      var ChannelT = TupleFile.writer();
      ChannelT.write(FileT);
      ChannelT.close();
      TupleFile.close();
    }
  }
  writeln("no dupes found");
}
proc ShowHuman() {  // open nano to view dupes
//  var openFlagN = spawnshell(["nano " + FileF]);
  if exists(sameSizeFiles[1]) {
    writeln("open a txt file of dupes! with [nano][vi][atom] " + FileF);
  }
  writeln("no dupes!!");
}
SizeCheck();
dirSameFileRM()
FullCheck();
WriteFiles();
ShowHuman();
