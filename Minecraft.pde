import java.util.HashMap;

int WORLD_SEED = 67;
//69

final int TILE = 48;
final int CHUNK_W = 160;
final int CHUNK_H = 160;
final int SKY_LIGHT = 255;

HashMap<String, PGraphics> chunkImages = new HashMap<String, PGraphics>();

final int BEDROCK = -1;
final int AIR = 0;
final int GRASS = 1;
final int DIRT = 2;
final int STONE = 3;
final int COBBLESTONE = 4;
final int COAL_ORE = 5;
final int IRON_ORE = 6;
final int GOLD_ORE = 7;
final int DIAMOND_ORE = 8;
final int BUSH = 9;
final int GRASS_LEAVES = 10;
final int LEAVES = 11;
final int WOOD = 12;
final int PLANKS = 13;
final int CRAFTING_TABLE = 14;
final int CHEST = 15;

// Current active chunk
int currentChunkX = 0;
int currentChunkY = 0;
int[][] currentTiles;

int blockLight = 340;
int verticalReach = 55;
int decay = 800;
int blockDecay = 10;
int blockDiffuseSteps = 32;

int[][] lightMap = new int[CHUNK_W][CHUNK_H];

HashMap<String, int[][]> savedChunks = new HashMap<String, int[][]>();

PImage bedrockTex;
PImage grassTex;
PImage dirtTex;
PImage stoneTex;
PImage cobblestoneTex;
PImage coal_oreTex;
PImage iron_oreTex;
PImage gold_oreTex;
PImage diamond_oreTex;
PImage bushTex;
PImage grassLeavesTex;
PImage leavesTex;
PImage woodTex;
PImage planksTex;
PImage craftingTableTex;
PImage chestTex;

PImage chestGuiTex;
PImage craftingGuiTex;


float px = TILE * 4;
float py = TILE * 8;
float vx = 0;
float vy = 0;

float moveAccel = 0.5;
float maxSpeed = 7;
float friction = 0.78;
float gravity = 0.95;
float jumpVel = -15;

float halfW = 15;
float halfH = 20;

boolean leftPressed = false;
boolean rightPressed = false;
boolean upPressed = false;
boolean downPressed = false;

// Block interaction
float blockRange = 250; //player reach
int selTileX = -1;
int selTileY = -1;
boolean tileVisible = false;

// Hotbar
final int HOTBAR_SLOTS = 9;
int[] hotbar = new int[HOTBAR_SLOTS];
int selectedSlot = 0;

// GUI
PImage hotbarTex;
PImage slotTex;

float prevPy;

final int SLOT_SIZE = 80;

// Inventory
boolean inventoryOpen = false;

final int INV_COLS = 9;
final int INV_ROWS = 3; // 3 inventory

int[][] inventory = new int[INV_ROWS][INV_COLS];
PImage inventoryTex;

// Dragging
int draggingItem = AIR;
boolean isDragging = false;

final float INV_SLOT_OFFSET_X = 0;
final float INV_SLOT_OFFSET_Y = 150;

final float CHEST_SLOT_OFFSET_X = 0;
final float CHEST_SLOT_OFFSET_Y = -130;


final int MAX_STACK = 64;

int[] hotbarCount = new int[HOTBAR_SLOTS];
int[][] inventoryCount = new int[INV_ROWS][INV_COLS];

int draggingCount = 0;

final int GRASS_TICK_INTERVAL = 1; // frames between grass updates
int grassTickCounter = 0;

ArrayList<ItemEntity> droppedItems = new ArrayList<ItemEntity>();
HashMap<String, ChestEntity> chestEntities = new HashMap<String, ChestEntity>();
ChestEntity openChest = null;
boolean chestOpen = false;

boolean inventorySlotsOnly = false;


void setup() {
  noiseSeed(WORLD_SEED);

  size(900, 700);
  noStroke();

  bedrockTex = loadImage("bedrock.png");
  grassTex = loadImage("grass.png");
  dirtTex = loadImage("dirt.png");
  stoneTex = loadImage("stone.png");
  cobblestoneTex = loadImage("cobblestone.png");
  coal_oreTex = loadImage("coal ore.png");
  iron_oreTex = loadImage("iron ore.png");
  gold_oreTex = loadImage("gold ore.png");
  diamond_oreTex = loadImage("diamond ore.png");
  bushTex = loadImage("bush.png");
  grassLeavesTex  = loadImage("grass leaves.png");
  leavesTex = loadImage("leaves.png");
  woodTex = loadImage("wood.png");
  
  planksTex = loadImage("planks.png");
  craftingTableTex = loadImage("crafting table.png");
  chestTex = loadImage("chest.png");
  
  chestGuiTex = loadImage("chest gui.png");
  craftingGuiTex = loadImage("crafting table gui.png");
  
  planksTex.resize(TILE, TILE);
  craftingTableTex.resize(TILE, TILE);
  chestTex.resize(TILE, TILE);

  
  bushTex.resize(TILE, TILE);
  grassLeavesTex.resize(TILE, TILE);
  leavesTex.resize(TILE, TILE);
  woodTex.resize(TILE, TILE);


  grassTex.resize(TILE, TILE);
  dirtTex.resize(TILE, TILE);
  stoneTex.resize(TILE, TILE);
  cobblestoneTex.resize(TILE, TILE);
  coal_oreTex.resize(TILE, TILE);
  iron_oreTex.resize(TILE, TILE);
  gold_oreTex.resize(TILE, TILE);
  diamond_oreTex.resize(TILE, TILE);
  bedrockTex.resize(TILE, TILE);

  currentTiles = loadChunk(currentChunkX, currentChunkY);

  computeLighting();

  snapPlayerToGround();
  
  hotbarTex = loadImage("gui_hotbar.png");
  slotTex = loadImage("gui_slot.png");
  
  // Fill hotbar with first 9 block IDs
  int[] defaultBlocks = {
    GRASS, DIRT, STONE, COBBLESTONE,
    COAL_ORE, CHEST, CRAFTING_TABLE,
    PLANKS, WOOD
  };
  
  for (int i = 0; i < HOTBAR_SLOTS; i++) {
    hotbar[i] = defaultBlocks[i];
  }
 
  
  // Fill rest with AIR
  for (int y = 0; y < INV_ROWS - 1; y++) {
    for (int x = 0; x < INV_COLS; x++) {
      inventory[y][x] = AIR;
    }
  }
  inventoryTex = loadImage("inventory.png");
  
  for (int i = 0; i < HOTBAR_SLOTS; i++) {
    hotbar[i] = defaultBlocks[i];
    hotbarCount[i] = MAX_STACK;
  }
  for (int y = 0; y < INV_ROWS; y++) {
    for (int x = 0; x < INV_COLS; x++) {
      inventoryCount[y][x] = 0;
    }
  }


}

void draw() {
  background(135, 200, 255);

  updatePlayer();
  updateBlockSystem();

  pushMatrix();
  applyCamera();

  renderWorld();
  renderPlayer();
  renderTransparentBlocks();
  renderBlockSystem();
  
  for (int i = droppedItems.size()-1; i >= 0; i--) {
    ItemEntity it = droppedItems.get(i);
    it.update();
    it.render();
    if (!it.alive) droppedItems.remove(i);
  }


  popMatrix();
  if (chestOpen) {
    renderChest();
    renderInventorySlots(width/2, height/2);
  }
  else if (inventoryOpen) {
    renderInventoryBackground();
    renderInventorySlots(width/2, height/2);
  }

  renderHotbar();
  renderDraggedItem();
}

