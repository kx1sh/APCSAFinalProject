public class Player extends Entity {
  private byte selectedItemIndex;
  private Item[] inventory;
  private boolean[] keyPresses;
  private float mx, my;
  private PVector hit;
  private PVector preHit;
  private boolean grounded;
 
  private float playerSpeed = 7;
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
  public Item[] getInventory() {return inventory;}
  
  @Override
  public void update() {
    boolean inv = world.getInv();
    float rotationAngle = map(mx, 0, width, 0, TWO_PI);
    float elevationAngle = map(my, 0, height, 0+PI/20, PI-PI/20);
    PVector dir = new PVector(cos(rotationAngle) * sin(elevationAngle), -cos(elevationAngle), sin(rotationAngle) * sin(elevationAngle));
    setDir(dir);
    
    // http://www.cse.yorku.ca/~amana/research/grid.pdf
    if (!inv) {
      hit = null;
      PVector cam = getPos().copy().add(new PVector(0, -1*blockSize, 0)).add(dir.copy().mult(headRadius));
      float x = cam.x/blockSize, y = cam.y/blockSize, z = cam.z/blockSize;
      if (world.getBlock(round(x), round(y), round(z)).isSolid()) {
        hit = new PVector(x, y, z);
      } else {
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
              if(abs(x - cam.x/blockSize) > reach) break;
              tMaxX= tMaxX + tDeltaX;
            } else {
              z += stepZ;
              if(abs(z - cam.z/blockSize) > reach) break;
              tMaxZ= tMaxZ + tDeltaZ;
            }
          } else {
            if(tMaxY < tMaxZ) {
              y += stepY;
              if(abs(y - cam.y/blockSize) > reach) break;
              tMaxY= tMaxY + tDeltaY;
            } else {
              z += stepZ;
              if(abs(z - cam.z/blockSize) > reach) break;
              tMaxZ= tMaxZ + tDeltaZ;
            }
          }
          Block b = world.getBlock(round(x), round(y), round(z));
          if (b.isSolid()) hit = new PVector(x, y, z);
        } while (hit == null);
        if (hit != null && hit.copy().sub(cam.div(blockSize)).mag() > reach) hit = null;
      }
    }
    
    if (!grounded && getVel().y > 0 && getWorld().getBlock(round(getPos().x/blockSize), round(getPos().y/blockSize)+2, round(getPos().z/blockSize)).isSolid()) grounded = true;
    if (grounded && !getWorld().getBlock(round(getPos().x/blockSize), round(getPos().y/blockSize)+2, round(getPos().z/blockSize)).isSolid()) grounded = false;
    PVector inDir = new PVector();
    if (!inv) {
      if (keyPresses['w']) inDir.add(new PVector(dir.x, 0, dir.z).normalize().mult(playerSpeed));
      if (keyPresses['a']) inDir.add(new PVector(dir.z, 0, -dir.x).normalize().mult(playerSpeed));
      if (keyPresses['s']) inDir.add(new PVector(-dir.x, 0, -dir.z).normalize().mult(playerSpeed));
      if (keyPresses['d']) inDir.add(new PVector(-dir.z, 0, dir.x).normalize().mult(playerSpeed));
      if (keyPresses[' ']) {
        //inDir.add(new PVector(0, -playerSpeed, 0)); // flying
        if (grounded) setVel(new PVector(0, -blockSize, 0)); // jumping
      }
      if (keyPresses[256 + SHIFT]) inDir.add(new PVector(0, playerSpeed, 0));
    }
    move(inDir.normalize().mult(playerSpeed), true);
  }
  
  public void keyPressed() {
    if (key == CODED) keyPresses[256 + keyCode] = true;
    else keyPresses[key] = true;
    
    if (!getWorld().getInv() && key >= '0' && key <= '9') selectedItemIndex = (byte)((key - '0' + 9) % 10);
    if (key == 'e') world.toggleInv();
  }  
  public void keyReleased() {
    if (key == CODED) keyPresses[256 + keyCode] = false;
    else keyPresses[key] = false;
  }  
  public void mouseWheel(MouseEvent event) {
    if (!getWorld().getInv()) selectedItemIndex = (byte)((selectedItemIndex + event.getCount() + 20) % 10);
  }  
  public void mouseMoved(MouseEvent event) {
    if (!getWorld().getInv()) {
      mx += (event.getX() - width/2) * mouseSensitivity;
      mx %= width;
      my += (event.getY() - height/2) * mouseSensitivity;
      my = constrain(my, 0, height);
      world.getWindow().warpPointer(width/2,height/2);
    }
  }
  public void mousePressed(MouseEvent event) {
    if (!getWorld().getInv() && hit != null) {
      if (event.getButton() == 37) { // left click
        Block b = world.setBlock(round(hit.x), round(hit.y), round(hit.z), AIR, 0);
        if (b.isSolid()) addItem(new Item((byte)1, b.getType()));
      } else if (event.getButton() == 39) { // right click
        Item i = inventory[35 + selectedItemIndex];
        PVector p = getPos(); float x = p.x, y = p.y, z = p.z;
        if (!(round(x/blockSize) == round(preHit.x) && round(z/blockSize) == round(preHit.z) && (round(y/blockSize) == round(preHit.y) || round(y/blockSize)-1 == round(preHit.y))) &&
          i != null && i.getType() != I_STICK) {
          world.setBlock(round(preHit.x), round(preHit.y), round(preHit.z), i.getType(), 0);
          i.setCount((byte)(i.getCount() - 1));
          if (i.getCount() == 0) {print(0); inventory[35 + selectedItemIndex] = null;}
        }
      }
    }
  }
  public Item addItem(Item item) {
    int firstEmpty = -1;
    int i = 35;
    do { // main inventory bar
      Item it = inventory[i];
      if (firstEmpty == -1 && it == null) firstEmpty = i;
      if (it != null && it.getCount() == 64) {i = i == 44 ? 5 : i+1; continue;}
      if (it != null && it.getType() == item.getType()) {
        int total = it.getCount() + item.getCount();
        if (total > 64) {
          inventory[i].setCount((byte)64);
          item.setCount((byte)(total - 64));
          return addItem(item);
        }
        inventory[i].setCount((byte)total);
        return null;
      }
      i = i == 44 ? 5 : i+1;
    } while (i != 35);
    
    i = 35;
    do {
      Item it = inventory[i];
      if (it == null) {
        inventory[i] = item;
        return null;
      }
      i = i == 44 ? 5 : i+1;
    } while (i != 35);
    return item;
  }
}
