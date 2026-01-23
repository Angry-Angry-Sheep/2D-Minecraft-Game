import fisica.*;
import java.util.ArrayList;
import processing.data.JSONObject;
import processing.data.JSONArray;

color blue = color(29,178,242);
color brown = color(166,120,24);
color green = color(74,163,57);
color red = color(224,80,61);
color yellow = color(242,215,16);
color orange = color(255,140,0);

FWorld world;
ArrayList<FPoly> platforms = new ArrayList<FPoly>();
ArrayList<RotatingPlatform> rotatingPlatforms = new ArrayList<RotatingPlatform>();
ArrayList<FPoly> deadlyPlatforms = new ArrayList<FPoly>();
ArrayList<FPoly> noJumpPlatforms = new ArrayList<FPoly>();

FBlob player;
float spawnX = 200;
float spawnY = 100;

ArrayList<FCircle> coins = new ArrayList<FCircle>();
ArrayList<CoinParticle> coinParticles = new ArrayList<CoinParticle>();
int coinsCollected = 0;
int totalCoins = 0;

FPoly goalFlag;
boolean levelComplete = false;

boolean leftPressed = false;
boolean rightPressed = false;
boolean upPressed = false;

float moveForce = 200;
float jumpForce = -4000;
boolean jumpReady = true;
int groundContacts = 0;

float camX = 0;
float camY = 0;
float camSmooth = 0.1;

float spinT = 0;

boolean queuedDeath = false;

final int STATE_MENU = 0;
final int STATE_LEVEL = 1;
final int STATE_COMPLETE = 2;

int gameState = STATE_MENU;


int currentLevel = 1;
String[] levelFiles = {
  "level1.json",
  "level2.json",
  "level3.json"
};

int[] levelStars = {0, 0, 0};  // 0–3 stars per level

float levelStartTime = 0;
float levelEndTime   = 0;

class Button {
  boolean hovered = false;
  boolean pressed = false;
  float anim = 0;   // goes from 0 to 1, used for smooth animation
  float x, y, w, h;
  String label;

  Button(float x, float y, float w, float h, String label) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.label = label;
  }

  void draw() {
  // update hover status
  hovered = (mouseX > x - w/2 && mouseX < x + w/2 &&
             mouseY > y - h/2 && mouseY < y + h/2);

  // smooth animation: anim -> 1 when hovered, anim -> 0 when not
  float target = hovered ? 1 : 0;
  anim = lerp(anim, target, 0.15);

  // scale effect on hover
  float scale = 1 + anim * 0.05;

  pushMatrix();
  translate(x, y);
  scale(scale);

  // background glow
  noStroke();
  fill(255, 100 + anim * 120);
  rectMode(CENTER);
  rect(0, 0, w, h, 20);

  // inner shadow gets stronger when hovered
  fill(255, 240);
  rect(0, 0, w - anim * 10, h - anim * 10, 20);

  // text pops up
  fill(0);
  textAlign(CENTER, CENTER);
  textSize(32 + anim * 3);
  text(label, 0, 0);
  
  if (pressed) {
  anim = lerp(anim, 0, 0.3);
  if (anim < 0.05) pressed = false;
}


  popMatrix();
}


boolean clicked(float mx, float my) {
  boolean hit = (mx > x - w/2 && mx < x + w/2 &&
                 my > y - h/2 && my < y + h/2);

  if (hit) {
    pressed = true;
    anim = 1;
  }

  return hit;
}

}

Button btnL1, btnL2, btnL3;
Button btnNextLevel, btnExit;

class CoinParticle {
  float x, y;
  float vx, vy;
  float life = 1.0;
  float size;

  CoinParticle(float px, float py) {
    x = px;
    y = py;

    float angle = random(TWO_PI);
    float speed = random(3, 7);

    vx = cos(angle) * speed;
    vy = sin(angle) * speed;

    size = random(6, 12);
  }

  boolean update() {
    x += vx;
    y += vy;

    vy += 0.2; // gravity-like drop

    size *= 0.93;
    life -= 0.04;

    return life <= 0 || size < 1;
  }

  void drawParticle() {
    noStroke();
    fill(255, 230, 60, life * 255);
    ellipse(x, y, size, size);
  }
}

class RotatingPlatform {
  FPoly body;
  float baseAngle, speed;

  RotatingPlatform(FPoly b, float base, float spd) {
    body = b;
    baseAngle = base;
    speed = spd;
    body.setStatic(true);
  }

  void update(float t) {
    float ang = baseAngle + speed * t;
    body.setRotation(radians(ang));
  }
}

void setup() {
  size(1000, 800);

  Fisica.init(this);
  world = new FWorld(-100000, -100000, 100000, 100000);
  world.setGravity(0, 1400);

  createButtons();
  gameState = STATE_MENU;
}