void renderHotbar() {
  imageMode(CENTER);
  rectMode(CENTER);

  float cx = width / 2;
  float cy = height - 40;

  image(hotbarTex, cx, cy);

  float startX = cx - (HOTBAR_SLOTS - 1) * SLOT_SIZE / 2;

  for (int i = 0; i < HOTBAR_SLOTS; i++) {
    float x = startX + i * SLOT_SIZE;

    if (i == selectedSlot) {
      image(slotTex, x, cy);
    }

    int id = hotbar[i];
    if (id != AIR) {
      PImage tex = getBlockTexture(id);
      if (tex != null) {
        image(tex, x, cy, 32, 32);
      }
    }
    if (hotbarCount[i] > 1) {
      fill(255);
      textAlign(RIGHT, BOTTOM);
      textSize(14);
      text(hotbarCount[i], x + SLOT_SIZE/2 - 6, cy + SLOT_SIZE/2 - 6);
    }
  }
}

void keyPressed() {

  if (key == 'e' || key == 'E') {
  
    if (chestOpen) {
      chestOpen = false;
      openChest = null;
      inventoryOpen = false;
      return;
    }
  
    inventoryOpen = !inventoryOpen;
    return;
  }

  if (key == 'q' || key == 'Q') {
    int slot = selectedSlot;
    if (hotbar[slot] != AIR && hotbarCount[slot] > 0) {
  
      float camX = px - width/2;
      float camY = py - height/2;
      camX = constrain(camX, 0, CHUNK_W*TILE - width);
      camY = constrain(camY, 0, CHUNK_H*TILE - height);
  
      float worldMouseX = mouseX + camX;
      float worldMouseY = mouseY + camY;
  
      float dx = worldMouseX - px;
      float dy = worldMouseY - py;
      float len = sqrt(dx*dx + dy*dy);
      if (len == 0) len = 1;
  
      dx /= len;
      dy /= len;
  
      ItemEntity it = new ItemEntity(
        px,
        py,
        hotbar[slot],
        1,
        true
      );
  
      float throwSpeed = 8.5;
      it.vx = dx * throwSpeed;
      it.vy = dy * throwSpeed - 2.5; // slight upward bias
  
      it.pickupDelay = 40;
      droppedItems.add(it);
  
      hotbarCount[slot]--;
      if (hotbarCount[slot] <= 0) {
        hotbar[slot] = AIR;
        hotbarCount[slot] = 0;
      }
    }
    return;
  }

  // Hotbar selection
  if (key >= '1' && key <= '9') {
    selectedSlot = key - '1';
  }

  if (inventoryOpen) return;

  // Movement
  if (key == 'a' || key == 'A') leftPressed = true;
  if (key == 'd' || key == 'D') rightPressed = true;
  if (key == 'w' || key == 'W') upPressed = true;
  if (key == 's' || key == 'S') downPressed = true;
}

void keyReleased() {
  if (key == 'a' || key == 'A') leftPressed = false;
  if (key == 'd' || key == 'D') rightPressed = false;
  if (key == 'w' || key == 'W') upPressed = false;
  if (key == 's' || key == 'S') downPressed = false;
}

boolean isPlatformTile(int x, int y) {
  int id = currentTiles[x][y];
  return id == WOOD || id == LEAVES || id == CHEST || id == CRAFTING_TABLE;
}

void applyCamera() {
  float camX = px - width/2;
  float camY = py - height/2;

  camX = constrain(camX, 0, CHUNK_W*TILE - width);
  camY = constrain(camY, 0, CHUNK_H*TILE - height);

  translate(-floor(camX), -floor(camY));
}

void updatePlayer() {
  if (inventoryOpen) {
    vx = 0;
    return;
  }

  prevPy = py;

  float skin = 0.1;

  if (leftPressed)  vx -= moveAccel;
  if (rightPressed) vx += moveAccel;

  vx = constrain(vx, -maxSpeed, maxSpeed);

  if (!leftPressed && !rightPressed) vx *= friction;

  vy += gravity;
  vy = min(vy, 40);

  float newPx = px + vx;

  float left = newPx - halfW + skin;
  float right = newPx + halfW - skin;
  float top = py - halfH + skin;
  float bottom = py + halfH - skin;

  int tileTop = floor(top / TILE);
  int tileBottom = floor(bottom / TILE);
  int tileLeft = floor(left / TILE);
  int tileRight = floor(right / TILE);

  if (vx > 0) {
    for (int ty = tileTop; ty <= tileBottom; ty++) {
      if (isSolidTile(tileRight, ty) && !isPlatformTile(tileRight, ty)) {
        newPx = tileRight * TILE - halfW;
        vx = 0;
      }
    }
  } 
  else if (vx < 0) {
    for (int ty = tileTop; ty <= tileBottom; ty++) {
      if (isSolidTile(tileLeft, ty) && !isPlatformTile(tileLeft, ty)) {
        newPx = (tileLeft + 1) * TILE + halfW;
        vx = 0;
      }
    }
  }

  px = newPx;

  float newPy = py + vy;

  float vLeft = px - halfW + skin;
  float vRight = px + halfW - skin;
  float vTop = newPy - halfH + skin;
  float vBottom = newPy + halfH - skin;

  int vTileLeft = floor(vLeft / TILE);
  int vTileRight = floor(vRight / TILE);
  int vTileTop = floor(vTop / TILE);
  int vTileBottom = floor(vBottom / TILE);

  boolean onGround = false;

  // falling
  if (vy > 0) {
    for (int tx = vTileLeft; tx <= vTileRight; tx++) {

      int ty = vTileBottom;
      if (tx < 0 || tx >= CHUNK_W || ty < 0 || ty >= CHUNK_H) continue;

      boolean solid = isSolidTile(tx, ty);
      boolean platform = isPlatformTile(tx, ty);

      float blockTop = ty * TILE;

      float prevBottom = prevPy + halfH;
      float currBottom = newPy + halfH;

      // SOLID NON-PLATFORM BLOCKS
      if (solid && !platform) {
        newPy = blockTop - halfH;
        vy = 0;
        onGround = true;
        break;
      }

      // PLATFORM (AND SOLID+PLATFORM) BLOCKS
      if (platform && !downPressed) {
        if (prevBottom <= blockTop && currBottom >= blockTop) {
          newPy = blockTop - halfH;
          vy = 0;
          onGround = true;
          break;
        }
      }
    }
  }

  // jump
  else if (vy < 0) {
    for (int tx = vTileLeft; tx <= vTileRight; tx++) {
  
      int ty = vTileTop;
      if (tx < 0 || tx >= CHUNK_W || ty < 0 || ty >= CHUNK_H) continue;
  
      // Only collide with true solid blocks (not platforms)
      if (isSolidTile(tx, ty) && !isPlatformTile(tx, ty)) {
  
        float blockBottom = (ty + 1) * TILE;
  
        float prevTop = prevPy - halfH;
        float currTop = newPy - halfH;
  
        // swept collision check (same strength as bottom)
        if (prevTop >= blockBottom && currTop <= blockBottom) {
          newPy = blockBottom + halfH;
          vy = 0;
          break;
        }
      }
    }
  }

  py = newPy;
  if (upPressed && onGround) {
    vy = jumpVel;
  }

  handleChunkChange();
}

void handleChunkChange() {
  boolean changed = false;
  int newChunkX = currentChunkX;
  int newChunkY = currentChunkY;

  if (px < 0) {
    newChunkX--;
    px += CHUNK_W * TILE;
    changed = true;
  }
  else if (px >= CHUNK_W * TILE) {
    newChunkX++;
    px -= CHUNK_W * TILE;
    changed = true;
  }

  if (py < 0) {
    newChunkY--;
    py += CHUNK_H * TILE;
    changed = true;
  }
  else if (py >= CHUNK_H * TILE) {
    newChunkY++;
    py -= CHUNK_H * TILE;
    changed = true;
  }

  if (changed) {
    currentChunkX = newChunkX;
    currentChunkY = newChunkY;
    currentTiles = loadChunk(currentChunkX, currentChunkY);
    computeLighting();
  
    // re-snap dropped items to terrain
  for (ItemEntity it : droppedItems) {
    it.resolveGroundSnap();
  }
  }
}

