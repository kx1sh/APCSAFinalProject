import controlP5.*;
import com.jogamp.newt.opengl.GLWindow;
import static java.lang.Math.*; 
PImage background;
ControlP5 menumaker;
PFont font;
boolean menuq = true;
private static final int blockSize = 20;
private static final int AIR=0, GRASS=1, DIRT=2, BEDROCK=3, WATER=4, OAK_WOOD=5, OAK_WOOD_PLANKS=6;
private static final int I_NONE=0, I_GRASS=1, I_DIRT=2, I_BEDROCK=3, I_STICK=4, I_OAK_WOOD=5, I_OAK_WOOD_PLANKS=6;
private final int[] C = {
  color(0),
  color(25, 200, 50),
  color(100, 60, 40),
  color(100),
  color(0, 100, 150),
  color(148, 111, 0),
  color(180, 150, 0),
};
private PImage[] imageItems = new PImage[I_OAK_WOOD_PLANKS+1];
private World world;

public void setup() {
  font = createFont("Minecraft.ttf", 28);
  size(640*2, 360*2, P3D);
  windowTitle("Minecraft Clone");
  background = loadImage("background.jpg");
  background.resize(2*640, 2*360);
  menumaker = new ControlP5(this);
  menumaker.addButton("play").setPosition(width/2-50, height/2-(50*9/16)).setSize(100, 50).setLabel("Play").getCaptionLabel().setFont(font).setSize(28);
  menumaker.addButton("exxit").setPosition(width/2-50, height/2+(50*9/16)).setSize(100, 50).setLabel("Exit").getCaptionLabel().setFont(font).setSize(28);
  
  for (int i = 1; i < I_OAK_WOOD_PLANKS+1; i++) {
    try {
      imageItems[i] = loadImage("textures/items"+(i+1)+".png");
    } catch (Exception e) {}
  }
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
 else { if (world != null) world.draw();}}
public void play(){menuq = false; menumaker.hide(); world = new World();}
public void exxit(){exit();}

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
