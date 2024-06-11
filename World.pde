import com.jogamp.newt.opengl.GLWindow;
import static java.lang.Math.*;

public class World {
  private HashMap<PVector, Block[][][]> chunks = new HashMap<>();
  private Entity[] entities; // limited amount of entities
  private PGraphics pg;
  private Player player;
  private long seed;
  private int tick;
  private GLWindow window;
  private boolean inv;
  
  private static final int loadChunks = 1, chunkSize = 16;
  private static final int chunkHeight = 256, generationHeight = 10, waterHeight = 9, baseHeight = 2, treeBaseHeight = 5;
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
    player = new Player(10, new PVector(), new PVector(0, -500, 0), new PVector(), this);
    seed = (long)random(1 << 63);
    tick = 0;
    inv = false;
    
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
    pg.textSize(40);
    for (int i = 0, ind = 0; i < width/15*10; i += width/15, ind++) {
      Item it = player.inventory[ind + 35];
      if (it != null) {
        pg.text(it.getType(), (width - width/15*20/2)/2 + i + 10, height - width/15*7/6 + 40);
        if (it.getCount() >= 2) {
          textAlign(RIGHT);
          pg.text(it.getCount(), (width - width/15*20/2)/2 + i + width/15 - 45, height - width/15*7/6 + width/15 - 10);
          textAlign(LEFT);
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
    pg.fill(0, 128);
    pg.noStroke();
    pg.rect(0, 0, width, height);
    pg.fill(160, 160, 150);
    pg.rect(200, 50, width-400, height-100);
  }
}
