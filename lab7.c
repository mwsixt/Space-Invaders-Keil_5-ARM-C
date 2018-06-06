extern int display_digit_on_7_seg(int input);					//Import all needed subroutines from assembly code
extern int illuminateLEDs(char input[]);
extern int illuminate_RGB_LED(int input);
extern int interrupt_init(void);
extern int output_string(char input[]);
extern int FIQ_Handler(void);
extern int lab7(void);
extern int library7(void);
extern int pin_connect_block_setup_for_uart0(void);
extern int output_character(char input);
extern int update_score(char score[]);
extern int start_timers(void);
extern int update_level(void);
extern char read_character(void);
extern char* read_string(void);
extern int stop_timers(void);
#include <stdlib.h>
void serial_init(void)
{
	  	/* 8-bit word length, 1 stop bit, no parity,  */
	  	/* Disable break control                      */
	  	/* Enable divisor latch access                */
   		*(volatile unsigned *)(0xE000C00C) = 131; 
	  	/* Set lower divisor latch for 9,600 baud */
			*(volatile unsigned *)(0xE000C000) = 10; 
	  	/* Set upper divisor latch for 9,600 baud */
			*(volatile unsigned *)(0xE000C004) = 0; 
	  	/* 8-bit word length, 1 stop bit, no parity,  */
	  	/* Disable break control                      */
	  	/* Disable divisor latch access               */
	  	*(volatile unsigned *)(0xE000C00C) = 3;
}

char board[17][23];									//Char array containing gameboard and all enemies,playes,shots,etc

char enemy1 = 'O';									//Back row enemy 40pts
char enemy2 = 'M';									//2nd & 3rd back row enemy 20 pts
char enemy3 = 'W';									//1st & 2nd row enemy 10pts
char mShip = 'X';										//motherShip 100-300pts
char player = 'A';									//Player character
char direction = 'R';								//Char for determining enemy direction
char shield = 'S';									//Initial Shield state
char smallShield = 's';							//Shield after being shot once
char enemyGun = 'v';								//Enemy gun representation
char mShipDir = 'R';								//Char for determining mothership direction
char playerGun = '^';								//Player gun representation
char levelC='0';										//Char version of level

char levelScoreString[]="0000";			//String version of levelScore
char playerLivesChar[]="1111";			//String version of playerLives
char levelPrompt[]="Level: 0";			//Level prompt
char motherShipPoints[]="   ";

