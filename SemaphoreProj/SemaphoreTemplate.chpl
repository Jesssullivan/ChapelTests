/**
* Implements a multi-token semaphore.
* This is a rough template provided through Kyle's instruction
*
* Authors: Jess Sullivan, ala Kyle Burke@https://turing.plymouth.edu/~kgb1013/?course=4310&project=0
*/
	//the number of tokens available

	// *removed duplicate numToken Decleration

	var numTokens : atomic int;

	proc Semaphore() {
		this.numTokens.write(1);
	}
	proc writeThis(writer) {

	}
	proc getNumTokens() : int {

	}
	proc p() {
		while(this.numTokens.read() <= 0) {
			sleep(2);
		}
		this.numTokens.sub(1); //removes one token


		proc v() {
			this.numTokens.add(1);
		}

		var y = this.x$; //any other reads must wait for a write

		this.x$ = 1;
	}

	// TBD critical section