// SNAP PLAYER TO TERRAIN
void snapPlayerToGround() {
  float skin = 0.1;

  int tileLeft  = floor((px - halfW + skin) / TILE);
  int tileRight = floor((px + halfW - skin) / TILE);

  tileLeft  = constrain(tileLeft, 0, CHUNK_W - 1);
  tileRight = constrain(tileRight, 0, CHUNK_W - 1);

  int bestSurfaceY = -1;

  for (int tx = tileLeft; tx <= tileRight; tx++) {
    for (int ty = 0; ty < CHUNK_H; ty++) {
      if (isSolidTile(tx, ty)) {
        boolean airAbove = (ty == 0) || !isSolidTile(tx, ty - 1);
        if (airAbove) {
          if (bestSurfaceY == -1 || ty < bestSurfaceY) {
            bestSurfaceY = ty;
          }
        }
        break;
      }
    }
  }

  if (bestSurfaceY != -1) {
    float blockTop = bestSurfaceY * TILE;
    py = blockTop - halfH - 0.1;
    vy = 0;
    return;
  }

  py = TILE * 2;
  vy = 0;
}

boolean isSolidTile(int tileX, int tileY) {
  if (tileX < 0 || tileX >= CHUNK_W || tileY < 0 || tileY >= CHUNK_H) {
    return false;
  }
  int id = currentTiles[tileX][tileY];
  
  return (id == GRASS ||
          id == DIRT ||
          id == STONE ||
          id == COBBLESTONE ||
          id == BEDROCK ||
          id == COAL_ORE ||
          id == IRON_ORE ||
          id == GOLD_ORE ||
          id == DIAMOND_ORE ||
          id == PLANKS ||
          id == CRAFTING_TABLE ||
          id == CHEST);

}

void computeLighting() {

  // Reset light map
  for (int x = 0; x < CHUNK_W; x++) {
    for (int y = 0; y < CHUNK_H; y++) {
      lightMap[x][y] = 0;
    }
  }

  for (int x = 0; x < CHUNK_W; x++) {
    boolean blocked = false;
    for (int y = 0; y < CHUNK_H; y++) {

      if (!blocked) {
        lightMap[x][y] = SKY_LIGHT;
        if (isSolidTile(x, y) && currentTiles[x][y] != LEAVES && currentTiles[x][y] != GRASS_LEAVES)
          blocked = true;

      } else {
        lightMap[x][y] = 0;
      }
    }
  }

  diffuseSkyLight(12);

  applyBlockLightsNatural();

  blurUndergroundLighting();
  blurUndergroundLighting();

  enforceBlackout();
}


void applyBlockLightsDiffuse() {

  // Inject block lights as strong sources
  for (int x = 0; x < CHUNK_W; x++) {
    for (int y = 0; y < CHUNK_H; y++) {

      if (currentTiles[x][y] == COBBLESTONE) {
        lightMap[x][y] = max(lightMap[x][y], blockLight);
      }
    }
  }

  // Diffuse block light outward
  for (int it = 0; it < 18; it++) {

    for (int x = 1; x < CHUNK_W - 1; x++) {
      for (int y = 1; y < CHUNK_H - 1; y++) {

        // Light spreads ONLY through air
        if (currentTiles[x][y] != AIR) continue;

        int best =
          max(
            max(lightMap[x+1][y], lightMap[x-1][y]),
            max(lightMap[x][y+1], lightMap[x][y-1])
          );

        int newL = best - decay;

        if (newL > lightMap[x][y]) {
          lightMap[x][y] = newL;
        }
      }
    }
  }
}

void diffuseSkyLight(int iterations) {

  for (int it = 0; it < iterations; it++) {

    for (int x = 1; x < CHUNK_W - 1; x++) {
      for (int y = 1; y < CHUNK_H - 1; y++) {

        // skylight spreads through air & foliage
        if (isSolidTile(x, y)) continue;

        int here = lightMap[x][y];

        int horiz = max(lightMap[x-1][y], lightMap[x+1][y]);
        int vert  = max(lightMap[x][y-1], lightMap[x][y+1]);

        // horizontal spreads farther than vertical
        int candidate = max(horiz - 4, vert - 12);

        if (candidate > here) {
          lightMap[x][y] = candidate;
        }
      }
    }
  }
}


void applyBlockLightsNatural() {

  int maxL = blockLight;

  for (int x = 0; x < CHUNK_W; x++) {
    for (int y = 0; y < CHUNK_H; y++) {
      if (currentTiles[x][y] == COBBLESTONE) {
        lightMap[x][y] = max(lightMap[x][y], maxL);
      }
    }
  }

  for (int it = 0; it < blockDiffuseSteps; it++) {
    for (int x = 1; x < CHUNK_W - 1; x++) {
      for (int y = 1; y < CHUNK_H - 1; y++) {

        if (currentTiles[x][y] != AIR) continue;

        int maxNeighbor = max(
          max(lightMap[x+1][y], lightMap[x-1][y]),
          max(lightMap[x][y+1], lightMap[x][y-1])
        );

        int target = maxNeighbor - blockDecay;

        if (target > lightMap[x][y]) {
          lightMap[x][y] = target;
        }
      }
    }
  }
}

void applyBlockLightsShadowCast() {
  int maxLight = 255;
  int lightRadius = 30;

  for (int x = 0; x < CHUNK_W; x++) {
    for (int y = 0; y < CHUNK_H; y++) {

      if (currentTiles[x][y] == COBBLESTONE) {

        // The source tile itself is full brightness
        lightMap[x][y] = max(lightMap[x][y], maxLight);

        // Spread outward
        for (int dx = -lightRadius; dx <= lightRadius; dx++) {
          for (int dy = -lightRadius; dy <= lightRadius; dy++) {

            int nx = x + dx;
            int ny = y + dy;

            if (nx < 0 || nx >= CHUNK_W || ny < 0 || ny >= CHUNK_H)
              continue;

            float dist = sqrt(dx*dx + dy*dy);
            if (dist > lightRadius) continue;

            // Stops light from penetrating blocks
            if (!hasLineOfSight(x, y, nx, ny)) continue;

            int solids = countSolidsAlongRay(x, y, nx, ny);

        float effectiveDist = dist;
        
        // light degrades 3x faster for each solid tile the ray passes through
        effectiveDist += solids * dist * 3.0;
        
        if (dist < 1.1) {
          lightMap[nx][ny] = max(lightMap[nx][ny], maxLight);
          continue;
        }
        
        int brightness = int(map(effectiveDist, 0, lightRadius, maxLight, 0));
        brightness = max(0, brightness);


            lightMap[nx][ny] = max(lightMap[nx][ny], brightness);
          }
        }
      }
    }
  }
}

boolean hasLineOfSight(int x0, int y0, int x1, int y1) {

  int dx = abs(x1 - x0);
  int dy = abs(y1 - y0);

  int sx = x0 < x1 ? 1 : -1;
  int sy = y0 < y1 ? 1 : -1;

  int err = dx - dy;

  int cx = x0;
  int cy = y0;

  int solidCount = 0;

  while (true) {

    // Skip origin tile
    if (!(cx == x0 && cy == y0)) {

      if (cx == x1 && cy == y1) {
        return (solidCount <= 2);
      }

      // For all intermediate tiles, check for blocking
      if (isSolidTile(cx, cy)) {
        solidCount++;
        if (solidCount > 2) return false;   // block after 2 solids
      }
    }

    // Step ray
    if (cx == x1 && cy == y1)
      break;

    int e2 = 2 * err;
    if (e2 > -dy) { err -= dy; cx += sx; }
    if (e2 < dx) { err += dx; cy += sy; }
  }

  return (solidCount <= 2);
}

