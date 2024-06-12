import com.jogamp.newt.opengl.GLWindow;
import static java.lang.Math.*;

public class World {
  private HashMap<PVector, Block[][][]> chunks = new HashMap<>();
  //private Entity[] entities; // limited amount of entities
  private PGraphics pg;
  private Player player;
  private long seed;
  private int tick;
  private GLWindow window;
  private boolean inv;
  private int invSelect;
  
  private static final int loadChunks = 1, chunkSize = 16;
  private static final int chunkHeight = 30, generationHeight = 10, waterHeight = 9, baseHeight = 2, treeBaseHeight = 5;
  private final int NOON=color(119, 186, 231), MIDNIGHT=color(10, 20, 50), RED_SKY=color(255, 176, 133);
  private static final int dayLength = 2400;
  
  public Player getPlayer() {return player;}
  public GLWindow getWindow() {return window;}
  public boolean getInv() {return inv;}
  public void toggleInv() {
    inv = !inv;
    if (inv) window.setPointerVisible(true);
    else {
      window.setPointerVisible(false);
      window.warpPointer(width/2,height/2);
    }
  }
  
  public World() {
    noStroke();
    smooth();
    float cameraZ = ((height/2.0) / tan(PI*60.0/360.0));
    perspective(PI/3.0, (float)width/height, 1e-2, cameraZ*10.0);
    player = new Player(10, new PVector(), new PVector(0, -300, 0), new PVector(), this);
    seed = (long)random(1 << 63);
    tick = 0;
    inv = false;
    invSelect = -1;
    
    // https://twicetwo.com/blog/processing/2016/03/01/processing-locking-the-mouse.html
    window = (GLWindow)surface.getNative();
    window.confinePointer(true);
    window.setPointerVisible(false);
    window.warpPointer(width/2,height/2);
  }
  
