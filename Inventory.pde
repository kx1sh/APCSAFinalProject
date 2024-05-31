public class Inventory {
 ArrayList<Item> Items = new ArrayList<Item>();
 public void addItem(Item e) {
  Items.add(e);
 }
 public Item useItem(int x) {
  if (x < Items.size()) {
   return Items.remove(Items.get(x)); 
  } }
  public int getCount(Item e) {
    int count = 0;
   for(Item x : Items) if (x.equals(e)) {count++;}
   return count; 
  }
  
 
}
