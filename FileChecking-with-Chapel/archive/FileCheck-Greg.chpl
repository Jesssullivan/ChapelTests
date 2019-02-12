use FileSystem;
// --flags!  example: --dir=../ --R=false --poof==true //
config const dir = ".";
config const R : bool=true;  // default will crawl all child dirs

var listFiles = findfiles(dir, recursive=R); // global vars, counters arrays, and domain "B"

var sameSizeFiles : domain((string,string));

proc SizeCheck() {
  for file1 in listFiles {
    for file2 in listFiles {
      if (getFileSize(file1) == getFileSize(file2)) &&
	(file1 != file2) {
	// writeln(" file size flagged for ", file1, " and ", file2);
	sameSizeFiles += (file1, file2);
      }
    }
  }
}

SizeCheck();

writeln("dumping sameSizeFiles:");
for (i, j) in sameSizeFiles do {
  writeln(i, " and ", j, " have the same size.");
 }