int direction2=0;
int time = 120;
int bDemX = 23;											//Y dimension of the board
int bDemY = 17;											//X dimension of the board
int mShipSeen =0;										//Number of motherships seen
int mShipShot =0;										//Number of motherships shot
int numOfEnemy = 0;									//Number of enemies on the board
int win = 1;												//boolean for win condition		
int level =0; 											//current level
int totalScore = 0000;									//Total score overall
int levelScore = 0;									//Current level score
int mShipBonusCount=0;
int mShipFlag=0;
int mShipScore=0;
int motherOnBoard = 0;							//Boolean for mothership in play
int playerLives =4;									//Number of player lives
int game = 0;												//Boolean for whether game is running
int bulletOB =0;
void newLevel(void);
void endGame(void);									//Declares endGame function
int printBoard(void);								//Declares printBoard function
void StartGame(void);								//Declares startGame function
void initiateBoard(void);
int main()
{
	/*Timer and interupt setup*/
	pin_connect_block_setup_for_uart0();
	serial_init();
	interrupt_init();
	lab7();
	
	/*ANSI char setup*/
	char clear[]="\033c";
	output_string(clear);
	char hide[]="\033[?25l";
	output_string(hide);

	/*game setup*/	
	
	
	
	initiateBoard();
	StartGame();												//Starts instruction screen
	output_string(clear);								//Clears screen
	output_string(hide);								//Hides Cursor
	illuminateLEDs(playerLivesChar);		//Turns on LEDs
	illuminate_RGB_LED('g'); 		//Turn on Green LED
	while(game == 0){										//While the game is Running
		if((board[bDemY-3][bDemX-2]==enemy1)||(board[bDemY-3][bDemX-2]==enemy2)||(board[bDemY-3][bDemX-2]==enemy3)||(numOfEnemy==0)||(time==0)){		
			game=1;													//If an enemy is in the corner above the player, end game
		}
		if(numOfEnemy==0){
			newLevel();
		}
		//printBoard();											//print game
	}
	endGame();													//End the game
}
/********************************************************************** 
*This method intatntiates the board to the beggining of the level setup 
**********************************************************************/
void initiateBoard(){
		/*wall setup*/
	char vWall='|';
	char hWall='-';
		/*Board Instantiation */
	for(int i = 0; i<bDemY; ++i){
		for(int j =0; j<bDemX; ++j){
			if((i==0 && j==0)||(i==0 && j==bDemX-1)||(i==bDemY-1 && j==bDemX-1)||(i==bDemY-1 && j==0)){		//If one of four corners, add vertical wall
				board[i][j] = vWall;
			}
			else if(i==0 || i==bDemY-1){	//If top or bottom row, add horizontal wall across
				board[i][j] = hWall;
			}
			else if(j==0 || j==bDemX-1){  //If left or right side, add vertical wall
				board[i][j] = vWall;
			}	
			else if (i==2 && j >7 && j<15){				
				board[i][j] = enemy1;						  //back row enemies added
				++numOfEnemy;											
			}
			else if((i==3 ||i==4) && j >7 && j<15){
				board[i][j] = enemy2;				//mid row enemies added
				++numOfEnemy;							
			}
			else if((i==5 ||i==6) && j >7 && j<15){
				board[i][j] = enemy3;						//front row enemies added
				++numOfEnemy;
			}
			else if((i==bDemY-5) && ((j == 5)||(j == 6)||(j == 7)||(j == 10)||(j == 11)||(j == 12)||(j == 15)||(j == 16)||(j == 17))){
				board[i][j] = shield;		//hardcodes in the shield
			}
			else if((i==bDemY-4) && ((j == 5)||(j == 7)||(j == 10)||(j == 12)||(j == 15)||(j == 17))){
				board[i][j] = shield;		//hardcodes in the shield
			}
			else{		
				board[i][j] = ' ';			//Flood empty space so board prints correctly
			}
		}
	}
	board[bDemY-2][bDemX/2] = player;		//places player on the board				
}
/***************************************************************** 
*This method begins the game by displaying all of the instructions 
*and prompts the user to begin the game
*****************************************************************/
void StartGame(){
	char clear[]="\033c";								//Clear the screen
	illuminate_RGB_LED('w');						//Turn light white
	
	output_string("Welcome Player!!");	//Output initial prompts
	output_string(" ");
	output_string("Press Y to play");
	output_string("Press N for Instructions");
	
	char input=read_character();				//Take in user input
	//char input=inputStr[0];
	if(input == 89 || input == 121){		//If Y or y
		output_string(clear);							//clear the screen
		start_timers();										//Start the timers
		level++;
		return;
	}	
	else{
		output_string(clear);							//clear the screen
		
		/*Output the Instructions*/
		output_string("  You my dear player have been given the honor of protecting earth from the invading army. ");	
		output_string("Your defense system is the letter A located on the bottom row of the board it has 3 blocks of the earths finest S-shields.");
		output_string("Your goal is to shoot away the incoming invaders which are denoted by the characters O, M and W before they can reach you.");
		output_string("Keep an eye out for the mothership X and look out they shoot back. If you get shot you will lose one of your four lives");
		output_string("");
		output_string("Move and shoot with the following controls ");
		output_string("A - Move left ");
		output_string("D - Move right");
		output_string("W – To shoot ");
		output_string("(on the LPC 2138) P14 – To pause");
		output_string("Q – To quit");
		output_string("");
		output_string("Expect to have fun! Rack up as many points as possible. The point breakdown is as follows ");
		output_string("W: 10 points");
		output_string("M: 20 points");
		output_string("O: 40 points");
		output_string("X: 100-300 points");
		output_string("Moving to the next Level: 50 points");
		output_string("Getting shot: -100 points");
		output_string("");
		output_string("The Score is displayed to you through the seven segment display on the LPC 2138.");
		output_string("The game is over when you run out of lives or the enemy Army touches down on earth.");
		output_string("You have 2 minutes before they run out of steam but beware once you finish off the first ");
		output_string("wave there will be more waves that will be even faster.");
		output_string("");
		output_string("Good luck soldier.");
		output_string("");
		output_string("Press any key to play");
		
		/*Take in input*/
		input = read_character();
		output_string(clear);							//clear the screen
		start_timers();										//Start the timers
		level++;
	}
}
/**************************************************************************
*Changes variables to reflect a new game started, mostly changes thing to 0
**************************************************************************/
void newGame(){
	time=120;
	mShipSeen=0;
	mShipShot=0;
	numOfEnemy=0;
	game=0;
	bulletOB=0;
	level=0;
	totalScore=0;
	levelScore=0;
	motherOnBoard=0;
	playerLives=4;
	playerLivesChar[0]='1';
	playerLivesChar[1]='1';
	playerLivesChar[2]='1';
	playerLivesChar[3]='1';
	main();
}
/***************************************************
*Starts a new level and resets variables accordingly
***************************************************/
void newLevel(){
	totalScore+=levelScore;
	levelScore=0;
	level++;
	if(level<5){
		update_level();
	}
	initiateBoard();
}	
/*****************************************************
*Mutator method to decrement counter from the Assembly
*****************************************************/
void decTime(){
	time--;
}	
/********************************************************* 
*The method handles the user getting hit and losing a life
*********************************************************/
void death(){
	illuminate_RGB_LED('r');						//Turn LED red
	--playerLives;											//Sutract from player lives
	for(int i=4;i>playerLives;i--){			//Creates string version of player lives, but fills it with 0s up to player lives
		playerLivesChar[i-1]='0';
		illuminateLEDs(playerLivesChar);
	}	
	if(levelScore>100){									//If the player has a score greater than 100, subtracts 100 from level score
		levelScore -= 100;
	}
	else{																//Else the score is set to 0
		levelScore=0;
	}

	if(playerLives == 0){								//If the player is out of lives, stop the game
		game = 1;
	}
	else{																//If not:
		for(int i = 0; i<bDemX; i++){		
			if(board[bDemY-2][i] == player){//Get rid of the shot above the player, and the player itself
				board[bDemY-2][i] = ' ';
				board[bDemY-3][i] = ' ';
			}
		}
		board[bDemY-2][bDemX/2] = ' ';		//Gets rid of the enemy shot above the spot 
		board[bDemY-2][bDemX/2] = player;	//Replaces player character in original position
		}
}
/********************************************************
*Updates the board, particularly with with enemy movement
********************************************************/
void updateBoard(){
	illuminate_RGB_LED('g');					//Turns LED green
	for(int j = 2; j<bDemY-3; j++){
		if((board[j][bDemX-2] == enemy1) || (board[j][bDemX-2] == enemy2) ||(board[j][bDemX-2] == enemy3)){
				direction2 = 1;		
		} 
	}
	for(int j = 2; j<bDemY-3; j++){
		if((board[j][1] == enemy1) || (board[j][1] == enemy2) ||(board[j][1] == enemy3)){
				direction2 = 1;		
		} 
	}
	if(direction == 'R'){							//Invaders moving right		
			/*RIGHT DOWNWARD CASE*/
		if(direction2 ==1){	
			direction = 'L';
			direction2 = 0;				
			for(int imov =bDemY-1; imov>=0; imov--){   //move everything down and 1 space left
				for(int jmov = 1; jmov<bDemX-1; jmov++){ 
					if((board[imov][jmov] == enemy1) || (board[imov][jmov] == enemy2) ||(board[imov][jmov] == enemy3)){						
						board[imov+1][jmov-1] = board[imov][jmov];
						board[imov][jmov] = ' ';
					}
				}
			}
		}
		else{		
			for(int imov =bDemY-1; imov>=0; imov--){ 
				for(int jmov = bDemX-1; jmov>=0; jmov--){ //move everything Right
					if((board[imov][jmov+1]==playerGun)&&((board[imov][jmov]==enemy1)||(board[imov][jmov]==enemy2)||(board[imov][jmov]==enemy3))){
							bulletOB=0;
					}
					if((board[imov][jmov] == enemy1) || (board[imov][jmov] == enemy2) ||(board[imov][jmov] == enemy3)){
						board[imov][jmov+1] = board[imov][jmov];
						board[imov][jmov] = ' ';
					}
				}
			}
		}
	}
	else{ //left case
		/*LEFT DOWNWARD CASE*/
		if(direction2==1){
			direction = 'R';
			direction2 = 0;				
			for(int imov =bDemY-1; imov>=0; imov--){   //move everything down and 1 space Right
				for(int jmov = 0; jmov<bDemX-1; jmov++){ 
					if((board[imov][jmov] == enemy1) || (board[imov][jmov] == enemy2) ||(board[imov][jmov] == enemy3)){						
						board[imov+1][jmov+1] = board[imov][jmov];
						board[imov][jmov] = ' ';
					}
				}
			}
		}
		else{									
		/*LEFT RIGHT CASE*/
			for(int imov =bDemY-1; imov>=0; imov--){ 
				for(int jmov = 0; jmov<=bDemX-1; jmov++){ //move everything Left
					if((board[imov][jmov-1]==playerGun)&&((board[imov][jmov]==enemy1)||(board[imov][jmov]==enemy2)||(board[imov][jmov]==enemy3))){
							bulletOB=0;
					}
					if((board[imov][jmov] == enemy1) || (board[imov][jmov] == enemy2) ||(board[imov][jmov] == enemy3)){
						board[imov][jmov-1] = board[imov][jmov];
						board[imov][jmov] = ' ';
					}
				}
			}
		}
	}	
}	
/********************
*Prints out the board
********************/
int printBoard(){
	//char clear[]="\033c";
	char clear[]="\033[1;2H";			
	output_string(clear);										//clear the screen now
  levelC=level+'0';
	levelPrompt[7]=levelC;									
	output_string(levelPrompt);							//Prints out level prompt
	
	char timePrompt[]="Time:  :  ";		//Displays the timer		
	if(time==120){
		timePrompt[6] = '2';
		timePrompt[8] = '0';
		timePrompt[9] = '0';
	}
	else if(time>60){
		timePrompt[6] = 1 +'0';
		timePrompt[8]=(time-60)/10+'0';
		timePrompt[9]=(time-60)%10+'0';
	}
	else{
		timePrompt[6] = '0';
		timePrompt[8]=time/10+'0';
		timePrompt[9]=time%10+'0';
	}
	output_string(timePrompt);
	
	char cr=13;
	char vt=11;
	for(int i=0;i<bDemY;++i){								//Prints out the board in proper format
			for(int j=0;j<=bDemX;++j){
				if(j==bDemX){
					if(mShipFlag==1){
							if(mShipBonusCount==5){
								mShipBonusCount=0;
								mShipFlag=0;
								mShipScore=0;
								motherOnBoard=0;
								for(int i=2;i>=0;i--){
									motherShipPoints[i]=' ';
								} 
							}
							else{
								int tempmScore=mShipScore;
								for(int i=2;i>=0;i--, tempmScore/=10){
									motherShipPoints[i]=tempmScore%10+'0';
								}	
								mShipBonusCount++;
							}	
							output_string(motherShipPoints);
					}
					output_character(cr);						//Prints out the equivalent of the enter key
					output_character(vt);
				}
				else{
					output_character(board[i][j]);	//Prints out the board at the specific character
				}
			}
		}
	int tempScore = levelScore;							//Set up levelScore string 
	for(int i=3;i>=0;i--, tempScore/=10){
		levelScoreString[i]=tempScore%10+'0';
		int potato=0;
	}
	update_score(levelScoreString);					//Updates the score

	return 0;
}
/**********************************************************************************
*Method moves the player as determined by the input generated by the UART interrupt
**********************************************************************************/
int movePlayer(char input){
	if((input == 97)||(input == 65)){						//move player left
			for(int i = 0; i<bDemX; i++){
				if((board[bDemY-2][i] == player)&&(i!=1)){
					board[bDemY-2][i] = ' ';
					board[bDemY-2][i-1] =player;
					break;
				}
			}
		}
	if((input == 100)||(input == 68)){						//move player right
			for(int i = 0; i<bDemX; i++){
				if((board[bDemY-2][i] == player)&&(i!=bDemX-2)){
					board[bDemY-2][i] = ' ';
					board[bDemY-2][i +1] =player;
					break;
				}
			}
		}
	return 0;
}
/*******************************************************
*Moves the mothership according to the direction created
*******************************************************/
void moveMother(){		
	if(motherOnBoard==1){
		if(mShipDir == 'R'){							//If the direction is right, moves the mothership left (I know)
			for(int i = bDemX-1; i>0; i--){
				if((board[1][i+1]==playerGun)&&(board[1][i]==mShip)){
					bulletOB=0;
				}
				if(board[1][i] ==  mShip){
					board[1][i] = ' ';
					board[1][i-1] = mShip;
					break;
				}
				if (board[1][0] ==  mShip){	//If the mothership is in the corner, replace the wall it replaced
					motherOnBoard=0;
					board[1][0] =  '|';
					break;
				}
			}
			
		}
		else{ 													//If the direction is left, moves the mothership right (I know)
			for(int i = 1; i<bDemX-1; i++){
				if((board[1][i-1]==playerGun)&&(board[1][i]==mShip)){
					bulletOB=0;
				}
				if(board[1][i] ==  mShip){
					board[1][i] = ' ';
					board[1][i+1] = mShip;
					break;
				}
				if (board[1][bDemX-1] ==  mShip){		//If the mothership is in the corner, replace the wall it replaced
					motherOnBoard=0;
					board[1][bDemX-1] =  '|';
					break;
				}
			}
		}	
	}
}	
/*******************************************************************************************
*	Generates a motherShip based on a random number and if there is already a mothership there
*******************************************************************************************/
void generateMother(){
	if(motherOnBoard==0){		//Only has a chance of creating a mothership if there isn't one on the board	
		int x = rand()%50+1;		//Creates a random X value from 1-5 
		int y=rand()%2;				//Creates a random Y value
		if(x==1){							//If the x is a one, genereate a mothership
			motherOnBoard=1;		//Set motherOnBoard flag
			++mShipSeen;				//Increment mothership count
			if(y==0){						
				mShipDir = 'R';		//If y=0, set direction to R and place mothership to the right side
				board[1][bDemX-2]= mShip; 
			}
			else{
				mShipDir='L';			//If y=1, set direction to L and place mothership to the left side
				board[1][1]= mShip;
			}
		}
	}
}
/*************************
*Generates a player's shot
*************************/
void generatePlayerShot(){		//Creates a shot right right above the player
	if(bulletOB==0){
		bulletOB=1;
		for(int j=0;j<bDemX-1;j++){
			if(board[bDemY-2][j]==player){
				board[bDemY-3][j]=playerGun;
			}	
		}
	}
}
/***************************
*Generates an enemies's shot
***************************/
void generateEnemyShot(){
	int x=rand()%15+1;
	int y=rand()%21+1;
	int flag=0;
	for(int j=bDemX-1;j>0;j--){
		for(int i=bDemY-1;i>0;i--){
			if(((board[y][x]==enemy1)||(board[y][x]==enemy2)||(board[y][x]==enemy3)) && (flag==0)){
				for(int k=y;k<bDemY;k++){
					if(board[k+1][x]==' '){
						board[k+1][x]=enemyGun;
						flag=1;
						break;
					}
				}
				break;
			}
		}	
	}	
}	
/***********************************
*Moves an enemy's or a player's shot
***********************************/
void moveShot(){
	for(int j=bDemX-2;j>0;j--){					//Checks through entire board minues edge cases
		for(int i=bDemY-1;i>0;i--){
			if(board[i][j]==playerGun){			//If the shot is a playershot
				if(board[i-1][j]==enemy1){		
					board[i][j]=' ';						//If the spot above is a O, clear the enemy, the shot, deincrement the enemy count, and add 40 to the score
					board[i-1][j]=' ';
					levelScore+=40;
					numOfEnemy--;
					bulletOB=0;
				}
				else if(board[i-1][j]==enemy2){
					board[i][j]=' ';
					board[i-1][j]=' ';					//If the spot above is a M, clear the enemy, the shot, deincrement the enemy count, and add 20 to the score
					levelScore+=20;
					numOfEnemy--;
					bulletOB=0;
				}
				else if(board[i-1][j]==enemy3){
					board[i][j]=' ';						//If the spot above is a W, clear the enemy, the shot, deincrement the enemy count, and add 10 to the score
					board[i-1][j]=' ';
					levelScore+=10;
					numOfEnemy--;
					bulletOB=0;
				}
				else if(board[i-1][j]==shield){
					board[i][j]=' ';						//If the spot above is a shield, replace with a small shield
					board[i-1][j]='s';
					bulletOB=0;
				}
				else if(board[i-1][j]==smallShield){
					board[i][j]=' ';						//If the spot above is a ssmallshield, replace with a blank
					board[i-1][j]=' ';
					bulletOB=0;
				}	
				else if(board[i-1][j]==mShip){
					board[i][j]=' ';						//If the spot above is a mothership, clear the enemy, the shot, and add a random 100-300 to the score
					board[i-1][j]=' ';
					mShipScore=rand()%200+100;
					levelScore+=mShipScore;
					mShipShot++;
					mShipFlag=1;
					bulletOB=0;
				}
				else if(board[i-1][j]==enemyGun){
					board[i][j]='~';					//If the spot above is an enemy gun, clear the spot above and place a tilde in place of the player shot
					board[i-1][j]=' ';
				}	
				else if(board[i-1][j]=='-'){
					board[i][j]=' ';					//If the spot is a wall, clear the enemy shot
					bulletOB=0;
				}	
				else{
					board[i][j]=' ';					//If its a blank, move the player shot up
					board[i-1][j]=playerGun;
				}	
				break;
			}
			else if(board[i][j]==enemyGun){		//If the shot is an enemy shot
				if(board[i+1][j]==shield){
					board[i][j]=' ';							//If the spot below is a shield, replace with a small shield
					board[i+1][j]=smallShield;
				}
				else if(board[i+1][j]==player){	//If the spot below is a player, initiate death
					death();
				}
				else if(board[i+1][j]==smallShield){
					board[i][j]=' ';							//If the spot below is a small shield, clear the shot and the smallShield
					board[i+1][j]=' ';
				}
				else if(board[i+1][j]=='-'){		//If the spot below is a wall, clear the shot
					board[i][j]=' ';
				}
				else{
					board[i][j]=' ';							//If the spot below is a blank, move the enemy gun down
					board[i+1][j]=enemyGun;
				}
				break;
			}
			else if(board[i][j]=='~'){				//If the spot is a tilde, change it to an enemy gun and the spot above to a player gun
				board[i][j]=enemyGun;					
				board[i-1][j]=playerGun;
			}	
		}	
	}	
}	
/******************************
*Generates the game over screen
******************************/
void endGame(){
	char clear[]="\033c";
	output_string(clear);						//Clears screen
	output_string("GAME OVER");
	
	levelC=level+'0';								//Prepares and prints the level prompt
	levelPrompt[7]=levelC;
	output_string(levelPrompt);
	
	char levelScorePrompt[]="Level Score:     ";		//Prepares and prints the level score prompt
	int tempScore = levelScore;			
	for(int i=16;i>=13;i--, tempScore/=10){
		levelScorePrompt[i]=tempScore%10+'0';
	}	
	output_string(levelScorePrompt);
	
	char motherShipPrompt[]="Motherships:   /  ";		//Prepares and prints the mothership prompt
	int tempMothers=mShipShot;
	for(int i=14;i>=13;i--,tempMothers/=10){
		motherShipPrompt[i]=tempMothers%10+'0';
	}	
	tempMothers=mShipSeen;
	for(int i=17;i>=16;i--,tempMothers/=10){
		motherShipPrompt[i]=tempMothers%10+'0';
	}	
	output_string(motherShipPrompt);

	//printf("Level Time:");												//update this line to have the timer in it
	//printf("/n");
	totalScore+=levelScore;
	char totalScorePrompt[]="Total Score:     ";		//Prepares and prints the total score prompt
	int tempTotalScore=totalScore;
	for(int i=18;i>=13;i--,tempTotalScore/=10){
		totalScorePrompt[i]=tempTotalScore%10+'0';
	}	
	output_string(totalScorePrompt);
	stop_timers();
	illuminate_RGB_LED('p');				//sets LED to purple
	char againP[]="Would you like to play again?";
	char yorother[]="Enter Y if yes, or any other key if no";
	output_string(againP);
	output_string(yorother);
	char input=read_character();
	if((input==121)||(input==89)){
		newGame();
	}	
	output_string(clear);						//Clears screen
	output_string("Goodbye");
}