int countSolidsAlongRay(int x0, int y0, int x1, int y1) {

  int dx = abs(x1 - x0);
  int dy = abs(y1 - y0);

  int sx = x0 < x1 ? 1 : -1;
  int sy = y0 < y1 ? 1 : -1;

  int err = dx - dy;

  int cx = x0;
  int cy = y0;

  int solidCount = 0;

  while (!(cx == x1 && cy == y1)) {

    // skip origin tile AND final tile
    if (!(cx == x0 && cy == y0) && !(cx == x1 && cy == y1)) {
      if (isSolidTile(cx, cy))
        solidCount++;
    }

    int e2 = 2 * err;
    if (e2 > -dy) { err -= dy; cx += sx; }
    if (e2 < dx) { err += dx; cy += sy; }
  }

  return solidCount;
}

void enforceBlackout() {
  for (int x = 0; x < CHUNK_W; x++) {
    for (int y = 0; y < CHUNK_H; y++) {

      int L = lightMap[x][y];

      if (L < 30) {
        if (currentTiles[x][y] != AIR) {
          lightMap[x][y] = 0;
        } else {
          lightMap[x][y] = 15;
        }
      }
    }
  }
}

void blurUndergroundLighting() {
  int[][] temp = new int[CHUNK_W][CHUNK_H];

  for (int x = 1; x < CHUNK_W - 1; x++) {
    for (int y = 1; y < CHUNK_H - 1; y++) {

      // Do NOT blur skylight
      if (lightMap[x][y] >= SKY_LIGHT) {
          temp[x][y] = lightMap[x][y];
          continue;
      }


      int sum = lightMap[x][y] +
        lightMap[x-1][y] + lightMap[x+1][y] +
        lightMap[x][y-1] + lightMap[x][y+1];

      temp[x][y] = sum / 5;
    }
  }

  for (int x = 1; x < CHUNK_W - 1; x++) {
    for (int y = 1; y < CHUNK_H - 1; y++) {
      lightMap[x][y] = temp[x][y];
    }
  }
}


void addPlayerLight() {
  float maxDist = 250;
  for (int x = 0; x < CHUNK_W; x++) {
    for (int y = 0; y < CHUNK_H; y++) {
      float cx = x*TILE + TILE/2;
      float cy = y*TILE + TILE/2;
      float dx = cx - px;
      float dy = cy - py;
      float dist = sqrt(dx*dx + dy*dy);

      if (dist < maxDist) {
        int extra = int(map(dist, 0, maxDist, 255, 0));
        lightMap[x][y] = max(lightMap[x][y], extra);
      }
    }
  }
}

void drawLit(PImage tex, float x, float y, int light) {

  image(tex, x, y);

  // Full black overlay for solid tiles only
  if (light <= 0 && currentTiles[int(x/TILE)][int(y/TILE)] != AIR) {
    fill(0);
    rect(x, y, TILE+1, TILE+1);
    return;
  }

  // Air gets dark but not pure black
  if (light <= 0) {
    fill(0, 220);
    rect(x, y, TILE+1, TILE+1);
    return;
  }

  // Normal fade for everything (including air)
  int darkness = 255 - light;
  fill(0, darkness);
  rect(x, y, TILE+1, TILE+1);
}

void renderTransparentBlocks() {
  rectMode(CORNER);
  imageMode(CORNER);

  for (int tx = 0; tx < CHUNK_W; tx++) {
    for (int ty = 0; ty < CHUNK_H; ty++) {

      int id = currentTiles[tx][ty];
      if (!isTransparentBlock(id)) continue;

      float wx = tx * TILE;
      float wy = ty * TILE;
      int L = lightMap[tx][ty];

      if (id == AIR) {
        drawAirDarkness(wx, wy, L);
        continue;
      }

      PImage tex = getBlockTexture(id);
      if (tex != null) {
        drawLit(tex, wx, wy, L);
      }
    }
  }
}



// WORLD RENDERING
void renderWorld() {
  rectMode(CORNER);
  imageMode(CORNER);

  for (int tx = 0; tx < CHUNK_W; tx++) {
    for (int ty = 0; ty < CHUNK_H; ty++) {

      int id = currentTiles[tx][ty];
      float wx = tx * TILE;
      float wy = ty * TILE;
      int L = lightMap[tx][ty];

      // Transparent blocks are drawn later
      if (isTransparentBlock(id)) continue;

      // ALL OTHER BLOCKS
      switch (id) {
        case GRASS: drawLit(grassTex, wx, wy, L); break;
        case DIRT: drawLit(dirtTex, wx, wy, L); break;
        case STONE: drawLit(stoneTex, wx, wy, L); break;
        case COBBLESTONE: drawLit(cobblestoneTex, wx, wy, L); break;
        case BEDROCK: drawLit(bedrockTex, wx, wy, L); break;
        case COAL_ORE: drawLit(coal_oreTex, wx, wy, L); break;
        case IRON_ORE: drawLit(iron_oreTex, wx, wy, L); break;
        case GOLD_ORE: drawLit(gold_oreTex, wx, wy, L); break;
        case DIAMOND_ORE: drawLit(diamond_oreTex, wx, wy, L); break;
        case BUSH: drawLit(bushTex, wx, wy, L); break;
        case GRASS_LEAVES: drawLit(grassLeavesTex, wx, wy, L); break;
        case LEAVES: drawLit(leavesTex, wx, wy, L); break;
        case WOOD: drawLit(woodTex, wx, wy, L); break;
        case PLANKS: drawLit(planksTex, wx, wy, L); break;
        case CRAFTING_TABLE: drawLit(craftingTableTex, wx, wy, L); break;
        case CHEST: drawLit(chestTex, wx, wy, L); break;
      }
    }
  }
}

void drawAirDarkness(float x, float y, int light) {

  if (light >= SKY_LIGHT) return;

  int darkness = 255 - light;
  darkness = constrain(darkness, 0, 220);

  fill(0, darkness);
  rect(x, y, TILE, TILE);
}



// PLAYER RENDER
void renderPlayer() {
  rectMode(CENTER);
  fill(255, 255, 0);
  rect(px, py, halfW * 2, halfH * 2);
}

// CHUNK LOADING / GENERATION
int[][] loadChunk(int cx, int cy) {
  String key = cx + "," + cy;

  if (savedChunks.containsKey(key)) {
    return savedChunks.get(key);
  }

  int[][] tiles = generateChunk(cx, cy);
  savedChunks.put(key, tiles);
  return tiles;
}

