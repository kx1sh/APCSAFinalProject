import com.jogamp.newt.opengl.GLWindow;

private HashMap<PVector, int[][][]> chunks = new HashMap<>();
public PVector cam;
public PVector center = new PVector();
public long seed;
public PVector vel;
private PGraphics pg;
private boolean[] keyPresses;
public int tick;
public int selectedItemIndex;
public int[] inventory;
private float mx, my;
private GLWindow r;

private static final int loadChunks = 2, chunkSize = 16;
private static final int chunkHeight = 256, generationHeight = 1, waterHeight = 0;
private static final float playerSpeed = 15;
private static final int AIR=0, GRASS=1, BEDROCK=2, WATER=3, OAK_WOOD = 4;
private final int NOON=color(119, 186, 231), MIDNIGHT=color(10, 20, 50), RED_SKY=color(255, 176, 133);
private static final int dayLength = 2400;

public void setup() {
  size(640*2, 360*2, P3D);
  noStroke();
  smooth();
  float cameraZ = ((height/2.0) / tan(PI*60.0/360.0));
  perspective(PI/3.0, (float)width/height, 1e-2, cameraZ*10.0);
  cam = new PVector(0, -500, 0);
  seed = (long)random(1 << 63);
  vel = new PVector(0, 0, 0);
  keyPresses = new boolean[512];
  tick = 0;
  selectedItemIndex = 0;
  
  // https://twicetwo.com/blog/processing/2016/03/01/processing-locking-the-mouse.html
  r = (GLWindow)surface.getNative();
  r.confinePointer(true);
  //r.setPointerVisible(false);
  r.warpPointer(width/2,height/2);
  mx = mouseX; my = mouseY;
}

public void draw() {
  float sunHeight = cos(tick * TWO_PI / dayLength);
  int skyColor = 
    sunHeight >= 0 ? lerpColor(RED_SKY, NOON, sunHeight) :
    lerpColor(RED_SKY, MIDNIGHT, -sunHeight);
  
  background(skyColor);
  pushMatrix();

  // https://gamedev.stackexchange.com/questions/68008/processing-implement-a-first-person-camera
  float rotationAngle = map(mx, 0, width, 0, TWO_PI);
  float elevationAngle = map(my, 0, height, 0+PI/10, PI-PI/10);
  center.x = cos(rotationAngle) * sin(elevationAngle);
  center.y = -cos(elevationAngle);
  center.z = sin(rotationAngle) * sin(elevationAngle);
  camera(cam.x, cam.y, cam.z, cam.x+center.x, cam.y+center.y, cam.z+center.z, 0, 1, 0);
  
  ambientLight(100, 100, 128);
  directionalLight(red(skyColor), green(skyColor), blue(skyColor), 0, 1, 0);
  lightFalloff(1.0, 0.0, 0.0);
  lightSpecular(255, 255, 255);
  
  float tx = cam.x/20 + chunkSize/2, tz = cam.z/20 + chunkSize/2;
  long ccx = (long)((tx >= 0 ? tx : tx - chunkSize + 1) / chunkSize) * chunkSize;
  long ccz = (long)((tz >= 0 ? tz : tz - chunkSize + 1) / chunkSize) * chunkSize;
  translate(ccx*20 - chunkSize*(20*loadChunks+20/2), 0, ccz*20 - chunkSize*(20*loadChunks+20/2));
  for (long cx = ccx - chunkSize*loadChunks; cx <= ccx + chunkSize*loadChunks; cx += chunkSize) {
    pushMatrix();
    for (long cz = ccz - chunkSize*loadChunks; cz <= ccz + chunkSize*loadChunks; cz += chunkSize) {
      PVector k = new PVector(cx, cz);
      if (!chunks.containsKey(k)) generateChunk(cx, cz);
      int[][][] chunk = chunks.get(k);
      pushMatrix();
      for (int i = 0; i < chunkSize; i++) {
        pushMatrix();
        for (int j = 0; j < chunkSize; j++) {
          pushMatrix();
          for (int h = 0; h < chunkHeight; h++) {
            int b = chunk[h][i][j];
            if (b != AIR) {
              fill(
                b == GRASS ? color(25+100+cx*3, 200+cz*2, chunkSize) :
                b == BEDROCK ? color(100) :
                b == WATER ? color(0, 100, 150) :
                color(180, 150, 0),
                b == WATER ? 200 : 255
              );
              if (b == WATER) {
                pushMatrix();
                rotateX(-PI/2);
                rect(-10, -10, 20, 20);
                popMatrix();
              } else box(20);
            }
            translate(0, -20, 0);
          }
          popMatrix();
          translate(0, 0, 20);
        }
        popMatrix();
        translate(20, 0, 0);
      }
      popMatrix();
      translate(0, 0, chunkSize*20);
    }
    popMatrix();
    translate(chunkSize*20, 0, 0);
  }
  
  boolean grounded = isSolid(getBlock((int)(cam.x/20), (int)(cam.y/20)+2, (int)(cam.z/20)));
  PVector orig = cam.copy();
  if (keyPresses['w']) cam.add(new PVector(center.x, 0, center.z).normalize().mult(playerSpeed));
  if (keyPresses['a']) cam.add(new PVector(center.z, 0, -center.x).normalize().mult(playerSpeed));
  if (keyPresses['s']) cam.add(new PVector(-center.x, 0, -center.z).normalize().mult(playerSpeed));
  if (keyPresses['d']) cam.add(new PVector(-center.z, 0, center.x).normalize().mult(playerSpeed));
  if (keyPresses[' ']) {
    //cam.add(new PVector(0, -playerSpeed, 0)); // flying
    if (grounded) vel = new PVector(0, -20, 0); // jumping
  }
  if (keyPresses[256 + SHIFT]) cam.add(new PVector(0, playerSpeed, 0));
  if (isSolid(getBlock((int)(cam.x/20), (int)(cam.y/20), (int)(cam.z/20))) ||
      isSolid(getBlock((int)(cam.x/20), (int)(cam.y/20)+1, (int)(cam.z/20)))) {
    cam = orig.copy();
    vel = new PVector(0, 0, 0);
  }
  orig = cam.copy();
  vel.add(new PVector(0, 5, 0));
  vel.limit(20);
  cam.add(vel);
  if (isSolid(getBlock((int)(cam.x/20), (int)(cam.y/20), (int)(cam.z/20))) ||
      isSolid(getBlock((int)(cam.x/20), (int)(cam.y/20)+1, (int)(cam.z/20)))) {
    cam = orig.copy();
    vel = new PVector(0, 0, 0);
  }
  
  popMatrix();
  hint(DISABLE_DEPTH_TEST);
  noLights();
  pg = createGraphics(width, height);
  pg.beginDraw();
  //fill(255);
  pg.textSize(20);
  pg.text(frameRate + " FPS", 10, 20);
  pg.text((long)(cam.x/20) + " " + (long)(-cam.y/20) + " " + (long)(cam.z/20), 10, 40);
  pg.text(frameRate + " FPS", 10, 20);
  pg.fill(0, 64);
  pg.stroke(color(200));
  pg.strokeWeight(8);
  for (int i = 0, ind = 0; i < width/15*10; i += width/15, ind++) {
    if (ind != selectedItemIndex) pg.rect((width - width/15*19/2)/2 + i, height - width/15*7/6, width/15, width/15);
  }
  pg.stroke(color(255));
  pg.strokeWeight(10);
  pg.rect((width - width/15*19/2)/2 + width/15*selectedItemIndex, height - width/15*7/6, width/15, width/15);
  pg.endDraw();
  image(pg, 0, 0); 
  hint(ENABLE_DEPTH_TEST);
  
  tick = (tick + 1) % dayLength;
}

