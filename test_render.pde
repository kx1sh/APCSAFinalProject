// chunks aren't aligned and shake when camera rotates
// chunks load at wrong position

HashMap<PVector, int[][][]> blocks = new HashMap<>();
PVector cam;
PVector center = new PVector();
long seed;

public void setup() {
  size(640*3, 360*3, P3D);
  //noStroke();
  float cameraZ = ((height/2.0) / tan(PI*60.0/360.0));
  perspective(PI/3.0, (float)width/height, 1e-2, cameraZ*10.0);
  cam = new PVector(0, -500, 0);
  seed = (long)random(1 << 63);
}

public void draw() {
  background(0, 180, 216);
  //lights();
  ambientLight(100, 100, 128);
  directionalLight(0, 180, 216, 0, 1, 0);
  lightFalloff(1.0, 0.0, 0.0);
  lightSpecular(255, 255, 255);

  // https://gamedev.stackexchange.com/questions/68008/processing-implement-a-first-person-camera
  float rotationAngle = map(mouseX, 0, width, 0+PI/10, TWO_PI);
  float elevationAngle = map(mouseY, 0, height, 0, PI);
  center.x = cos(rotationAngle) * sin(elevationAngle);
  center.y = -cos(elevationAngle);
  center.z = sin(rotationAngle) * sin(elevationAngle);
  camera(cam.x, cam.y, cam.z, cam.x+center.x, cam.y+center.y, cam.z+center.z, 0, 1, 0);

  long ccx = (long)((cam.x/20+8) / 16) * 16;
  long ccz = (long)((cam.z/20+8) / 16) * 16;
  translate(ccx*20-20*16/2, 0, ccz*20-20*16/2);
  for (long cx = ccx - 16; cx <= ccx + 16; cx += 16) {
	for (long cz = ccz - 16; cz <= ccz + 16; cz += 16) {
  	PVector k = new PVector(cx, cz);
  	if (!blocks.containsKey(k)) generateChunk(cx, cz);
  	int[][][] chunk = blocks.get(k);
  	for (int i = 0; i < 16; i++) {
    	for (int j = 0; j < 16; j++) {
      	fill(color(25, 200, 16));
      	for (int h = 0; h < 256; h++) {
        	if (chunk[h][i][j] != 0) box(20);
        	translate(0, -20, 0);
      	}
      	translate(0, 256*20, 20);
    	}
    	translate(20, 0, -20*16);
  	}
  	translate(-20*16, 0, 16*20);
	}
	translate(16*20, 0, 3*-16*20);
  }
 
  if (keyPressed) {
	switch (key) {
  	case 'w':
    	cam.add(new PVector(center.x, 0, center.z).normalize().mult(15));
    	break;
  	case 'a':
    	cam.add(new PVector(center.z, 0, -center.x).normalize().mult(5));
    	break;
  	case 's':
    	cam.add(new PVector(-center.x, 0, -center.z).normalize().mult(5));
    	break;
  	case 'd':
    	cam.add(new PVector(-center.z, 0, center.x).normalize().mult(5));
    	break;
  	case ' ':
    	cam.add(new PVector(0, -5, 0));
    	break;
  	case CODED:
    	if (keyCode == SHIFT) cam.add(new PVector(0, 5, 0));
    	break;
	}
  }
}

private void generateChunk(long x, long z) {
  float[][] m = new float[16][16];
  noiseSeed(seed);
  for (float i = 1; i >= 1./16; i /= 2) {
	for (int j = 0; j < 16; j++) for (int k = 0; k < 16; k++) {
  	m[j][k] += noise((x+j) / i / 50, (z+k) / i / 50) * i * 10;
	}
  }
 
  int[][][] chunk = new int[256][16][16];
  for (int j = 0; j < 16; j++) for (int k = 0; k < 16; k++) {
	int h = round(m[j][k]);
	for (int i = 0; i < h; i++) {
  	chunk[i][j][k] = 1;
	}
  }
  blocks.put(new PVector(x, z), chunk);
}
