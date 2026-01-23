# 2D-Minecraft-Game
DISCLAIMER: Turns out the water script broke while implimenting a new feature today so assume the water flows like lava

FEATURES: 
17 Blocks, 2 Liquids
Chest can store items and if broken they will drop their items

Items are dropped when blocks are broken and float in water (I did not have time to add floating compatibility with lava)

There is randomly generating terrain in which manipulating the world seed would yeild different terrain types

There is infinite terrain in BOTH the horizontal and vertical direction. If you go left or right enough you can see a "wall" and pass through it. The same goes for up and down. However, there is a hard limit for going below bedrock.

There is one structure which is the tree

There is an lighting system

There is a cave system, and lava and water SHOULD generate in caves

There is ore generation (different ores generate at different y levels)

Collision is made without any external libary like fisica

All textures except for crafting table, leaves, grass leaves, and gui, are made by hand

Pressing '0' allows the player to enter "creative mode"

Pressing "@S" saves a .json file of your world inside of the "worlds" folder, though I havent added a load feature yet

There is an inventory GUI, press "e" to open it. You can drag items around in the inventory

UNFINISHED FEATURES:

I tried to add a save and load world feature. I have experience doing this in Unity C# for my games. Saving works but loading dosent work and I am out of time so I cant fix it. I tried to ask someone else to help me but that got didnt solve the issue

The lighting system is bugged at the edges of each chunk (blocks appear too dark)

I planned to add a crafting system as seen with the crafting table GUI and block but I ran out of time.


ANSWERS TO QUESTIONS:

The hardest part of this project is implimenting the lighting system and working on this project while having finals and tests in other classes since its towards the end of the semester. The second hardest would be the water system in which the water should slope. The third hardest problem would be the terrain generation.
The most annoying problem would be when there is a null pointer exception during runtime, especially in cases where a single change can trigger a domino effect in the code. Processing dosent display which line is causing the issue which is very annoying and I overcomed this by resorting to ai to tell me where it is.

I overcomed the lighting system challenge by just spending more time on it and checking how other people made their own 2d lighting system. I overcomed the water texture problem by removing the water texture all together and made water be drawn in-game and the verticies manually drawn for the slope effect (flowing water). I overcomed the terrain generation by making it use perlin noise instead of a combanation of sin and cos to generate the general terrain shape.

I learned the most at HashMaps<> since before, I never used them. In the game, they are vital to the 2d infinite chunk system,

I am most proud of the infinte terrain generation, espciacally at how smooth it is in which the player can just jump from one chunk to another and the terrain would carry on.