public void mouseMoved(MouseEvent event) {
  mx += event.getX() - width/2;
  mx %= width;
  my += event.getY() - height/2;
  my = constrain(my, 0, height);
  r.warpPointer(width/2,height/2);
}

private void generateChunk(long x, long z) {
  float[][] m = new float[chunkSize][chunkSize];
  noiseSeed(seed);
  for (float i = 1; i >= 1./chunkSize; i /= 2) {
    for (int j = 0; j < chunkSize; j++) for (int k = 0; k < chunkSize; k++) {
      m[j][k] += noise((x+j) / i / 50, (z+k) / i / 50) * i * generationHeight;
    }
  }
 
  int[][][] chunk = new int[chunkHeight][chunkSize][chunkSize];
  for (int j = 0; j < chunkSize; j++) for (int k = 0; k < chunkSize; k++) {
    int h = round(m[j][k]);
    for (int i = 0; i < h; i++) {
      chunk[i][j][k] = i == 0 ? BEDROCK : GRASS;
    }
    for (int i = 1; i < waterHeight; i++) {
      if (chunk[i][j][k] == AIR) chunk[i][j][k] = WATER;
    }
    
    if (round(m[j][k]) >= waterHeight && noise((x+j), (z+k)) > .85) {
      for (int i = round(m[j][k]); i < round(m[j][k]) + 3 + (int)random(3); i++) {
        chunk[i][j][k] = OAK_WOOD;
      }
    }
  }
  
  chunks.put(new PVector(x, z), chunk);
}

public int getBlock(long x, long y, long z) {
  if (y > 0) return 0;
  long tx = x + chunkSize/2, tz = z + chunkSize/2;
  long cx = (long)((tx >= 0 ? tx : tx - chunkSize + 1) / chunkSize) * chunkSize;
  long cz = (long)((tz >= 0 ? tz : tz - chunkSize + 1) / chunkSize) * chunkSize; 
  var c = chunks.get(new PVector(cx, cz));
  return c[(int)-y][(int)(tx - cx)][(int)(tz - cz)];
}

public void keyPressed() {
  if (key == CODED) keyPresses[256 + keyCode] = true;
  else keyPresses[key] = true;
  
  if (key >= '0' && key <= '9') selectedItemIndex = (key - '0' + 9) % 10;
}

public void keyReleased() {
  if (key == CODED) keyPresses[256 + keyCode] = false;
  else keyPresses[key] = false;
}

public static boolean isSolid(int block) {
  return block != AIR && block != WATER;
}

public void mouseWheel(MouseEvent event) {
  selectedItemIndex = (selectedItemIndex + event.getCount() + 20) % 10;
}