void createButtons() {
  btnL1 = new Button(width/2, 300, 300, 80, "Play Level 1");
  btnL2 = new Button(width/2, 420, 300, 80, "Play Level 2");
  btnL3 = new Button(width/2, 540, 300, 80, "Play Level 3");

  btnNextLevel = new Button(width/2, height/2 + 120, 300, 80, "Next Level");
  btnExit      = new Button(width/2, height/2 + 220, 300, 80, "Exit to Menu");
}

void draw() {
  background(blue);

  if (gameState == STATE_MENU) {
    drawMenu();
    return;
  }

  if (gameState == STATE_LEVEL) {
    runLevel();
    return;
  }

  if (gameState == STATE_COMPLETE) {
    drawCompletionScreen();
    return;
  }
}

void drawMenu() {
  background(blue);

  fill(255);
  textAlign(CENTER, CENTER);
  textSize(70);
  text("PLATFORMER GAME", width/2, 150);

  textSize(20);
  text("Use A / D / W or Arrow Keys to Move and Jump", width/2, 210);

  // Draw buttons
  btnL1.draw();
  btnL2.draw();
  btnL3.draw();

  // Draw stars under each button
  drawStars(width/2, 360, levelStars[0]);
  drawStars(width/2, 480, levelStars[1]);
  drawStars(width/2, 600, levelStars[2]);
}

void drawStars(float x, float y, int stars) {
  pushMatrix();
  translate(x, y);
  float spacing = 45;

  for (int i = 0; i < 3; i++) {
    pushMatrix();
    translate((i - 1) * spacing, 0);

    if (i < stars) {
      fill(255, 220, 0);   // filled star
    } else {
      noFill();
    }

    stroke(255, 220, 0);
    strokeWeight(3);

    drawStar(0, 0, 12, 25, 5);
    popMatrix();
  }

  popMatrix();
}
void drawStar(float x, float y, float radius1, float radius2, int npoints) {
  float angle = TWO_PI / npoints;
  float halfAngle = angle / 2.0;

  beginShape();
  for (float a = 0; a < TWO_PI; a += angle) {
    float sx = x + cos(a) * radius2;
    float sy = y + sin(a) * radius2;
    vertex(sx, sy);
    sx = x + cos(a + halfAngle) * radius1;
    sy = y + sin(a + halfAngle) * radius1;
    vertex(sx, sy);
  }
  endShape(CLOSE);
}


void runLevel() {
  if (queuedDeath) {
    death();
    queuedDeath = false;
  }

  updateMovement();
  world.step();

  // Update rotating platforms
  spinT += 1;
  for (RotatingPlatform rp : rotatingPlatforms) {
    rp.update(spinT);
  }

  // Camera follow
  PVector c = getBlobCenter(player);
  camX += (width/2 - c.x - camX) * camSmooth;
  camY += (height/2 - c.y - camY) * camSmooth;

  // Death if falling too far
  if (c.y > 1000) {
    death();
    return;
  }

  // Apply camera
  pushMatrix();
  translate(camX, camY);

  world.draw();
  drawCoins();
  drawParticles();

  popMatrix();

  // If levelComplete flag set by collisions, move to complete screen
  if (levelComplete) {
    levelEndTime = (millis() - levelStartTime) / 1000.0;

    // Assign stars based on coins collected
    int stars = calculateStars();
    levelStars[currentLevel - 1] = max(levelStars[currentLevel - 1], stars);

    gameState = STATE_COMPLETE;
  }
}

void drawCompletionScreen() {
  background(0, 0, 0, 180);

  fill(255);
  textAlign(CENTER, CENTER);
  textSize(70);
  text("LEVEL COMPLETE!", width/2, 200);

  textSize(40);
  text("Time: " + nf(levelEndTime, 1, 2) + " s", width/2, 280);
  text("Coins: " + coinsCollected + " / " + totalCoins, width/2, 340);
  text("Stars: " + levelStars[currentLevel - 1] + " / 3", width/2, 400);

  if (currentLevel < levelFiles.length) {
    btnNextLevel.label = "Next Level";
  } else {
    btnNextLevel.label = "Play Again";
  }

  btnNextLevel.draw();
  btnExit.draw();
}

int calculateStars() {
  if (coinsCollected == 0) return 1;
  if (coinsCollected < totalCoins) return 2;
  return 3;
}

void drawCoins() {
  float shimmer = sin(frameCount * 0.1);
  for (FCircle coin : coins) {
    pushMatrix();
    translate(coin.getX(), coin.getY());
    noStroke();

    // outer gold
    fill(255, 200, 40);
    ellipse(0, 0, 26, 26);

    // inner shimmer
    float innerSize = 20 + shimmer * 2;
    fill(255, 240, 80);
    ellipse(0, 0, innerSize, innerSize);

    popMatrix();
  }
}

