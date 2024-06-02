private static final int blockSize = 20;
private static final int AIR=0, GRASS=1, BEDROCK=2, WATER=3, OAK_WOOD = 4;
private World world;

public void setup() {
  size(640*2, 360*2, P3D);
  windowTitle("Minecraft Clone");
  world = new World();
}

public void draw() {
  if (world != null) world.draw();
}

public void keyPressed() {
  if (world != null) world.getPlayer().keyPressed();
}  
public void keyReleased() {
  if (world != null) world.getPlayer().keyReleased();
}  
public void mouseWheel(MouseEvent event) {
  if (world != null) world.getPlayer().mouseWheel(event);
}
public void mouseMoved(MouseEvent event) {
  if (world != null) world.getPlayer().mouseMoved(event);
}
public void mousePressed(MouseEvent event) {
  if (world != null) world.getPlayer().mousePressed(event);
}
