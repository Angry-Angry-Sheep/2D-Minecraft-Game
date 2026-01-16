class ChestEntity {

  static final int COLS = 9;
  static final int ROWS = 3;
  static final int SIZE = 27;

  int[] items = new int[SIZE];
  int[] counts = new int[SIZE];

  int worldX, worldY; // world tile coordinates

  ChestEntity(int wx, int wy) {
    worldX = wx;
    worldY = wy;

    for (int i = 0; i < SIZE; i++) {
      items[i] = AIR;
      counts[i] = 0;
    }
  }
}