void drawParticles() {
  for (int i = coinParticles.size() - 1; i >= 0; i--) {
    CoinParticle p = coinParticles.get(i);
    p.drawParticle();
    if (p.update()) {
      coinParticles.remove(i);
    }
  }
}

boolean isOnGround() {
  return groundContacts > 0;
}

void updateMovement() {
  if (leftPressed)  player.addForce(-moveForce, 0);
  if (rightPressed) player.addForce( moveForce, 0);

  if (upPressed && isOnGround() && jumpReady) {
    player.addForce(0, jumpForce);
    jumpReady = false;
  }
}

void makePlayer() {
  player = new FBlob();
  player.setAsCircle(spawnX, spawnY, 40);
  player.setFillColor(yellow);
  player.setDensity(1);
  player.setFriction(0.05);
  player.setStroke(0);
  player.setRestitution(0.1);
  world.add(player);
}

void death() {
  if (player != null) {
    world.remove(player);
  }
  makePlayer();
  groundContacts = 0;
  jumpReady = true;

  // Reset camera to player
  PVector c = getBlobCenter(player);
  camX = width/2 - c.x;
  camY = height/2 - c.y;
}

void loadLevel(String filename) {
  JSONObject json = loadJSONObject(filename);

  world.clear();
  platforms.clear();
  deadlyPlatforms.clear();
  noJumpPlatforms.clear();
  rotatingPlatforms.clear();
  coins.clear();
  coinParticles.clear();
  levelComplete = false;
  coinsCollected = 0;

  world.setGravity(0, 1400);
  world.setEdges(-100000, -100000, 100000, 100000);

  // Player spawn
  JSONArray sp = json.getJSONArray("playerSpawn");
  spawnX = sp.getFloat(0);
  spawnY = sp.getFloat(1);
  makePlayer();

  // Coins
  JSONArray coinArr = json.getJSONArray("coins");
  for (int i = 0; i < coinArr.size(); i++) {
    JSONObject c = coinArr.getJSONObject(i);
    coins.add(createCoin(c.getFloat("x"), c.getFloat("y")));
  }
  totalCoins = coins.size();

  // Flag
  JSONObject fl = json.getJSONObject("flag");
  goalFlag = createFlag(fl.getFloat("x"), fl.getFloat("y"));

  // Platforms
  JSONArray plats = json.getJSONArray("platforms");
  for (int i = 0; i < plats.size(); i++) {
    JSONObject p = plats.getJSONObject(i);

    float x   = p.getFloat("x");
    float y   = p.getFloat("y");
    float rot = p.getFloat("rot");
    int col   = parseColor(p.getString("color"));

    float fric    = p.getFloat("friction");
    boolean stat  = p.getBoolean("static");
    boolean deadly = p.getBoolean("deadly");
    boolean noJump = p.getBoolean("noJump");

    Float rotSpeed  = p.isNull("rotSpeed")  ? null : p.getFloat("rotSpeed");
    Float baseAngle = p.isNull("baseAngle") ? null : p.getFloat("baseAngle");

    // Vertices
    JSONArray vertsArr = p.getJSONArray("verts");
    float[][] verts = new float[vertsArr.size()][2];

    for (int v = 0; v < vertsArr.size(); v++) {
      JSONArray pair = vertsArr.getJSONArray(v);
      verts[v][0] = pair.getFloat(0);
      verts[v][1] = pair.getFloat(1);
    }

    // Create platform
    FPoly poly = createPlatform(x, y, rot, verts, col, fric, stat);
    platforms.add(poly);

    if (deadly)  deadlyPlatforms.add(poly);
    if (noJump)  noJumpPlatforms.add(poly);

    if (rotSpeed != null) {
      RotatingPlatform rp = new RotatingPlatform(poly, baseAngle, rotSpeed);
      rotatingPlatforms.add(rp);
    }
  }

  // Initial camera
  PVector c = getBlobCenter(player);
  camX = width/2 - c.x;
  camY = height/2 - c.y;
}

FPoly createPlatform(float posX, float posY, float rotDeg, float[][] verts, int col, float fric, boolean stat) {
  FPoly p = new FPoly();
  for (float[] v : verts) {
    p.vertex(v[0], v[1]);
  }

  p.setStatic(stat);
  p.setFillColor(col);
  p.setFriction(fric);

  world.add(p);
  p.setPosition(posX, posY);
  p.setRotation(radians(rotDeg));

  return p;
}

FCircle createCoin(float x, float y) {
  FCircle c = new FCircle(20);
  c.setPosition(x, y);

  c.setFillColor(color(255, 220, 40));
  c.setStroke(0);
  c.setStatic(true);
  c.setSensor(true);

  world.add(c);
  return c;
}