  public void draw() {
    float sunHeight = cos(tick * TWO_PI / dayLength);
    int skyColor = 
      sunHeight >= 0 ? lerpColor(RED_SKY, NOON, sunHeight) :
      lerpColor(RED_SKY, MIDNIGHT, -sunHeight);
    
    background(skyColor);
    pushMatrix();
    
    // https://gamedev.stackexchange.com/questions/68008/processing-implement-a-first-person-camera
    player.update();
    PVector hit = player.getHit();
    PVector dir = player.getDir();
    PVector cam = player.getPos().copy().add(new PVector(0, -1*blockSize, 0)).add(dir.copy().mult(5));
    camera(cam.x, cam.y, cam.z, cam.x+dir.x, cam.y+dir.y, cam.z+dir.z, 0, 1, 0);
    
    ambientLight(100, 100, 128);
    PVector sunlightDir = new PVector(0, 1).rotate(tick * TWO_PI / dayLength);
    directionalLight(red(skyColor), green(skyColor), blue(skyColor), sunlightDir.x, sunlightDir.y, 0);
    lightFalloff(1.0, 0.0, 0.0);
    lightSpecular(255, 255, 255);
    
    float tx = cam.x/blockSize + chunkSize/2, tz = cam.z/blockSize + chunkSize/2;
    long ccx = (long)((tx >= 0 ? tx : tx - chunkSize + 1) / chunkSize) * chunkSize;
    long ccz = (long)((tz >= 0 ? tz : tz - chunkSize + 1) / chunkSize) * chunkSize;
    translate(ccx*blockSize - chunkSize*(blockSize*loadChunks+blockSize/2), 0, ccz*blockSize - chunkSize*(blockSize*loadChunks+blockSize/2));
    for (long cx = ccx - chunkSize*loadChunks; cx <= ccx + chunkSize*loadChunks; cx += chunkSize) {
      pushMatrix();
      for (long cz = ccz - chunkSize*loadChunks; cz <= ccz + chunkSize*loadChunks; cz += chunkSize) {
        PVector k = new PVector(cx, cz);
        if (!chunks.containsKey(k)) generateChunk(cx, cz);
        Block[][][] chunk = chunks.get(k);
        pushMatrix();
        for (int i = 0; i < chunkSize; i++) {
          pushMatrix();
          for (int j = 0; j < chunkSize; j++) {
            pushMatrix();
            for (int h = 0; h < chunkHeight; h++) {
              Block b = chunk[h][i][j];
              if (b.getType() != AIR) {
                boolean isHit = false;
                float mag = 0;
                if (hit != null) {
                  mag = new PVector(cx + i - chunkSize/2, -h, cz + j - chunkSize/2).sub(new PVector(round(hit.x), round(hit.y), round(hit.z))).mag();
                  isHit = mag < 1;
                  if (isHit) {stroke(0); strokeWeight(1);}
                }
                fill(
                  C[b.getType()],
                  b.getType() == WATER ? 200 : 255
                );
                if (b.getType() == WATER) {
                  pushMatrix();
                  rotateX(-HALF_PI);
                  rect(-blockSize/2, -blockSize/2, blockSize, blockSize);
                  popMatrix();
                } else box(blockSize);
                if (isHit) noStroke();
              }
              translate(0, -blockSize, 0);
            }
            popMatrix();
            translate(0, 0, blockSize);
          }
          popMatrix();
          translate(blockSize, 0, 0);
        }
        popMatrix();
        translate(0, 0, chunkSize*blockSize);
      }
      popMatrix();
      translate(chunkSize*blockSize, 0, 0);
    }
    
    popMatrix();
    hint(DISABLE_DEPTH_TEST);
    noLights();
    pg = createGraphics(width, height);
    pg.beginDraw();
    //fill(255);
    pg.textSize(20);
    pg.text(frameRate + " FPS", 10, 20);
    pg.text(round(cam.x/blockSize) + " " + round(-cam.y/blockSize) + " " + round(cam.z/blockSize), 10, 40);
    pg.text(tick, 10, 60);
    pg.fill(0, 64);
    pg.stroke(color(200));
    pg.strokeWeight(8);
    int sel = player.getSelectedItemIndex();
    for (int i = 0, ind = 0; i < width/15*10; i += width/15, ind++) {
      if (ind != sel) pg.rect((width - width/15*20/2)/2 + i, height - width/15*7/6, width/15, width/15);
    }
    pg.stroke(color(255));
    pg.strokeWeight(10);
    pg.rect((width - width/15*20/2)/2 + width/15*sel, height - width/15*7/6, width/15, width/15);
    pg.fill(255);
    pg.textSize(30);
    for (int i = 0, ind = 0; i < width/15*10; i += width/15, ind++) {
      Item it = player.inventory[ind + 35];
      if (it != null) {
        pg.image(imageItems[it.getType()], (width - width/15*20/2)/2 + i + 10, height - width/15*7/6 + 10);
        if (it.getCount() >= 2) {
          pg.textAlign(RIGHT);
          pg.text(it.getCount(), (width - width/15*20/2)/2 + i + width/15 - 10, height - width/15*7/6 + width/15 - 10);
          pg.textAlign(LEFT);
        }
      }
    }
    pg.stroke(255,0,0);
    pg.strokeWeight(1.3);
    pg.line(width/2, (height-30)/2, width/2, (height+30)/2);
    pg.line((width-30)/2, height/2, (width+30)/2, height/2);
    pg.noStroke();
    if (inv) showInventory(pg);
    pg.endDraw();
    image(pg, 0, 0); 
    hint(ENABLE_DEPTH_TEST);
    
    tick = (tick + 1) % dayLength;
  }
  
