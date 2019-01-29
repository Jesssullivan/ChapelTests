/**
* Implements a multi-token semaphore.
*
* Authors: Jess Sullivan
*/
	//the number of tokens available
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
