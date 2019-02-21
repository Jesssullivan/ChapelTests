# Playing with Sync Variables

```

git clone https://github.com/Jesssullivan/ChapelTests

cd ChapelTests/UsingSyncVariables

chpl ParallelTester4py.chpl

python3 HowFastSyncTest.py

```

ParallelTester.chpl and ParallelTester4py.chpl demonstrate various serial and parallel problems and solutions. Parallel is not always the best idea;

These try to build from this simple, un-synced coforall loop:
```
// This tries to add up to 100000, but fails:
// Needs sync variable!

module A { // use a module to remove the "lvalue" or shadow variable errors.
  var Num = 0;
}

coforall i in 1..100000 {
  A.Num += 1;
}

```
...Into more usual uses:

```
module char2 {
  var group = ("");
}

// Then use a separate function as the identified "Task":
// init a sync variable

var x$: sync bool;
x$ = true;

proc TaskToDo(i) {
  x$;     // "read" sync$ or otherwise wait until written to / emptied
  char2.group += (i);
  x$ = true;    // release sync$
}

// iterate in a more organized way with sync$ in place:

if SyncedParallelS_String {
coforall i in listChars {
  TaskToDo(i);
}

```
# Config Arguments / --Flags:

```
config const V : bool=false;
config const UnSyncedParallel_Int : bool=false;
config const UnSyncedParallel_String : bool=false;
config const SyncedParallel_Int : bool=false;
config const SyncedParallelS_String : bool=false;
config const SerialLoop_Int : bool=false;
config const SerialLoop_String : bool=false;
```
# Results: What do you think?

# '--UnSyncedParallel_Int=true'

0.5051926708221436 # average seconds per run
12.629816770553589 # total elapsed seconds

# '--UnSyncedParallel_String=true'

0.00779653549194336 # average seconds per run
0.19491338729858398# # total elapsed seconds

# '--SyncedParallel_Int=true'

2.1734048461914064 # average seconds per run
54.335121154785156 # total elapsed seconds

# '--SyncedParallelS_String=true'

0.008196306228637696 # average seconds per run
0.20490765571594238 # total elapsed seconds

# '--SerialLoop_Int=true'

0.007977991104125977 # average seconds per run
0.19944977760314941 # total elapsed seconds

# '--SerialLoop_String=true'

0.007650108337402344 # average seconds per run
0.1912527084350586 # total elapsed seconds
