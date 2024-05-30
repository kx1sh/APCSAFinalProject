PImage menu;
final int menustate = 0;
final int gmplay = 1; 
final int md = 2;
int state = menustate;

void setup(){
   menu = loadImage(minecraft.jpg);
   size(640*2, 360*2);
   smooth();
}
void draw(){
 switch(state){
    case menustate: 
      Menu();
      break;
    case gmplay:
      playGame();
      break;
    case md: 
      SrvlOrCrtv();
      break;
    default: 
      exit();
      break;
 }
}

void keyPressed(){
  switch(state){
    case menustate: 
      kpMenu();
      break;
    case gmplay:
      kpplayGame();
      break;
    case md: 
      kpSrvlOrCrtv();
      break;
    default: 
      exit();
      break;
 }
}
void kpMenu(){
 switch(key){
   case
 }
}
