public class Item {
  private byte count;
  private int type;
  
  public Item(byte c, int t) {
    count = c; type = t;
  }
  
  public byte getCount() {return count;}
  public int getType() {return type;}
  
  public void use(World world) {
  
  }
}
