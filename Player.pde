public class Player extends Entity {
  private byte selectedItemIndex;
  private Item[] inventory;
  private boolean[] keyPresses;
  private float mx, my;
  
  private static final float playerSpeed = 15;
  private static final float mouseSensitivity = .2;
  
  public Player(float h, PVector d, PVector p, PVector v, World w) {
    super(h, d, p, v, w);
    inventory = new Item[45]; // 1 crafting output, 4 crafting inputs, 40 inventory items; in actual Minecraft each row has 9 items instead of 10
    keyPresses = new boolean[512];
    selectedItemIndex = 0;
    mx = width/2; my = height/2;
  }
  
  public byte getSelectedItemIndex() {return selectedItemIndex;}
  
  @Override
  public void update() {
    float rotationAngle = map(mx, 0, width, 0, TWO_PI);
    float elevationAngle = map(my, 0, height, 0+PI/10, PI-PI/10);
    PVector dir = new PVector(cos(rotationAngle) * sin(elevationAngle), -cos(elevationAngle), sin(rotationAngle) * sin(elevationAngle));
    setDir(dir);
    
    boolean grounded = getWorld().getBlock((int)(getPos().x/blockSize), (int)(getPos().y/blockSize)+1, (int)(getPos().z/blockSize)).isSolid();
    PVector inDir = new PVector();
    if (keyPresses['w']) inDir.add(new PVector(dir.x, 0, dir.z).normalize().mult(playerSpeed));
    if (keyPresses['a']) inDir.add(new PVector(dir.z, 0, -dir.x).normalize().mult(playerSpeed));
    if (keyPresses['s']) inDir.add(new PVector(-dir.x, 0, -dir.z).normalize().mult(playerSpeed));
    if (keyPresses['d']) inDir.add(new PVector(-dir.z, 0, dir.x).normalize().mult(playerSpeed));
    if (keyPresses[' ']) {
      //inDir.add(new PVector(0, -playerSpeed, 0)); // flying
      if (grounded) setVel(new PVector(0, -blockSize, 0)); // jumping
    }
    if (keyPresses[256 + SHIFT]) inDir.add(new PVector(0, playerSpeed, 0));
    move(inDir.normalize().mult(playerSpeed), true);
  }
  
  public void keyPressed() {
    if (key == CODED) keyPresses[256 + keyCode] = true;
    else keyPresses[key] = true;
    
    if (key >= '0' && key <= '9') selectedItemIndex = (byte)((key - '0' + 9) % 10);
  }  
  public void keyReleased() {
    if (key == CODED) keyPresses[256 + keyCode] = false;
    else keyPresses[key] = false;
  }  
  public void mouseWheel(MouseEvent event) {
    selectedItemIndex = (byte)((selectedItemIndex + event.getCount() + 20) % 10);
  }  
  public void mouseMoved(MouseEvent event) {
    mx += (event.getX() - width/2) * mouseSensitivity;
    mx %= width;
    my += (event.getY() - height/2) * mouseSensitivity;
    my = constrain(my, 0, height);
    world.getWindow().warpPointer(width/2,height/2);
  }
}
