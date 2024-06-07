public class Item {
  private byte count;
  private int type;
  private int atthp;
  private int attvel;
  public Item(byte c, int t) {
    count = c; type = t;
  }
  
  public byte getCount() {return count;}
  public int getType() {return type;}
  
  
  public void use(Player player)  {
    float ps = player.getSpeed();
     player.setSpeed(attvel+ps);
     float ph = player.getHp();
     player.setHp(ph+atthp);
  }
}
