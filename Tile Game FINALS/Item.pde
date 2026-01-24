class ItemEntity {
  float x, y;
  float vx, vy;
  int id;
  int count;
  boolean alive = true;

  final float ITEM_HALF = 12; // half of 24px sprite
  final float GRAVITY = 0.4;
  final float FRICTION = 0.7;
  final float MAX_FALL_SPEED = 20;

  int pickupDelay = 30; // frames before item can be picked up

  ItemEntity(float x, float y, int id, int count, boolean instantPickup) {
    this.x = x;
    this.y = y;
    this.id = id;
    this.count = count;
  
    vx = random(-2, 2);
    vy = random(-4, -1);
  
    pickupDelay = instantPickup ? 0 : 30;
  }

  void update() {
    
    boolean inWater = false;

    int cx = int(x / TILE);
    int cy = int(y / TILE);
    
    if (cx >= 0 && cx < CHUNK_W && cy >= 0 && cy < CHUNK_H) {
      if (isWaterTile(cx, cy)) {
        inWater = true;
      }
    }

  
    // gravity
    if (inWater) {
      // buoyancy
      vy -= 0.15; // buoyant force
      vy *= 0.88; // vertical drag
      vx *= 0.90; // horizontal drag
    } else {
      vy += GRAVITY;
      vy = min(vy, MAX_FALL_SPEED);
    }

    float nextX = x + vx;
    // collision
    int leftTile = int((nextX - ITEM_HALF) / TILE);
    int rightTile = int((nextX + ITEM_HALF) / TILE);
    int topTile = int((y - ITEM_HALF + 1) / TILE);
    int botTile = int((y + ITEM_HALF - 1) / TILE);
  
    boolean hitWall = false;
  
    for (int ty = topTile; ty <= botTile; ty++) {
      if (ty < 0 || ty >= CHUNK_H) continue;
  
      if (vx > 0 && rightTile >= 0 && rightTile < CHUNK_W &&
          isSolidTile(rightTile, ty)) {
        x = rightTile * TILE - ITEM_HALF;
        hitWall = true;
        break;
      }
  
      if (vx < 0 && leftTile >= 0 && leftTile < CHUNK_W &&
          isSolidTile(leftTile, ty)) {
        x = (leftTile + 1) * TILE + ITEM_HALF;
        hitWall = true;
        break;
      }
    }
  
    if (hitWall) {
      vx = -vx * 0.85;
      if (abs(vx) < 0.15) vx = 0;
    } else {
      x = nextX;
    }
  
    float nextY = y + vy;
  
    int tileX = int(x / TILE);
    int tileY = int((nextY + ITEM_HALF) / TILE);
  
    if (tileX >= 0 && tileX < CHUNK_W &&
        tileY >= 0 && tileY < CHUNK_H &&
        isSolidTile(tileX, tileY)) {
  
      y = tileY * TILE - ITEM_HALF;
  
      if (vy > 1.5) {
        vy = -vy * 0.15;
      } else {
        vy = 0;
      }
  
      vx *= FRICTION;
    } else {
      y = nextY;
    }
  
    if (pickupDelay > 0) {
      pickupDelay--;
    } else if (dist(x, y, px, py) < 30) {
      if (addItemToInventory(id, count)) {
        alive = false;
        return;
      }
    }
  
    resolveInsideSolid();
  }
  
  // stop vertical motion cleanly
  void vyStop() {
    vy = 0;
  }
  
  void render() {
    PImage tex = getBlockTexture(id);
    if (tex == null) return;
  
    imageMode(CENTER);
  
    int tx = int(x / TILE);
    int ty = int(y / TILE);
  
    int L = 255;
    if (tx >= 0 && tx < CHUNK_W && ty >= 0 && ty < CHUNK_H) {
      L = lightMap[tx][ty];
    }
  
    image(tex, x, y, 24, 24);
    // when in dark places, item will be darker
    int darkness = 255 - L;
    darkness = constrain(darkness, 0, 180);
  
    if (darkness > 0) {
      fill(0, darkness);
      rectMode(CENTER);
      rect(x, y, 24, 24);
    }
  
    // stack count
    if (count > 1) {
      fill(255);
      textAlign(RIGHT, BOTTOM);
      textSize(12);
      text(count, x + 12, y + 12);
    }
  }
    
  void resolveInsideSolid() {
    if (true) return;
    int left = int((x - ITEM_HALF) / TILE);
    int right = int((x + ITEM_HALF) / TILE);
    int top = int((y - ITEM_HALF) / TILE);
    int bottom = int((y + ITEM_HALF) / TILE);
  
    // bounds check
    if (left < 0 || right >= CHUNK_W || top < 0 || bottom >= CHUNK_H) return;
  
    if (isSolidTile(left,  top) &&
        isSolidTile(right, top) &&
        isSolidTile(left,  bottom) &&
        isSolidTile(right, bottom)) {
  
      for (int i = 0; i < TILE; i++) {
  
        top = int((y - ITEM_HALF) / TILE);
        bottom = int((y + ITEM_HALF) / TILE);
  
        if (top < 0 || bottom >= CHUNK_H) break;
  
        if (isSolidTile(left, top) &&
            isSolidTile(right, top) &&
            isSolidTile(left, bottom) &&
            isSolidTile(right, bottom)) {
  
          y -= 1;
          vy = 0;
  
        } else {
          break;
        }
      }
    }
  }


  void resolveGroundSnap() {
    int tx = int(x / TILE);
    if (tx < 0 || tx >= CHUNK_W) return;
  
    int ty = int((y + ITEM_HALF) / TILE);
    if (ty < 0 || ty >= CHUNK_H) return;
  
    if (!isSolidTile(tx, ty)) return;
  
    for (int i = 0; i < TILE; i++) {
      ty = int((y + ITEM_HALF) / TILE);
      if (ty < 0 || ty >= CHUNK_H) break;
  
      if (isSolidTile(tx, ty)) {
        y -= 1;
      } else {
        break;
      }
    }
  
    ty = int((y + ITEM_HALF) / TILE);
    if (ty >= 0 && ty < CHUNK_H && isSolidTile(tx, ty)) {
      y = ty * TILE - ITEM_HALF;
    }
  
    vy = 0;
  }
}
// reused function as player to check if it floats in water
boolean isPlayerInWater() {
  int cx = int(px / TILE);
  int cy = int(py / TILE);

  if (cx < 0 || cx >= CHUNK_W || cy < 0 || cy >= CHUNK_H) return false;
  return currentTiles[cx][cy] == WATER;
}
