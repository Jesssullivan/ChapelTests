use FileSystem;
use Spawn;
use Time;
// --flags!  example: --dir=../ --R=false --poof==true //
config const dir = ".";
config const R : bool=true;  // default will crawl all child dirs
//config const poof : bool=false; //no print, remove direct dupes
config const fileF = "Flagged_Dupes.txt";
config const  fileCSV = "Flagged_Dupes-CSV-VERSION.csv";
// global vars, counters arrays, and domain "B"
var listFiles = findfiles(dir, recursive=R);
var NumFiles, b, c = 0;  // make a few scratch counters
for string in listFiles do NumFiles += 1;  // NumFiles is... exactly what is sound like
var i = for i in 1..NumFiles do i;
var j = for j in 1..NumFiles by-1 do j; // just going a different direction.
var B : [1..NumFiles,1..NumFiles] int;  // a domain of all options *I THINK* has now been achived
var FlaggedList, CSVlist = ''; // starting strings, will grow with dupe hits
// order of operations.  each is a proc() to make control flow easy.
// nearly identical proc()s are fine, consider them macros?
proc SizeCheck() {
  for (i,j) in B.domain {
    if getFileSize(listFiles[i]) == getFileSize(listFiles[j]) && i != j {  // note i cannot be j!
      writeln(" file size flagged for ", listFiles[i]," and ", listFiles[j]);
      // simple and easy use in initList()
      CSVlist += listFiles[i] + " , " + listFiles[j] + "\n";
      //  easier to read as proc human()
      FlaggedList += "Size dupe match found for: " + listFiles[i] + " , " + listFiles[j] + "\r\n";
    }
  }
}
proc dirFileCheck() {  // eval for literally identical files in same dir
  forall (i,j) in B.domain {
    if sameFile(listFiles[i], listFiles[j]) == true && i != j {
      writeln("found a direct dir dupe between ", listFiles[i],"and ", listFiles[j]);
    }
  }
}
// because this is uncommon, why not just remove those ASAP?
proc dirFileForce() {
  forall (i,j) in B.domain {
    if sameFile(listFiles[i], listFiles[j]) == true && i != j {
      remove(listFiles[i]);
    }
  }
}
proc initList() {
  //  eval CSVlist for a second entry, which means there is a dupe!
  if exists(CSVlist[2]) == true {
    {  // write to some files to make life easier.
      // this is the human / verbose .txt file
      var CompFLag = compile(FlaggedList);
      var FlagFile = open(fileF, iomode.cw);
      var ChannelF = FlagFile.writer();
      ChannelF.write(CompFLag);  // file and channel close() is crucial, clean up processes
      ChannelF.close();  // both must be closed.
      FlagFile.close();  //  otherwise asking for non-reproducible troubles...?
      } // using backets in weak attempt to cordon these processes off, ala cobegin
      {  // this is CSV version obviously
        var CompCSV = compile(CSVlist);
        var CSVFile = open(fileCSV, iomode.cw);
        var ChannelCSV = CSVFile.writer();
        ChannelCSV.write(CompCSV);
        ChannelCSV.close();
        CSVFile.close();
      }
    }
    writeln("no dupes found");
  }
  proc ShowHuman() {  // open nano to view dupes
    var openFlagN = spawnshell(["nano "+fileF]);
    writeln("wrote size dupes to CSV and verbose text!  Opening in... 3 seconds");
    sleep(2);
    writeln("opening txt file of dupes!");
    sleep(1);
    openFlagN.wait();
  }
  // WORK IN PROGRESS:
  // Control flow:  which processes should be done?
  SizeCheck();
  dirFileCheck();
  initList();
  ShowHuman();
