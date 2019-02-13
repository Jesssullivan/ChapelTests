use FileSystem;

config const dir = ".";
config const R : bool=true;
config const FileF = "Flagged_Dupes.txt";
config const  FileT = "Flagged_Dupes-Tversion.csv";
var listFiles = findfiles(dir, recursive=R);
//var sameSizeFiles : domain((string,string));
var sameSizeFiles = " ";
var FlaggedList = " ";
proc SizeCheck() {
  writeln("entering SizeCheck, evaluating overall file size....")
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
  if exists(sameSizeFiles[1]) {
    writel("entering FullCheck, sameSizeFiles[1] == true");
    for file1 in sameSizeFiles {
      for file2 in sameSizeFiles {
        if (file1 != file2) {
          var tmp1 = open(file1, iomode.r);
          var tmp2 = open(file2, iomode.r);
          var tmpRead1 = tmp1.reader();
          var tmpRead2 = tmp2.reader();
          if tmp1.length() != tmp2.length() {
            // Start a ReadCheck
            if tmpRead1.read(string) != tmpRead2.read(string) {
              writeln("ReadCheck found diffs in samesized files" +
              file1+" - against - "+file2);
            }
          }
          if tmpRead1.read(string) == tmpRead2.read(string) {
            writeln("ReadCheck knows " +
            file1+" - and - "+file2+" have different lengths under scrutiny.
             same size, appears a dupe in ReadCheck.  Perhaps review otherwise
              Manually? ");
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
  proc WriteFiles() {
    if exists(sameSizeFiles[1]) {
      writeln("entering WriteFiles, sameSizeFiles[1] == true")
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
      writeln("files written and channels closed.")
    }
  }
  proc ShowHuman() {
     // open nano to view dupes, spawn process for later etc
    if exists(sameSizeFiles[1]) {
      writeln("open a txt file of dupes! with [nano][vi][atom] " + FileF);
    }
  }
  SizeCheck();
  FullCheck();
  WriteFiles();
  ShowHuman();