int[][] generateChunk(int cx, int cy) {

  int[][] tiles = new int[CHUNK_W][CHUNK_H];

  float baseHeight = 55;
  float hillAmp = 200;

  float nBig = 0.0015;
  float nMed = 0.01;
  float nSmall = 0.04;

  float dirtBase = 3.5;
  float dirtNoise = 0.035;

  float blendScaleX = 0.12;
  float blendScaleY = 0.12;

  int[] surface = new int[CHUNK_W];
  int[] dirtDepth = new int[CHUNK_W];

  for (int x = 0; x < CHUNK_W; x++) {
    int worldX = cx * CHUNK_W + x;

    float big  = noise((worldX + WORLD_SEED) * nBig);
    float med  = noise((worldX + WORLD_SEED) * nMed);
    float small= noise((worldX + WORLD_SEED) * nSmall);
    
    float noiseVal = big * 0.55 + med * 0.30 + small * 0.15;
    
    noiseVal = (noiseVal - 0.5);
    
    int height = int(baseHeight + noiseVal * hillAmp);
    surface[x] = height;

    float dn = noise((worldX + WORLD_SEED * 444) * dirtNoise);
    dirtDepth[x] = max(2, int(dirtBase + dn * 3));
  }

  // 2. TERRRAIN
  int worldStartY = cy * CHUNK_H;

  for (int x = 0; x < CHUNK_W; x++) {

    int surfY = surface[x];
    int dirtD = dirtDepth[x];

    for (int localY = 0; localY < CHUNK_H; localY++) {

      int worldY = worldStartY + localY;

      if (worldY < surfY) {
        tiles[x][localY] = AIR;
      }
      else if (worldY == surfY) {
        tiles[x][localY] = GRASS;
      }
      else if (worldY <= surfY + dirtD) {

        float blend = noise(
          (worldY + WORLD_SEED) * blendScaleY,
          (x + WORLD_SEED) * blendScaleX
        );

        float depthFactor = map(worldY, surfY, surfY + dirtD, 0, 1);
        float threshold = 0.82 - depthFactor * 0.45;

        if (blend > threshold) tiles[x][localY] = STONE;
        else tiles[x][localY] = DIRT;

      } else {
        tiles[x][localY] = STONE;
      }
    }
  }
  
  // 2.5 SURFACE VEGETATION
  for (int x = 1; x < CHUNK_W - 1; x++) {
  
    int surfY = surface[x];
  
    if (tiles[x][surfY] != GRASS) continue;
  
    int above = surfY - 1;
    if (above < 0) continue;
  
    float worldX = cx * CHUNK_W + x;
  
    float bushNoise  = noise(worldX * 0.15, (surfY + WORLD_SEED) * 0.15);
    float leafNoise  = noise(worldX * 0.35, (surfY + WORLD_SEED) * 0.35);
  
    // Bush
    if (bushNoise > 0.70) {
      tiles[x][above] = BUSH;
    }
    // Grass leaves 
    else if (leafNoise > 0.49) {
      tiles[x][above] = GRASS_LEAVES;
    }
  }
  
  // 2.6 TREES
  for (int x = 3; x < CHUNK_W - 3; x++) {
  
    int surfY = surface[x];
    if (tiles[x][surfY] != GRASS) continue;
  
    float worldX = cx * CHUNK_W + x;
    float treeNoise = noise(worldX * 0.06, (surfY + WORLD_SEED) * 0.06);
    if (treeNoise < 0.55) continue;
  
    // Prevent overlap
    boolean spaceClear = true;
    for (int dx = -3; dx <= 3; dx++) {
      if (tiles[x + dx][surfY - 1] == WOOD) {
        spaceClear = false;
        break;
      }
  }
  if (!spaceClear) continue;
        tiles[x][surfY] = DIRT;

  for (int h = 1; h <= 4; h++) {
    int ty = surfY - h;
    if (ty < 0) break;
    tiles[x][ty] = WOOD;
  }

  int top = surfY - 4;

  // leaves
  // Layer 1
  for (int dx = -2; dx <= 2; dx++) {
    if (tiles[x + dx][top - 1] == AIR)
      tiles[x + dx][top - 1] = LEAVES;
  }

  // Layer 2
  for (int dx = -1; dx <= 1; dx++) {
    if (tiles[x + dx][top - 2] == AIR)
      tiles[x + dx][top - 2] = LEAVES;
  }

  // Layer 3
  if (tiles[x][top - 3] == AIR)
    tiles[x][top - 3] = LEAVES;
}

  // 3. BEDROCK
  if (cy == 0) {
    for (int x = 0; x < CHUNK_W; x++) {
      tiles[x][CHUNK_H - 1] = BEDROCK;  // bottom tile row
    }
  }
  
  // 3.5 CAVES
  boolean[][] caveMask = new boolean[CHUNK_W][CHUNK_H];

  for (int x = 2; x < CHUNK_W - 2; x++) {
    for (int y = 2; y < CHUNK_H - 2; y++) {

      int worldY = cy * CHUNK_H + y;

      boolean allowNearSurface = noise(x*0.15, y*0.15) > 0.92;
      if (!allowNearSurface && worldY < baseHeight + 5) continue;

      float f1 = noise((x + WORLD_SEED*31) * 0.05, (y + WORLD_SEED*41) * 0.05);
      float f2 = noise((x + WORLD_SEED*11) * 0.10, (y + WORLD_SEED*21) * 0.10);
      float f3 = noise((x + WORLD_SEED*51) * 0.20, (y + WORLD_SEED*61) * 0.20);

      float value = f1 * 0.60 + f2 * 0.33 + f3 * 0.17;

      if (value > 0.58) caveMask[x][y] = true;
    }
  }

  // cave stuff
  for (int x = 2; x < CHUNK_W - 2; x++) {
    for (int y = 2; y < CHUNK_H - 2; y++) {
      if (!caveMask[x][y]) continue;

      // If dirt is above cancel the cave
      if (tiles[x][y-1] == DIRT || tiles[x][y-2] == DIRT || tiles[x][y-3] == DIRT) {
        caveMask[x][y] = false;
        continue;
      }
      if (tiles[x][y-1] == GRASS || tiles[x][y-2] == GRASS || tiles[x][y-3] == GRASS) {
        caveMask[x][y] = false;
        continue;
      }
    }
  }

  for (int x = 2; x < CHUNK_W - 2; x++) {
    for (int y = 2; y < CHUNK_H - 2; y++) {
      if (!caveMask[x][y]) continue;

      int neighbors = 0;

      for (int dx = -1; dx <= 1; dx++) {
        for (int dy = -1; dy <= 1; dy++) {
          if (dx == 0 && dy == 0) continue;
          if (caveMask[x+dx][y+dy]) neighbors++;
        }
      }

      if (neighbors < 2) caveMask[x][y] = false;
    }
  }

  for (int x = 1; x < CHUNK_W - 1; x++) {
    for (int y = 1; y < CHUNK_H - 1; y++) {
      if (caveMask[x][y] && tiles[x][y] == STONE) {
        tiles[x][y] = AIR;
      }
    }
  }

  // 4. ORE GENERATION
  for (int x = 1; x < CHUNK_W - 1; x++) {
    for (int y = 1; y < CHUNK_H - 1; y++) {

      if (tiles[x][y] != STONE) continue;

      int worldY = cy * CHUNK_H + y;

      float nCoal    = noise(x * 0.12 + WORLD_SEED*7,    worldY * 0.12 + WORLD_SEED*13);
      float nIron    = noise(x * 0.12 + WORLD_SEED*27,   worldY * 0.12 + WORLD_SEED*33);
      float nGold    = noise(x * 0.12 + WORLD_SEED*57,   worldY * 0.12 + WORLD_SEED*63);
      float nDiamond = noise(x * 0.12 + WORLD_SEED*87,   worldY * 0.12 + WORLD_SEED*93);
      
      //COAL
      if (worldY < baseHeight + 25 && nCoal > 0.45) {
        if (noise((x + WORLD_SEED*1000) * 0.30,
                  (y + WORLD_SEED*2000) * 0.30) > 0.55)
          tiles[x][y] = COAL_ORE;
      }
      
      // IRON
      if (nIron > 0.70) {
        if (noise((x + WORLD_SEED*2000) * 0.5,
                  (y + WORLD_SEED*3000) * 0.5) > 0.55)
          tiles[x][y] = IRON_ORE;
      }
      
      // GOLD
      if (worldY > baseHeight + 20 && nGold > 0.70) {
        if (noise((x + WORLD_SEED*4000) * 0.9,
                  (y + WORLD_SEED*5000) * 0.9) > 0.60)
          tiles[x][y] = GOLD_ORE;
      }

      // EXTRA DIAMOND BOOST NEAR BOTTOM
      float diamondBoost = 0;
      if (worldY > baseHeight + 70) diamondBoost = 0.10;
      if (worldY > baseHeight + 90) diamondBoost = 0.20;
      if (worldY > baseHeight + 110) diamondBoost = 0.30;

      // DIAMOND
      if (worldY > baseHeight + 50 && nDiamond > 0.85 - diamondBoost) {
        if (noise((x + WORLD_SEED*7000) * 0.95,
                  (y + WORLD_SEED*8000) * 0.95) > 0.50)
          tiles[x][y] = DIAMOND_ORE;
      }
    }
  }

  // 5. NATURAL DIRT BLEEDING INTO STONE
  for (int x = 1; x < CHUNK_W - 1; x++) {
    for (int y = 1; y < CHUNK_H - 1; y++) {

      if (tiles[x][y] != STONE) continue;

      boolean nearDirt =
        tiles[x-1][y] == DIRT || tiles[x+1][y] == DIRT ||
        tiles[x][y-1] == DIRT || tiles[x][y+1] == DIRT ||
        tiles[x-1][y-1] == DIRT || tiles[x+1][y-1] == DIRT ||
        tiles[x-1][y+1] == DIRT || tiles[x+1][y+1] == DIRT;

      if (!nearDirt) continue;

      float n1 = noise((x + WORLD_SEED*8)  * 0.15, (y + WORLD_SEED*9)  * 0.15);
      float n2 = noise((x + WORLD_SEED*18) * 0.07, (y + WORLD_SEED*12) * 0.07);
      float n3 = noise((x + WORLD_SEED*5)  * 0.35, (y + WORLD_SEED*27) * 0.35);

      float combined = (n1*0.5 + n2*0.3 + n3*0.2);

      if (combined > 0.58)
        tiles[x][y] = DIRT;
    }
  }

  return tiles;
}


