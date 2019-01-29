/**
* "Implements a multi-token semaphore."
* These are the template bits provided through Kyle's instruction
* ala Kyle Burke@https://turing.plymouth.edu/~kgb1013/?course=4310&project=0
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

	
	}

	// TBD critical section
