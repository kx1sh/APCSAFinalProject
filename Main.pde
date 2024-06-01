private static final int blockSize = 20;
private static final int AIR=0, GRASS=1, BEDROCK=2, WATER=3, OAK_WOOD = 4;
private World world;

public void setup() {
  size(640*2, 360*2, P3D);
  world = new World();
}

public void draw() {
  world.draw();
}

public void keyPressed() {
  world.getPlayer().keyPressed();
}  
public void keyReleased() {
  world.getPlayer().keyReleased();
}  
public void mouseWheel(MouseEvent event) {
  world.getPlayer().mouseWheel(event);
}  
public void mouseMoved(MouseEvent event) {
  world.getPlayer().mouseMoved(event);
}