// BLOCK INTERACTION SYSTEM

void renderBlockSystem() {
  renderBlockPreview();
  renderSelectedTile();
}

PImage getBlockTexture(int id) {
  switch (id) {
    case GRASS: return grassTex;
    case DIRT: return dirtTex;
    case STONE: return stoneTex;
    case COBBLESTONE: return cobblestoneTex;
    case BEDROCK: return bedrockTex;
    case COAL_ORE: return coal_oreTex;
    case IRON_ORE: return iron_oreTex;
    case GOLD_ORE: return gold_oreTex;
    case DIAMOND_ORE: return diamond_oreTex;
    case BUSH: return bushTex;
    case GRASS_LEAVES: return grassLeavesTex;
    case LEAVES: return leavesTex;
    case WOOD: return woodTex;
    case PLANKS: return planksTex;
    case CRAFTING_TABLE: return craftingTableTex;
    case CHEST: return chestTex;

  }
  return null;
}


// BLOCK SELECTION
void updateBlockSelection() {
  tileVisible = false;
  selTileX = -1;
  selTileY = -1;

  float camX = px - width/2;
  float camY = py - height/2;
  camX = constrain(camX, 0, CHUNK_W*TILE - width);
  camY = constrain(camY, 0, CHUNK_H*TILE - height);

  float worldMouseX = mouseX + camX;
  float worldMouseY = mouseY + camY;

  int targetTileX = floor(worldMouseX / TILE);
  int targetTileY = floor(worldMouseY / TILE);

  if (targetTileX < 0 || targetTileX >= CHUNK_W ||
      targetTileY < 0 || targetTileY >= CHUNK_H) {
    return;
  }

  float dx = (targetTileX*TILE + TILE/2) - px;
  float dy = (targetTileY*TILE + TILE/2) - py;
  float dist = sqrt(dx*dx + dy*dy);
  if (dist > blockRange) return;

  float startX = px;
  float startY = py;
  float endX = targetTileX*TILE + TILE/2;
  float endY = targetTileY*TILE + TILE/2;

  int steps = int(max(abs(endX - startX), abs(endY - startY)) / 6);
  if (steps < 1) steps = 1;

  float stepX = (endX - startX) / steps;
  float stepY = (endY - startY) / steps;

  float rx = startX;
  float ry = startY;

  for (int i = 0; i <= steps; i++) {
    int cx = floor(rx / TILE);
    int cy = floor(ry / TILE);

    if (cx >= 0 && cx < CHUNK_W && cy >= 0 && cy < CHUNK_H) {
      if (isSolidTile(cx, cy)) {
        selTileX = cx;
        selTileY = cy;
        tileVisible = true;
        return;
      }
    }

    rx += stepX;
    ry += stepY;
  }

  selTileX = targetTileX;
  selTileY = targetTileY;
  tileVisible = true;
}

// HIGHLIGHT SELECTED TILE
void renderSelectedTile() {
  if (!tileVisible) return;

  stroke(0);
  strokeWeight(3);
  noFill();
  rectMode(CORNER);
  rect(selTileX*TILE, selTileY*TILE, TILE, TILE);

  noStroke();
}

// BLOCK CLICK HANDLING
void mousePressed() {

  if (chestOpen) {
    handleChestMouse();      // chest slots
    handleInventoryMouse();  // inventory + hotbar
    return;
  }

  if (inventoryOpen) {
    handleInventoryMouse();
    return;
  }

  if (!tileVisible) return;


  boolean changed = false;

  int tx = selTileX;
  int ty = selTileY;
  int id = currentTiles[tx][ty];

  if (mouseButton == RIGHT) {

    // open chest
    if (id == CHEST) {
      int wx = currentChunkX * CHUNK_W + tx;
      int wy = currentChunkY * CHUNK_H + ty;

      String key = chestKeyFromWorld(wx, wy);
      openChest = chestEntities.get(key);

      if (openChest != null) {
        chestOpen = true;
        inventoryOpen = false;
      }
      return;
    }

    // place block
    if (isInsidePlayer(tx, ty)) return;

    int slot = selectedSlot;

    if (hotbar[slot] != AIR &&
        hotbarCount[slot] > 0 &&
        isReplaceableBlock(id)) {

      int placeId = hotbar[slot];

      currentTiles[tx][ty] = placeId;
      invalidateFoliageAbove(tx, ty);
      hotbarCount[slot]--;

      // create chest entity
      if (placeId == CHEST) {
        int wx = currentChunkX * CHUNK_W + tx;
        int wy = currentChunkY * CHUNK_H + ty;
        String key = chestKeyFromWorld(wx, wy);
        chestEntities.put(key, new ChestEntity(wx, wy));
      }

      if (hotbarCount[slot] <= 0) {
        hotbar[slot] = AIR;
        hotbarCount[slot] = 0;
      }

      changed = true;
    }
  }
  // break block
  else if (mouseButton == LEFT) {

    if (!isBreakableTile(tx, ty)) return;

    // remove chest enity
    if (id == CHEST) {
      int wx = currentChunkX * CHUNK_W + tx;
      int wy = currentChunkY * CHUNK_H + ty;
      String key = chestKeyFromWorld(wx, wy);
    
      ChestEntity chest = chestEntities.get(key);
      if (chest != null) {
    
        // Drop all stored items
        for (int i = 0; i < ChestEntity.SIZE; i++) {
          int item = chest.items[i];
          int count = chest.counts[i];
    
          if (item != AIR && count > 0) {
            spawnItemDrop(tx, ty, item, count, false);
          }
        }
    
        // Remove chest entity
        chestEntities.remove(key);
      }
    }

    // drop item
    if (id != AIR) {
      spawnItemDrop(tx, ty, id, 1);
    }

    currentTiles[tx][ty] = AIR;
    invalidateFoliageAbove(tx, ty);
    changed = true;
  }
  // block light update
  if (changed) {
    computeLighting();
  }
}



void renderBlockPreview() {
  if (!tileVisible) return;
  if (isSolidTile(selTileX, selTileY)) return;

  int id = hotbar[selectedSlot];
  if (id == AIR) return;

  PImage tex = getBlockTexture(id);
  if (tex == null) return;

  tint(255, 120);
  image(tex, selTileX * TILE, selTileY * TILE);
  noTint();
}

void spawnItemDrop(int tx, int ty, int id, int count) {
  spawnItemDrop(tx, ty, id, count, true);
}

void spawnItemDrop(int tx, int ty, int id, int count, boolean instantPickup) {
  float x = tx * TILE + TILE/2;
  float y = ty * TILE + TILE/2;
  droppedItems.add(new ItemEntity(x, y, id, count, instantPickup));
}

boolean isTransparentBlock(int id) {
  return id == AIR ||
         id == BUSH ||
         id == GRASS_LEAVES ||
         id == LEAVES;
}

boolean isBreakableTile(int tx, int ty) {
  if (tx < 0 || tx >= CHUNK_W || ty < 0 || ty >= CHUNK_H)
    return false;

  int id = currentTiles[tx][ty];

  return id != AIR;
}

