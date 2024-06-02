import controlP5.*;
import com.jogamp.newt.opengl.GLWindow;
import static java.lang.Math.*; 
PImage background;
ControlP5 menumaker;
PFont font;
boolean menuq = true;
private static final int blockSize = 20;
private static final int AIR=0, GRASS=1, BEDROCK=2, WATER=3, OAK_WOOD = 4;
private World world;

public void setup() {
  font = createFont("Minecraft.ttf", 28);
  size(640*2, 360*2, P3D);
  windowTitle("Minecraft Clone");
  world = new World();
  background = loadImage("background.jpg");
  background.resize(2*640, 2*360);
  menumaker = new ControlP5(this);
  menumaker.addButton("play").setPosition(width/2-50, height/2-(50*9/16)).setSize(100, 50).setLabel("Play").getCaptionLabel().setFont(font).setSize(28);
  menumaker.addButton("exit").setPosition(width/2-50, height/2+(50*9/16)).setSize(100, 50).setLabel("Exit").getCaptionLabel().setFont(font).setSize(28);
  world = new World();
}

public void draw() {
  if (menuq){
   background(background);
   textAlign(width/2, height/2);
   textFont(font);
   textSize(60);
   fill(255);
   text("Minecraft Clone", width/2, height/2-200);
   textSize(20);
   text("by Edmund and Krish", width/2, height/2-140);
  }
  else {
  if (world != null) world.draw();
}}
public void play(){menuq = false; menumaker.hide();}
public void exit(){exit();}

public void keyPressed() {
  if (!menuq && world != null) world.getPlayer().keyPressed();
}  
public void keyReleased() {
  if (!menuq && world != null) world.getPlayer().keyReleased();
}  
public void mouseWheel(MouseEvent event) {
  if (!menuq && world != null) world.getPlayer().mouseWheel(event);
}
public void mouseMoved(MouseEvent event) {
  if (!menuq && world != null) world.getPlayer().mouseMoved(event);
}
public void mousePressed(MouseEvent event) {
  if (!menuq && world != null) world.getPlayer().mousePressed(event);
}
public void drawbutton(Controller<?> b){
 float x = b.getPosition()[0];
 float y= b.getPosition()[1];
 float big = b.getWidth(); float sixthree = b.getHeight(); fill(180);
 rect(x,y,big, sixthree);
 fill(130);
 rect(x,y+sixthree-3, big, 3);
 rect(x+big-3, y, 3, sixthree);
}
