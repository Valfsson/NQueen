/**
* Name: N-queen problem
* The N Queen is the problem of placing N chess queens on an N×N chessboard so that no two queens attack each other.
* Author: Anna
* Tags: GAMA, Grid 
*/


model Nqueen

global {
	/** World variables */
	float worldDimension <- 120#m;
    geometry shape <- square(worldDimension);
    bool stop<- false;
    
    /** Agents variables */
	int number_of_queens <- rnd(4,20); 
	int board_raws <-number_of_queens;
	int board_columns <- number_of_queens;
	
	init {
					
		create Queen number: number_of_queens{
			color <- #red;
			location <-(point(rnd(0,number_of_queens*8),-5,0));	
			}					
		}
	 list<Queen> queens_list;
	 list<Board> boardcells_list;	
	 	
	reflex stop when: stop=true{
		do pause;
	}
			
	}

grid Board skills:[fipa] height:number_of_queens width:number_of_queens neighbors:number_of_queens {
	
	rgb color <-bool(((grid_x + grid_y) mod 2)) ? #white : #black;
	bool taken <-false;
	
	init{
		add self to: boardcells_list;
	}
}

species Queen skills:[fipa]{
	
int raw<-0; 
int index;
Board selectedBoardCell<- nil;
bool searchForPosition <- false;
bool noPositionAvailible <- false;
bool positionFound <- false;



	init{
		add self to: queens_list;
		index <- int(queens_list[length(queens_list) -1]);
		write name +': my index is --> '+ index;
		
		if(length(queens_list) = number_of_queens) {
  			do start_conversation with:(to: list(queens_list[0]), protocol: 'fipa-contract-net', performative: 'cfp', contents: ['Next Queen']); 
            write "Start finding position for first Queen!";
		}		
	}
	
	
	/* Calculates act-scenarios based on aswers from Queen-agents */					
	reflex recieve_cfp when:(!empty(cfps)){
		
		message msg <- cfps[0];
		list<string> m <- (msg.contents);
		string msgS <- m[0];
		
		if(msgS='Next Queen'){
			searchForPosition <-true;
			write name +': searching for a new position';
		}
		else if(msgS='No position'){
			write name +': changing current position';
			
			/* calculates next raw. Mod used for making sure raw is always in the right range */
			raw <-(raw +1) mod number_of_queens; 
			
			positionFound <- false;
 			selectedBoardCell.taken <- false;
			selectedBoardCell <- nil;
			
			if(raw = 0){
				noPositionAvailible <-true;
			} else {
				searchForPosition <-true;
			}
			
			
		}
		informs <- nil;	
	}
	
	
	/* Comunicates with Queen-predecesor */
	reflex cfp_notFound when: noPositionAvailible {
		do start_conversation with:(to: list(queens_list[index -1]), protocol: 'fipa-contract-net', performative: 'cfp', contents: ['No position']);     
        write name + ": no availible position found, one step back ";
        noPositionAvailible <- false;
	}
	
	
	/* Comunicates with Queen-successor */
	reflex cfp_found when: positionFound {
		if (index != (number_of_queens -1)){
			write name  +': position availible. ';
			do start_conversation with:(to: list(queens_list[index +1]), protocol: 'fipa-contract-net', performative: 'cfp', contents: ['Next Queen']);     
  
            noPositionAvailible <- false;
		} else {
			write 'Task completed! All Queens are placed';
			stop<- true;
		}
		
		positionFound <- false;
	}	
		
	/* Calculates position on the board */
	reflex findPosition when: searchForPosition {		
		
		 loop i from: raw to:(number_of_queens-1) {
		 	
		 	if((rawCheck(i)=false) and (diagonalUpperCheck(i, index) = false) and (diagonalDownCheck(i, index) = false)){
		 		
		 		/* new attempt on finding the position */
		 		if(selectedBoardCell != nil){
		 			write name +': Boar Cell #'+selectedBoardCell+' is now empty again';
		 			selectedBoardCell.taken <- false;
		 		}
		 		

		 		raw <- i;
		 		selectedBoardCell <- boardcells_list[cellIndex(index, raw)];
		 		write name +': selected cell at column: '+(index+1)+' . at raw: '+(raw+1);
		 		
		 		location <- selectedBoardCell.location;
		 		selectedBoardCell.taken <- true;
		 		
		 		/* Places taken cell to the list */
		 		boardcells_list[cellIndex(index, raw)] <- selectedBoardCell;
		 		searchForPosition <- false;
		 		positionFound <- true;
		 			write name +': found a position';
		 		break;		 		
		 	}
		 	
		 		/* Places last Queen */
		 		if((i = (number_of_queens-1)) and (positionFound = false)){
		 		write name +': placing last queen'; 
		 		
		 		noPositionAvailible <- true;
		 		raw <- 0;
		 		searchForPosition <- false;
		 		positionFound <- false;
		 		write name +': didn´t find a position';
		 		break;
		 	
		 	}
		 
		 } /* loop i ends*/
	
	}
	
	/* Calculates grid cells index */	
	int cellIndex(int indexQ, int rawQ ){
		return (number_of_queens * rawQ) + indexQ;
	}
	
	
	/* Makes sure there are no other queens in the same raw. Checks all Queens from the left of current Queen */
	bool rawCheck(int rowQ){
		int columnQ <- (index -1);
		
		if(columnQ >= 0){
			
			loop while: (columnQ >= 0) {
				Board cellQ <- Board[cellIndex(columnQ,rowQ)];
				
				if(cellQ.taken = true){
					return true;
				}
				columnQ <- (columnQ -1);
			}
		}
		
		return false;
	}
	
	/* Makes sure there are no other queens in the upper diagonal */
	bool diagonalUpperCheck (int rawQ, int indexQ){
		
		write name+ ': checking upper diagonal';
		
		int current_x <- indexQ;
		int current_y <- rawQ;
		
		current_x <- (current_x -1);
		current_y <- (current_y -1);
		
		write name+ ':Checking x--> ' + current_x + ': y--> '+ current_y; 
		
		loop while: ((current_y >= 0) and (current_x >= 0)){
			Board cellQ <- Board[cellIndex(current_x,current_y)];
			
			if(cellQ.taken = true){
				write name+ ': checking upper diagonal --> the cell is already taken!';
				return true;
			}
		
		current_x <- (current_x -1);
		current_y <- (current_y -1);
			
		}
		write name+ ': checking upper diagonal --> the cell is not taken!';
		return false;
	}
	
	/* Makes sure there are no other queens in diagonal that goes down. Checks all Queens from the left of current Queen */	
	bool diagonalDownCheck (int rowQ, int indexQ){
		
		write name+ ': checking "down" diagonal'; 
		
		int current_x <- indexQ;
		int current_y <- rowQ;
		
		current_x <- (current_x -1);
		current_y <- (current_y +1);
		
		write name+ ': Checking x--> ' + current_x + ': y--> '+ current_y;
		
		loop while: ( (current_y < number_of_queens) and (current_y >= 0) and (current_x >=0)){
			Board cellQ <- Board[cellIndex(current_x,current_y)];
			
			if(cellQ.taken =true){
				write name+ ': checking down diagonal --> the cell is already taken!';
				return true;
			}
		
		current_x <- (current_x -1);
		current_y <- (current_y -1);
			
		}
		
		write name+ ': checking down-diagonal --> the cell is not taken!';
		return false;
	}
	

	

aspect base{
	draw circle(4) color: color border: #black;
	}	
}


	

experiment TestModel type: gui {
	parameter "Number of Queens " var: number_of_queens category:"Queens:";

	output {
		display map type: opengl {
			
			grid Board lines:#black;
			species Queen aspect:base; 

				}
			}
}