void renderInventory() {
  imageMode(CENTER);
  rectMode(CENTER);

  float cx = width / 2;
  float cy = height / 2;

  image(inventoryTex, cx, cy);

  float slotSize = SLOT_SIZE;
  float startX = cx - (INV_COLS - 1) * slotSize / 2 + INV_SLOT_OFFSET_X;
  float startY = cy - (INV_ROWS - 1) * slotSize / 2 + INV_SLOT_OFFSET_Y;

  for (int y = 0; y < INV_ROWS; y++) {
    for (int x = 0; x < INV_COLS; x++) {

      float sx = startX + x * slotSize;
      float sy = startY + y * slotSize;

      int id = inventory[y][x];
      if (id != AIR) {
        PImage tex = getBlockTexture(id);
        if (tex != null) {
          image(tex, sx, sy, 32, 32);
        }
      }
      if (inventoryCount[y][x] > 1) {
        fill(255);
        textAlign(RIGHT, BOTTOM);
        textSize(14);
        text(inventoryCount[y][x], sx + SLOT_SIZE/2 - 6, sy + SLOT_SIZE/2 - 6);
      }
    }
  }

  // Draw dragged item
  if (isDragging && draggingItem != AIR) {
    PImage tex = getBlockTexture(draggingItem);
    if (tex != null) {
      image(tex, mouseX, mouseY, 32, 32);
    }
  }
  if (isDragging && draggingItem != AIR) {
    PImage tex = getBlockTexture(draggingItem);
    if (tex != null) {
      image(tex, mouseX, mouseY, 32, 32);
  
      if (draggingCount > 1) {
        fill(255);
        textAlign(RIGHT, BOTTOM);
        textSize(14);
        text(draggingCount, mouseX + 16, mouseY + 16);
      }
    }
  }
}

void handleInventoryMouse() {

  float half = SLOT_SIZE / 2;
  boolean split = keyPressed && key == ' ';

  // hotbar
  float hotbarY = height - 40;
  float hotbarStartX = width / 2 - (HOTBAR_SLOTS - 1) * SLOT_SIZE / 2;

  for (int i = 0; i < HOTBAR_SLOTS; i++) {
    float sx = hotbarStartX + i * SLOT_SIZE;
    float sy = hotbarY;

    if (mouseX >= sx - half && mouseX <= sx + half &&
        mouseY >= sy - half && mouseY <= sy + half) {

      if (!isDragging) {
        int count = hotbarCount[i];
        if (hotbar[i] == AIR || count <= 0) return;

        if (split && count > 1) {
          draggingItem = hotbar[i];
          draggingCount = (count + 1) / 2;
          hotbarCount[i] -= draggingCount;
        } else {
          draggingItem = hotbar[i];
          draggingCount = count;
          hotbar[i] = AIR;
          hotbarCount[i] = 0;
        }

        isDragging = true;
      }
      else {
        if (hotbar[i] == AIR) {
          hotbar[i] = draggingItem;
          hotbarCount[i] = draggingCount;
          draggingItem = AIR;
          draggingCount = 0;
          isDragging = false;
        }
        else if (hotbar[i] == draggingItem) {
          int space = MAX_STACK - hotbarCount[i];
          int moved = min(space, draggingCount);

          hotbarCount[i] += moved;
          draggingCount -= moved;

          if (draggingCount <= 0) {
            draggingItem = AIR;
            draggingCount = 0;
            isDragging = false;
          }
        }
        else {
          int tempItem = hotbar[i];
          int tempCount = hotbarCount[i];

          hotbar[i] = draggingItem;
          hotbarCount[i] = draggingCount;

          draggingItem = tempItem;
          draggingCount = tempCount;
        }
      }
      return;
    }
  }

  float cx = width / 2;
  float cy = height / 2;

  float startX = cx - (INV_COLS - 1) * SLOT_SIZE / 2 + INV_SLOT_OFFSET_X;
  float startY = cy - (INV_ROWS - 1) * SLOT_SIZE / 2 + INV_SLOT_OFFSET_Y;

  for (int y = 0; y < INV_ROWS; y++) {
    for (int x = 0; x < INV_COLS; x++) {

      float sx = startX + x * SLOT_SIZE;
      float sy = startY + y * SLOT_SIZE;

      if (mouseX >= sx - half && mouseX <= sx + half &&
          mouseY >= sy - half && mouseY <= sy + half) {

        if (!isDragging) {
          int count = inventoryCount[y][x];
          if (inventory[y][x] == AIR || count <= 0) return;

          if (split && count > 1) {
            draggingItem = inventory[y][x];
            draggingCount = (count + 1) / 2;
            inventoryCount[y][x] -= draggingCount;
          } else {
            draggingItem = inventory[y][x];
            draggingCount = count;
            inventory[y][x] = AIR;
            inventoryCount[y][x] = 0;
          }

          isDragging = true;
        }
        else {
          if (inventory[y][x] == AIR) {
            inventory[y][x] = draggingItem;
            inventoryCount[y][x] = draggingCount;
            draggingItem = AIR;
            draggingCount = 0;
            isDragging = false;
          }
          else if (inventory[y][x] == draggingItem) {
            int space = MAX_STACK - inventoryCount[y][x];
            int moved = min(space, draggingCount);

            inventoryCount[y][x] += moved;
            draggingCount -= moved;

            if (draggingCount <= 0) {
              draggingItem = AIR;
              draggingCount = 0;
              isDragging = false;
            }
          }
          else {
            int tempItem = inventory[y][x];
            int tempCount = inventoryCount[y][x];

            inventory[y][x] = draggingItem;
            inventoryCount[y][x] = draggingCount;

            draggingItem = tempItem;
            draggingCount = tempCount;
          }
        }
        return;
      }
    }
  }
  
  if (!chestOpen && isDragging && draggingItem != AIR) {
    spawnItemDrop(
      int(px / TILE),
      int(py / TILE),
      draggingItem,
      draggingCount,
      false
    );
  }
  
  if (!chestOpen) {
    draggingItem = AIR;
    draggingCount = 0;
    isDragging = false;
  }

}


boolean isReplaceableBlock(int id) {
  return id == AIR ||
         id == LEAVES ||
         id == GRASS_LEAVES;
}

// PLAYER-HITBOX CHECK
boolean isInsidePlayer(int tx, int ty) {
  float blockLeft = tx*TILE;
  float blockRight = blockLeft + TILE;
  float blockTop = ty*TILE;
  float blockBottom = blockTop + TILE;

  float pLeft = px - halfW;
  float pRight = px + halfW;
  float pTop = py - halfH;
  float pBottom = py + halfH;

  boolean overlap = !(pRight <= blockLeft || pLeft >= blockRight || pBottom <= blockTop || pTop >= blockBottom);

  return overlap;
}

void updateBlockSystem() {
  updateBlockSelection();
  updateGrassSystem();
}

boolean hasNearbyGrass(int x, int y) {
  for (int dx = -1; dx <= 1; dx++) {
    for (int dy = -1; dy <= 1; dy++) {

      if (dx == 0 && dy == 0) continue;

      int nx = x + dx;
      int ny = y + dy;

      if (nx < 0 || nx >= CHUNK_W || ny < 0 || ny >= CHUNK_H) continue;

      if (currentTiles[nx][ny] == GRASS) return true;
    }
  }
  return false;
}

boolean hasSupportBelow(int x, int y) {
  if (y >= CHUNK_H - 1) return true;

  int below = currentTiles[x][y + 1];

  if (below == AIR) return false;

  if (below == BUSH || below == GRASS_LEAVES)
    return false;

  return isSolidTile(x, y + 1);
}