FPoly createFlag(float x, float y) {
  FPoly f = new FPoly();
  f.vertex(-10, -50);
  f.vertex(10, -50);
  f.vertex(10, 50);
  f.vertex(-10, 50);
  f.setStatic(true);
  f.setFillColor(color(255, 0, 200));
  world.add(f);
  f.setPosition(x, y);
  return f;
}

int parseColor(String name) {
  if (name.equals("brown"))  return brown;
  if (name.equals("green"))  return green;
  if (name.equals("red"))    return red;
  if (name.equals("yellow")) return yellow;
  if (name.equals("orange")) return orange;
  return brown;
}

void keyPressed() {
  if (gameState != STATE_LEVEL) return;

  if (key == 'a' || keyCode == LEFT)  leftPressed  = true;
  if (key == 'd' || keyCode == RIGHT) rightPressed = true;
  if (key == 'w' || keyCode == UP)    upPressed    = true;
}

void keyReleased() {
  if (gameState != STATE_LEVEL) return;

  if (key == 'a' || keyCode == LEFT)  leftPressed  = false;
  if (key == 'd' || keyCode == RIGHT) rightPressed = false;
  if (key == 'w' || keyCode == UP) {
    upPressed = false;
    jumpReady = true;
  }
}

void mousePressed() {
  if (gameState == STATE_MENU) {
    if (btnL1.clicked(mouseX, mouseY)) startLevel(1);
    else if (btnL2.clicked(mouseX, mouseY)) startLevel(2);
    else if (btnL3.clicked(mouseX, mouseY)) startLevel(3);
  } else if (gameState == STATE_COMPLETE) {
    if (btnNextLevel.clicked(mouseX, mouseY)) {
      if (currentLevel < levelFiles.length) {
        startLevel(currentLevel + 1);
      } else {
        gameState = STATE_MENU;
      }
    }
    if (btnExit.clicked(mouseX, mouseY)) {
      gameState = STATE_MENU;
    }
  }
}

void startLevel(int lvl) {
  currentLevel = constrain(lvl, 1, levelFiles.length);
  loadLevel(levelFiles[currentLevel - 1]);
  levelComplete = false;
  queuedDeath = false;
  levelStartTime = millis();
  gameState = STATE_LEVEL;
}

void contactStarted(FContact c) {
  FBody a = c.getBody1();
  FBody b = c.getBody2();

  boolean aIsPlayer = (a == player || a.getParent() == player);
  boolean bIsPlayer = (b == player || b.getParent() == player);
  boolean playerInvolved = aIsPlayer || bIsPlayer;

  // DEADLY
  for (FPoly p : deadlyPlatforms) {
    if ((a == p || b == p) && playerInvolved) {
      queuedDeath = true;
      return;
    }
  }

  // No Jump
  for (FPoly p : noJumpPlatforms) {
    if ((a == p || b == p) && playerInvolved) {
      return;
    }
  }

  // COIN COLLECTION
  for (int i = coins.size() - 1; i >= 0; i--) {
    FCircle coin = coins.get(i);
    if ((a == coin || b == coin) && playerInvolved) {
      for (int k = 0; k < 15; k++) {
        coinParticles.add(new CoinParticle(coin.getX(), coin.getY()));
      }
      world.remove(coin);
      coins.remove(i);
      coinsCollected++;
    }
  }

  // GOAL FLAG
  if ((a == goalFlag || b == goalFlag) && playerInvolved) {
    if (!levelComplete) {
      levelComplete = true;
    }
  }

  // NORMAL GROUND CONTACT
  if (!playerInvolved) return;

  for (FPoly p : platforms) {
    if (a == p || b == p) {
      // do not count deadly platforms as ground
      if (!deadlyPlatforms.contains(p)) {
        groundContacts++;
      }
    }
  }
}

void contactEnded(FContact c) {
  FBody a = c.getBody1();
  FBody b = c.getBody2();

  boolean aIsPlayer = (a == player || a.getParent() == player);
  boolean bIsPlayer = (b == player || b.getParent() == player);

  if (!aIsPlayer && !bIsPlayer) return;

  for (FPoly p : platforms) {
    if (a == p || b == p) {
      if (!deadlyPlatforms.contains(p)) {
        groundContacts--;
        if (groundContacts < 0) groundContacts = 0;
      }
    }
  }
}

PVector getBlobCenter(FBlob blob) {
  if (blob == null) return new PVector(width/2, height/2);
  
  // getVertexBodies() isn't listed in fisica's documentation. This function can allow for future people to make platformers out of FBlobs
  ArrayList bodies = blob.getVertexBodies();
  int n = bodies.size();
  if (n == 0) return new PVector(width/2, height/2);

  float sx = 0, sy = 0;
  for (int i = 0; i < n; i++) {
    FBody b = (FBody)bodies.get(i);
    sx += b.getX();
    sy += b.getY();
  }
  return new PVector(sx / n, sy / n);
}
