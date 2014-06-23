SGG_SKSpineImport
=================

This is a library to import json animations created in Esoteric Software's Spine application.

DISCLAIMER:

I have no affiliation with esoteric Software whatsoever and built this runtime without the use of their supplied starting point. I am still relatively new to this whole *programming* thing and therefore may not have implemented everything in the most efficient or optimized manner. Therefore, I will not be held responsible for problems pertaining to this runtime in any way. Also, don't make fun of things that I didn't do right please. I have feelings! If something could be done in a better way, that's the reason I open sourced this. Feel free to make changes and go through whatever process there is to get them up here (I haven't collaborated on github yet, so I'm not exactly sure of the process yet). And finally, in all sincerity, I hope that this project either helps you or makes your life a little easier. :)

Usage:

Examples and shortcomings can be viewed by building the project. It's configured to demo for OS X, but builds for iOS and can be reconjiggered to use iOS controls.

Import the entire SpineImporter folder to your project. Add the following line to the header of whatever you need to add the runtime to:

	#import "SpineImport.h"
	
Create spine objects as such:

	SGG_Spine* boy = [SGG_Spine node];
	[boy skeletonFromFileNamed:@"spineboy" andAtlasNamed:@"spineboy" andUseSkinNamed:Nil];
	boy.position = CGPointMake(self.size.width/4, self.size.height/4);
	[boy runAnimation:@"walk" andCount:-1];
	boy.queueCount = -1;
	boy.queuedAnimation = @"walk";
	boy.queueIntro = 0.1;
	boy.zPosition = 0;
	[self addChild:boy];
	
More examples are contained in the project. I believe it should be fairly straightforward.

To import image assets, you must add the ORIGINAL image files to your project in an Xcode atlas file. Atlases created by Spine or third parties are unsupported.

Features:

*   Import Spine animations
*	Handles fairly easily
*	Support for multiple skins on a skeleton (click to see the alt goblin skin, using the same skeleton)
	*	Also supports partial replacement (e.g. just hands)
*	Start and stop animation
*	Slot Animation
*	Rudimentary support for easy ease keyframes
*	Z Ordering
*	Queue system for animation (when you jump, it will automatically return to running/walking when the animation finishes)
*	Animations can be transitioned into each other (as opposed to hard cutting from one to the other)
*	Builds for OS X and iOS


Limitations:

*	Slot animation gets confused when you switch skins during an animation (in the example build, hold the mouse down for a while, then let go and watch the goblin eyes)
~~*	Animation is built using SKAction - therefore, easing of keyframes is limited to the simple enumerated versions of easy ease that SKAction includes (ease in, ease out, ease both, linear)
	*	This runtime automatically detects the closest approximation and applies it, however~~
*	Z order keyframes are NOT implemented
*	Mixing animation (have your feet walking while your arms swing a weapon, for example) is not implemented.
*	Requires using the built in atlas managment.
*	Notice how the elf stays down and doesn't reset his animation. I'm not sure why that is.
*	Can't have slashes (/) in image names



Requirements:

*	Xcode 5+
*	SpriteKit project

Target requirements:

*	iOS 7+
or 
*	Mac OS X 10.9+ or whatever SpriteKit's requirements are. I'm not 100% sure and I don't care enough to look them up just for this. I'm not your mom.


## Merge from 
https://github.com/massivepenguin/SGG_SKSpineImport

Added three methods:


## changeSkinPartial
*Accepts: (NSMutableDictionary *)slotsToReplace*

**Dictionary format:**
>slot name : replacement skin name

Replaces the texture of any nodes mentioned in the slotsToReplace dictionary with their accompanying textures.

Created to serve my own needs: I have an avatar builder in my Sprite Kit game, and I need to swap out specific slots without changing the whole skin (so the player can choose different shirts, pants etc.).

### Usage:

```
NSDictionary* partReplacement = @{@"torso": @"goblin", @"head": @"goblin"};

[goblin changeSkinPartial:partReplacement];
```


### Limitations:
* Your dictionary's keys must match the slot names specified in the skeleton's .json file.
* If you need to replace any 'nested' nodes, you must create an entry for that slot in your dictionary.



## resetSkinPartial
Resets any changes made through changeSkinPartial; reverts the skeleton back to the textures used when the scene was created.
Should only be called after changeSkinPartial.


## colorizeSlots
*Accepts: (NSArray *)slotsToColorize withColor:(SKColor *)color andIntensity:(CGFloat)blendFactor*

Colorizes the slots listed in the slotsToColorize array using the specified color and blend factor.
*Note: be sure to use the attatchment name, not the slot name.*

Can be used to make a body part flash red, or to let the player change their hair/skin color.

### Usage:
```
NSArray* partsToColorize = @[@"head", @"left-shoulder", @"torso"];
SKColor* color = [SKColor redColor];
[boy colorizeSlots:partsToColorize withColor:color andIntensity:1];
```

### Limitations:
* Your array's values must match the slot names specified in the skeleton's .json file.
* If you need to colorize any 'nested' nodes, you must create an entry for that slot in your dictionary.


## Questions or comments?
Let me know!
