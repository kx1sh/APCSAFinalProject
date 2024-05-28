// collision can be weird

private HashMap<PVector, int[][][]> chunks = new HashMap<>();
public PVector cam;
public PVector center = new PVector();
public long seed;
private static final int loadChunks = 1;
private static final int chunkSize = 16;
private static final int chunkHeight = 256;
private static final float playerSpeed = 5;
private PGraphics pg;
private static final int AIR=0, GRASS=1, BEDROCK=2, WATER=3;

public void setup() {
  size(640*2, 360*2, P3D);
  noStroke();
  float cameraZ = ((height/2.0) / tan(PI*60.0/360.0));
  perspective(PI/3.0, (float)width/height, 1e-2, cameraZ*10.0);
  cam = new PVector(0, -500, 0);
  seed = (long)random(1 << 63);
}

public void draw() {
  background(0, 180, 216);
  pushMatrix();

  // https://gamedev.stackexchange.com/questions/68008/processing-implement-a-first-person-camera
  float rotationAngle = map(constrain(mouseX, 0, width), 0, width, 0, TWO_PI);
  float elevationAngle = map(constrain(mouseY, 0, height), 0, height, 0+PI/10, PI-PI/10);
  center.x = cos(rotationAngle) * sin(elevationAngle);
  center.y = -cos(elevationAngle);
  center.z = sin(rotationAngle) * sin(elevationAngle);
  camera(cam.x, cam.y, cam.z, cam.x+center.x, cam.y+center.y, cam.z+center.z, 0, 1, 0);
  
  ambientLight(100, 100, 128);
  directionalLight(0, 180, 216, 0, 1, 0);
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
                color(0, 100, 150),
                b == WATER ? 100 : 255
              );
              if (b == WATER) {
                rotateX(-PI/2);
                rect(-10, -10, 20, 20);
                rotateX(PI/2);
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
 
  if (keyPressed) {
    PVector orig = cam.copy();
    switch (key) {
      case 'w':
        cam.add(new PVector(center.x, 0, center.z).normalize().mult(playerSpeed));
        break;
      case 'a':
        cam.add(new PVector(center.z, 0, -center.x).normalize().mult(playerSpeed));
        break;
      case 's':
        cam.add(new PVector(-center.x, 0, -center.z).normalize().mult(playerSpeed));
        break;
      case 'd':
        cam.add(new PVector(-center.z, 0, center.x).normalize().mult(playerSpeed));
        break;
      case ' ':
        cam.add(new PVector(0, -playerSpeed, 0));
        break;
      case CODED:
        if (keyCode == SHIFT) cam.add(new PVector(0, playerSpeed, 0));
        break;
    }
    if (getBlock((int)(cam.x/20), (int)(cam.y/20), (int)(cam.z/20)) == GRASS ||
        getBlock((int)(cam.x/20), (int)(cam.y/20)+1, (int)(cam.z/20)) == GRASS) cam = orig.copy();
  }
  
  popMatrix();
  hint(DISABLE_DEPTH_TEST);
  noLights();
  pg = createGraphics(1000, 100);
  pg.beginDraw();
  fill(255);
  pg.textSize(50);
  pg.text(frameRate + " FPS", 10, 50);
  pg.text((long)(cam.x/20) + " " + (long)(-cam.y/20) + " " + (long)(cam.z/20), 10, 100);
  pg.endDraw();
  image(pg, 0, 0); 
  hint(ENABLE_DEPTH_TEST);
}

private void generateChunk(long x, long z) {
  float[][] m = new float[chunkSize][chunkSize];
  noiseSeed(seed);
  for (float i = 1; i >= 1./chunkSize; i /= 2) {
    for (int j = 0; j < chunkSize; j++) for (int k = 0; k < chunkSize; k++) {
      m[j][k] += noise((x+j) / i / 50, (z+k) / i / 50) * i * 10;
    }
  }
 
  int[][][] chunk = new int[chunkHeight][chunkSize][chunkSize];
  for (int j = 0; j < chunkSize; j++) for (int k = 0; k < chunkSize; k++) {
    int h = round(m[j][k]);
    for (int i = 0; i < h; i++) {
      chunk[i][j][k] = i == 0 ? BEDROCK : GRASS;
    }
    for (int i = 1; i < 9; i++) {
      if (chunk[i][j][k] == AIR) chunk[i][j][k] = WATER;
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