  private void generateChunk(long x, long z) {
    float[][] m = new float[chunkSize][chunkSize];
    noiseSeed(seed);
    for (float i = 1; i >= 1./chunkSize; i /= 2) {
      for (int j = 0; j < chunkSize; j++) for (int k = 0; k < chunkSize; k++) {
        m[j][k] += noise((x+j) / i / 50, (z+k) / i / 50) * i * generationHeight;
      }
    }
   
    Block[][][] chunk = new Block[chunkHeight][chunkSize][chunkSize];
    for (int j = 0; j < chunkSize; j++) for (int k = 0; k < chunkSize; k++) {
      int h = round(m[j][k]) + baseHeight;
      for (int i = 0; i < chunkHeight; i++) {
        chunk[i][j][k] = new Block(i >= h ? AIR : i == 0 ? BEDROCK : i == h-1 ? GRASS : DIRT, new PVector(x+j-8 , -i, z+k-8), this);
      }
      for (int i = 1; i < waterHeight; i++) {
        if (chunk[i][j][k].getType() == AIR) chunk[i][j][k] = new Block(WATER, new PVector(x+j-8, -i, z+k-8), this);
      }
      
      if (round(m[j][k]) >= waterHeight && noise((x+j), (z+k)) > .85) {
        for (int i = round(m[j][k]) + baseHeight; i < round(m[j][k]) + baseHeight + treeBaseHeight + (int)random(3); i++) {
          chunk[i][j][k] = new Block(OAK_WOOD, new PVector(x+j-8, -i, z+k-8), this);
        }
      }
    }
    
    chunks.put(new PVector(x, z), chunk);
  }
  public Block getBlock(long x, long y, long z) {
    if (y > 0) return new Block(AIR, new PVector(x, y, z), this);
    long tx = x + chunkSize/2, tz = z + chunkSize/2;
    long cx = (long)((tx >= 0 ? tx : tx - chunkSize + 1) / chunkSize) * chunkSize;
    long cz = (long)((tz >= 0 ? tz : tz - chunkSize + 1) / chunkSize) * chunkSize; 
    var c = chunks.get(new PVector(cx, cz));
    if (c == null) return new Block(AIR, new PVector(x, y, z), this);
    return c[(int)-y][(int)(tx - cx)][(int)(tz - cz)];
  }
  public Block setBlock(long x, long y, long z, int type, int state) {
    if (y > 0) return null;
    long tx = x + chunkSize/2, tz = z + chunkSize/2;
    long cx = (long)((tx >= 0 ? tx : tx - chunkSize + 1) / chunkSize) * chunkSize;
    long cz = (long)((tz >= 0 ? tz : tz - chunkSize + 1) / chunkSize) * chunkSize; 
    var c = chunks.get(new PVector(cx, cz));
    if (c == null) return null;
    Block b = c[(int)-y][(int)(tx - cx)][(int)(tz - cz)];
    c[(int)-y][(int)(tx - cx)][(int)(tz - cz)] = new Block(type, state, new PVector(x, y, z), this);
    return b;
  }
  
