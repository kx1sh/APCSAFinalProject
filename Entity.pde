public class Entity {
  private float hp;
  private PVector dir, pos, vel;
  private World world;
  
  private static final float terminalVel = 20;
  
  public Entity(float h, PVector d, PVector p, PVector v, World w) {
    hp = h; dir = d; pos = p; vel = v; world = w;
  }
  
  public float getHp() {return hp;}
  public PVector getDir() {return dir;}
  public PVector getPos() {return pos;}
  public PVector getVel() {return vel;}
  public World getWorld() {return world;}
  
  public void setHp(float h) {hp = h;}
  public void setDir(PVector d) {dir = d;}
  public void setPos(PVector p) {pos = p;}
  public void setVel(PVector v) {vel = v;}
  
  public void update() {
  
  }
  
  public void move(PVector d, boolean gravity) {
    PVector orig = pos.copy();
    pos.add(d);
    if (world.getBlock(round(pos.x/blockSize), round(pos.y/blockSize), round(pos.z/blockSize)).isSolid() ||
        world.getBlock(round(pos.x/blockSize), round(pos.y/blockSize)-1, round(pos.z/blockSize)).isSolid()) {
      pos = orig.copy();
    }
    
    if (gravity) {
      orig = pos.copy();
      vel.add(new PVector(0, 5, 0));
      vel.limit(terminalVel);
      pos.add(vel);
      if (world.getBlock(round(pos.x/blockSize), round(pos.y/blockSize), round(pos.z/blockSize)).isSolid() ||
          world.getBlock(round(pos.x/blockSize), round(pos.y/blockSize)-1, round(pos.z/blockSize)).isSolid()) {
        pos = orig.copy();
        vel = new PVector(0, 0, 0);
      }
    }
  }
}