boolean addItemToInventory(int id, int count) {

  // try hotbar first
  for (int i = 0; i < HOTBAR_SLOTS; i++) {
    if (hotbar[i] == id && hotbarCount[i] < MAX_STACK) {
      int space = MAX_STACK - hotbarCount[i];
      int moved = min(space, count);
      hotbarCount[i] += moved;
      count -= moved;
      if (count <= 0) return true;
    }
  }

  // 2) empty slot
  for (int i = 0; i < HOTBAR_SLOTS; i++) {
    if (hotbar[i] == AIR) {
      hotbar[i] = id;
      hotbarCount[i] = min(MAX_STACK, count);
      return true;
    }
  }

  // try inventory second
  for (int y = 0; y < INV_ROWS; y++) {
    for (int x = 0; x < INV_COLS; x++) {
      if (inventory[y][x] == id && inventoryCount[y][x] < MAX_STACK) {
        int space = MAX_STACK - inventoryCount[y][x];
        int moved = min(space, count);
        inventoryCount[y][x] += moved;
        count -= moved;
        if (count <= 0) return true;
      }
    }
  }

  // empty slot
  for (int y = 0; y < INV_ROWS; y++) {
    for (int x = 0; x < INV_COLS; x++) {
      if (inventory[y][x] == AIR) {
        inventory[y][x] = id;
        inventoryCount[y][x] = min(MAX_STACK, count);
        return true;
      }
    }
  }

  return false; // inventory full
}


void updateGrassSystem() {
  grassTickCounter++;
  if (grassTickCounter < GRASS_TICK_INTERVAL) return;
  grassTickCounter = 0;

  for (int i = 0; i < 60; i++) {

    int x = int(random(CHUNK_W));
    int y = int(random(CHUNK_H));

    int id = currentTiles[x][y];

    // bushes break if air is under
    if ((id == GRASS_LEAVES || id == BUSH) && !hasSupportBelow(x, y)) {
      currentTiles[x][y] = AIR;
      continue;
    }

    // grass decay
    if (id == GRASS) {
      if (y > 0 && !isReplaceableBlock(currentTiles[x][y - 1])) {
        currentTiles[x][y] = DIRT;
      }
    }

    // grass spread
    else if (id == DIRT) {
      if (y <= 0) continue;
      if (!isReplaceableBlock(currentTiles[x][y - 1])) continue;

      if (hasNearbyGrass(x, y)) {
        currentTiles[x][y] = GRASS;
      }
    }
  }
}

String chestKey(int cx, int cy, int tx, int ty) {
  return cx + "," + cy + ":" + tx + "," + ty;
}

String chestKeyFromWorld(int worldX, int worldY) {
  return worldX + "," + worldY;
}

String chestKeyFromLocal(int cx, int cy, int tx, int ty) {
  int wx = cx * CHUNK_W + tx;
  int wy = cy * CHUNK_H + ty;
  return wx + "," + wy;
}

void renderChest() {
  if (!chestOpen || openChest == null) return;

  imageMode(CENTER);
  rectMode(CENTER);

  float cx = width / 2;
  float cy = height / 2;

  image(chestGuiTex, cx, cy);

  float startX = cx - (ChestEntity.COLS - 1) * SLOT_SIZE / 2 + CHEST_SLOT_OFFSET_X;
  float startY = cy - (ChestEntity.ROWS - 1) * SLOT_SIZE / 2 + CHEST_SLOT_OFFSET_Y;

  for (int i = 0; i < ChestEntity.SIZE; i++) {

    int col = i % ChestEntity.COLS;
    int row = i / ChestEntity.COLS;

    float sx = startX + col * SLOT_SIZE;
    float sy = startY + row * SLOT_SIZE;

    int id = openChest.items[i];
    int count = openChest.counts[i];

    if (id != AIR) {
      PImage tex = getBlockTexture(id);
      if (tex != null) image(tex, sx, sy, 32, 32);
    }

    if (count > 1) {
      fill(255);
      textAlign(RIGHT, BOTTOM);
      textSize(14);
      text(count, sx + SLOT_SIZE/2 - 6, sy + SLOT_SIZE/2 - 6);
    }
  }
}


void handleChestMouse() {

  float half = SLOT_SIZE / 2;
  boolean split = keyPressed && key == ' ';

  float cx = width / 2;
  float cy = height / 2;

  for (int i = 0; i < ChestEntity.SIZE; i++) {

    float startX = cx - (ChestEntity.COLS - 1) * SLOT_SIZE / 2 + CHEST_SLOT_OFFSET_X;
    float startY = cy - (ChestEntity.ROWS - 1) * SLOT_SIZE / 2 + CHEST_SLOT_OFFSET_Y;
    
    int col = i % ChestEntity.COLS;
    int row = i / ChestEntity.COLS;


    float sx = startX + col * SLOT_SIZE;
    float sy = startY + row * SLOT_SIZE;

    if (mouseX >= sx - half && mouseX <= sx + half &&
        mouseY >= sy - half && mouseY <= sy + half) {

      if (!isDragging) {
        if (openChest.items[i] == AIR || openChest.counts[i] == 0) return;

        if (split && openChest.counts[i] > 1) {
          draggingItem = openChest.items[i];
          draggingCount = (openChest.counts[i] + 1) / 2;
          openChest.counts[i] -= draggingCount;
        } else {
          draggingItem = openChest.items[i];
          draggingCount = openChest.counts[i];
          openChest.items[i] = AIR;
          openChest.counts[i] = 0;
        }

        isDragging = true;
      }
      else {
        if (openChest.items[i] == AIR) {
          openChest.items[i] = draggingItem;
          openChest.counts[i] = draggingCount;
          draggingItem = AIR;
          draggingCount = 0;
          isDragging = false;
        }
        else if (openChest.items[i] == draggingItem) {
          int space = MAX_STACK - openChest.counts[i];
          int moved = min(space, draggingCount);

          openChest.counts[i] += moved;
          draggingCount -= moved;

          if (draggingCount <= 0) {
            draggingItem = AIR;
            draggingCount = 0;
            isDragging = false;
          }
        }
        else {
          int tmpItem = openChest.items[i];
          int tmpCount = openChest.counts[i];

          openChest.items[i] = draggingItem;
          openChest.counts[i] = draggingCount;

          draggingItem = tmpItem;
          draggingCount = tmpCount;
        }
      }
      return;
    }
  }
}

void renderInventoryBackground() {
  imageMode(CENTER);
  image(inventoryTex, width/2, height/2);
}

void renderInventorySlots(float baseX, float baseY) {

  float startX = baseX - (INV_COLS - 1) * SLOT_SIZE / 2 + INV_SLOT_OFFSET_X;
  float startY = baseY - (INV_ROWS - 1) * SLOT_SIZE / 2 + INV_SLOT_OFFSET_Y;

  for (int y = 0; y < INV_ROWS; y++) {
    for (int x = 0; x < INV_COLS; x++) {

      float sx = startX + x * SLOT_SIZE;
      float sy = startY + y * SLOT_SIZE;

      int id = inventory[y][x];
      int count = inventoryCount[y][x];

      if (id != AIR) {
        PImage tex = getBlockTexture(id);
        if (tex != null) image(tex, sx, sy, 32, 32);
      }

      if (count > 1) {
        fill(255);
        textAlign(RIGHT, BOTTOM);
        textSize(14);
        text(count, sx + SLOT_SIZE/2 - 6, sy + SLOT_SIZE/2 - 6);
      }
    }
  }
}

void renderDraggedItem() {
  if (!isDragging || draggingItem == AIR) return;

  PImage tex = getBlockTexture(draggingItem);
  if (tex != null) {
    imageMode(CENTER);
    image(tex, mouseX, mouseY, 32, 32);

    if (draggingCount > 1) {
      fill(255);
      textAlign(RIGHT, BOTTOM);
      textSize(14);
      text(draggingCount, mouseX + 16, mouseY + 16);
    }
  }
}

void invalidateFoliageAbove(int x, int y) {
  int aboveY = y - 1;
  if (aboveY < 0) return;

  int id = currentTiles[x][aboveY];

  if ((id == GRASS_LEAVES || id == BUSH) && !hasSupportBelow(x, aboveY)) {
    currentTiles[x][aboveY] = AIR;
  }
}
