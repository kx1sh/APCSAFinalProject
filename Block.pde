public class Block {
  private int type, state;
  private PVector pos;
  private World world;
  
  public Block(int t, PVector p, World w) {
    type = t; state = 0; pos = p; world = w;
  }
  
  public Block(int t, int s, PVector p, World w) {
    type = t; state = s; pos = p; world = w;
  }
  
  public int getType() {return type;}
  public PVector getPos() {return pos;}
  public int getState() {return state;}
  public World getWorld() {return world;}
  
  public boolean isSolid() {
    return type != AIR && type != WATER;
  }
}
