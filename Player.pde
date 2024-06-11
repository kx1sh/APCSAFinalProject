public class Player extends Entity {
  private byte selectedItemIndex;
  private Item[] inventory;
  private boolean[] keyPresses;
  private float mx, my;
  private PVector hit;
  private PVector preHit;
  private boolean grounded;
 
  private float playerSpeed = 5;
  private static final float mouseSensitivity = .2;
  private static final float reach = 4;
  private static final float headRadius = 5;
  
  public Player(float h, PVector d, PVector p, PVector v, World w) {
    super(h, d, p, v, w);
    inventory = new Item[45]; // 1 crafting output, 4 crafting inputs, 40 inventory items; in actual Minecraft each row has 9 items instead of 10
    keyPresses = new boolean[512];
    selectedItemIndex = 0;
    mx = width/2; my = height/2;
  }
  public float getSpeed(){return playerSpeed;}
  public void setSpeed(float s) {playerSpeed = s;}
  public byte getSelectedItemIndex() {return selectedItemIndex;}
  public PVector getHit() {return hit;}
  public PVector getPreHit() {return preHit;}
  
  @Override
  public void update() {
    float rotationAngle = map(mx, 0, width, 0, TWO_PI);
    float elevationAngle = map(my, 0, height, 0+PI/10, PI-PI/10);
    PVector dir = new PVector(cos(rotationAngle) * sin(elevationAngle), -cos(elevationAngle), sin(rotationAngle) * sin(elevationAngle));
    setDir(dir);
    
    // http://www.cse.yorku.ca/~amana/research/grid.pdf
    hit = null;
    PVector cam = getPos().copy().add(new PVector(0, -1*blockSize, 0)).add(dir.copy().mult(headRadius));
    float x = cam.x/blockSize, y = cam.y/blockSize, z = cam.z/blockSize;
    float stepX = signum(dir.x), stepY = signum(dir.y), stepZ = signum(dir.z);
    float tMaxX = ((stepX > 0 ? ceil(x+.5) : floor(x+.5))-.5-x)/dir.x;
    float tMaxY = ((stepY > 0 ? ceil(y+.5) : floor(y+.5))-.5-y)/dir.y;
    float tMaxZ = ((stepZ > 0 ? ceil(z+.5) : floor(z+.5))-.5-z)/dir.z;
    float tDeltaX = 1/abs(dir.x);
    float tDeltaY = 1/abs(dir.y);
    float tDeltaZ = 1/abs(dir.z);
    do {
      preHit = new PVector(x, y, z);
      if(tMaxX < tMaxY) {
        if(tMaxX < tMaxZ) {
          x += stepX;
          if(abs(x - cam.x/20) > reach) break;
          tMaxX= tMaxX + tDeltaX;
        } else {
          z += stepZ;
          if(abs(z - cam.z/20) > reach) break;
          tMaxZ= tMaxZ + tDeltaZ;
        }
      } else {
        if(tMaxY < tMaxZ) {
          y += stepY;
          if(abs(y - cam.y/20) > reach) break;
          tMaxY= tMaxY + tDeltaY;
        } else {
          z += stepZ;
          if(abs(z - cam.z/20) > reach) break;
          tMaxZ= tMaxZ + tDeltaZ;
        }
      }
      Block b = world.getBlock(round(x), round(y), round(z));
      if (b.isSolid()) hit = new PVector(x, y, z);
    } while (hit == null);
    if (hit != null && hit.copy().sub(cam.div(20)).mag() > reach) hit = null;
    
    if (!grounded && getVel().y > 0 && getWorld().getBlock(round(getPos().x/blockSize), round(getPos().y/blockSize)+2, round(getPos().z/blockSize)).isSolid()) grounded = true;
    if (grounded && !getWorld().getBlock(round(getPos().x/blockSize), round(getPos().y/blockSize)+2, round(getPos().z/blockSize)).isSolid()) grounded = false;
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
  public void mousePressed(MouseEvent event) {
    if (hit != null) {
      if (event.getButton() == 37) // left click
        world.setBlock(round(hit.x), round(hit.y), round(hit.z), AIR, 0);
      else if (event.getButton() == 39) { // right click
        world.setBlock(round(preHit.x), round(preHit.y), round(preHit.z), BEDROCK, 0);
      }
    }
  }
}