  public void showInventory(PGraphics pg) {
    // no way to merge items
    pg.fill(0, 150);
    pg.noStroke();
    pg.rect(0, 0, width, height);
    pg.fill(160, 160, 150);
    pg.rect(200, 50, width-400, height-100);
    Item[] inventory = getPlayer().getInventory();
    
    pg.fill(0, 64);
    pg.stroke(color(200));
    pg.strokeWeight(8);
    for (int i = 0; i < 40; i++) {
      Item it = inventory[i+5];
      if (mousePressed && mouseOn(i%10*80 + 200 + 40, i/10*80 + 50 + 260)) {
        if (invSelect == -1 && it != null) invSelect = i+5; // select
        else if (invSelect != -1) {
          Item s = inventory[invSelect];
          if (mouseButton == LEFT || it != null) { // swap
            if (mouseButton == LEFT || invSelect != 0) {
              inventory[i+5] = s;
              inventory[invSelect] = it;
              if (invSelect == 0) useInputs();
              if (invSelect < 5) craftRes();
              invSelect = -1;
            }
          } else if (invSelect != 0) { // split
            inventory[i+5] = new Item((byte)((s.getCount()+1)/2), s.getType());
            s.setCount((byte)(s.getCount()/2));
            if (s.getCount() == 0) inventory[invSelect] = null;
            if (invSelect < 5) craftRes();
            invSelect = -1;
          }
        }
      }
      if (i+5 == invSelect) {pg.stroke(color(255)); pg.strokeWeight(10);}
      pg.rect(i%10*80 + 200 + 40, i/10*80 + 50 + 260, 80, 80);
      if (it != null) {
        pg.image(imageItems[it.getType()], i%10*80 + 200 + 40 + 10, i/10*80 + 50 + 260 + 10);
        if (it.getCount() > 1) {
          pg.fill(255);
          pg.textAlign(RIGHT);
          pg.text(it.getCount(), i%10*80 + 200 + 40 + 70, i/10*80 + 50 + 260 + 70);
          pg.textAlign(LEFT);
          pg.fill(0, 64);
        }
      }
      if (i+5 == invSelect) {pg.stroke(color(200)); pg.strokeWeight(8);}
    }
    for (int i = 0; i < 4; i++) {
      Item it = inventory[i+1];
      if (mousePressed && mouseOn(i%2*80 + 200 + 40 + 80*6, i/2*80 + 50 + 40)) {
        if (invSelect == -1 && it != null) invSelect = i+1; // select
        else if (invSelect != -1) {
          Item s = inventory[invSelect];
          if (mouseButton == LEFT || it != null) { // swap
            if (mouseButton == LEFT || invSelect != 0) {
              if (invSelect == 0) useInputs();
              inventory[i+1] = s;
              inventory[invSelect] = it;
              invSelect = -1;
            }
          } else if (invSelect != 0) { // split
            inventory[i+1] = new Item((byte)((s.getCount()+1)/2), s.getType());
            s.setCount((byte)(s.getCount()/2));
            if (s.getCount() == 0) inventory[invSelect] = null;
            invSelect = -1;
          }
        }
        craftRes();
      }
      if (i+1 == invSelect) {pg.stroke(color(255)); pg.strokeWeight(10);}
      pg.rect(i%2*80 + 200 + 40 + 80*6, i/2*80 + 50 + 40, 80, 80);
      if (it != null) {
        pg.image(imageItems[it.getType()], i%2*80 + 200 + 40 + 80*6 + 10, i/2*80 + 50 + 40 + 10);
        if (it.getCount() > 1) {
          pg.fill(255);
          pg.textAlign(RIGHT);
          pg.text(it.getCount(), i%2*80 + 200 + 40 + 80*6 + 70, i/2*80 + 50 + 40 + 70);
          pg.textAlign(LEFT);
          pg.fill(0, 64);
        }
      }
      if (i+1 == invSelect) {pg.stroke(color(200)); pg.strokeWeight(8);}
    }
    Item it = inventory[0];
    if (mousePressed && mouseOn(200 + 40 + 80*9, 50 + 40 + 40)) {
      if (invSelect == 0) invSelect = -1;
      else if (invSelect == -1 && it != null) invSelect = 0; // select
    }
    if (0 == invSelect) {pg.stroke(color(255)); pg.strokeWeight(10);}
    pg.rect(200 + 40 + 80*9, 50 + 40 + 40, 80, 80);
    if (it != null) {
      pg.image(imageItems[it.getType()], 200 + 40 + 80*9 + 10, 50 + 40 + 40 + 10);
      if (it.getCount() > 1) {
        pg.fill(255);
        pg.textAlign(RIGHT);
        pg.text(it.getCount(), 200 + 40 + 80*9 + 70, 50 + 40 + 40 + 70);
        pg.textAlign(LEFT);
        pg.fill(0, 64);
      }
    }
    pg.fill(255);
    pg.textAlign(CENTER, CENTER);
    pg.text("→", 200 + 40 + 80*8 + 40, 50 + 40 + 80);
    pg.textAlign(LEFT, BOTTOM);
  }
  private boolean mouseOn(float x, float y) {
    return mouseX >= x && mouseY >= y && mouseX - x < 80 && mouseY - y < 80;
  }
  private void craftRes() {
    Item[] inventory = getPlayer().getInventory();
    inventory[0] = null;
    if (inventory[1] != null && inventory[1].getType() == I_OAK_WOOD && inventory[2] == null && inventory[3] == null && inventory[4] == null) {
      inventory[0] = new Item((byte)4, I_OAK_WOOD_PLANKS);
    } else if (inventory[1] != null && inventory[1].getType() == I_OAK_WOOD_PLANKS && inventory[3] != null && inventory[3].getType() == I_OAK_WOOD_PLANKS && inventory[2] == null && inventory[4] == null) {
      inventory[0] = new Item((byte)4, I_STICK);
    }
  }
  private void useInputs() {
    Item[] inventory = getPlayer().getInventory();
    for (int i = 1; i < 5; i++) {
      if (inventory[i] != null) {
        inventory[i].setCount((byte)(inventory[i].getCount() - 1));
        if (inventory[i].getCount() == 0) inventory[i] = null;
      }
    }
  }
}
