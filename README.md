SGG_SKSpineImport
=================

This is a library to import json animations created in Esoteric Software's Spine application.


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
*	Start and stop animation
*	Slot Animation
*	Rudimentary support for easy ease keyframes
*	Z Ordering
*	Queue system for animation (when you jump, it will automatically return to running/walking when the animation finishes)
*	Animations can be transitioned into each other (as opposed to hard cutting from one to the other)
*	Builds for OS X and iOS


Limitations:

*	Slot animation gets confused when you switch skins during an animation (in the example build, hold the mouse down for a while, then let go and watch the goblin eyes)
*	Animation is built using SKAction - therefore, easing of keyframes is limited to the simple enumerated versions of easy ease that SKAction includes (ease in, ease out, ease both, linear)
	*	This runtime automatically detects the closest approximation and applies it, however
*	Z order keyframes are implemented
*	Mixing animation (have your feet walking while your arms swing a weapon, for example) is not implemented.
*	Requires using the built in atlas managment.


Requirements:

*	Xcode 5+
*	SpriteKit project

Target requirements:

*	iOS 7+
or 
*	Mac OS X 10.9+ or whatever SpriteKit's requirements are. I'm not 100% sure and I don't care enough to look them up just for this. I'm not your mom.