SGG_SKSpineImport
=================

This is a library to import json animations created in Esoteric Software's Spine application.

DISCLAIMER:

I have no affiliation with esoteric Software whatsoever and built this runtime without the use of their supplied starting point. I am still relatively new to this whole *programming* thing and therefore may not have implemented everything in the most efficient or optimized manner. Therefore, I will not be held responsible for problems pertaining to this runtime in any way. Also, if something could be done in a better way, that's the reason I open sourced this. Feel free to make changes and make a pull request.

And finally, in all sincerity, I hope that this project either helps you or makes your life a little easier. :)

Usage:

Examples and shortcomings can be viewed by building the project. It's configured to demo for OS X, but builds for iOS and can be reconjiggered to use iOS controls.

Import the entire SpineImporter folder to your project. Add the following line to the header of whatever you need to add the runtime to:

	#import "SpineImport.h"
	
Create spine objects as such:

	boy = [SGG_Spine node];
	[boy skeletonFromFileNamed:@"spineboy" andAtlasNamed:@"spineboy" andUseSkinNamed:Nil];
	boy.position = CGPointMake(self.size.width/4, self.size.height/4);
	boy.queuedAnimation = @"walk";
	boy.queueIntro = 0.1;
	[boy runAnimation:@"walk" andCount:0 withIntroPeriodOf:0.1 andUseQueue:YES];
	boy.zPosition = 0;
	[self addChild:boy];

And then the animations must be "activated" for each spine object in the update method of the scene:

	[boy activateAnimations];
	
More examples are contained in the project. I believe it should be fairly straightforward.

To import image assets, you must add the ORIGINAL image files to your project in an Xcode atlas file. Atlases created by Spine or third parties are unsupported.

Features:

*   Import Spine animations
*	Handles fairly easily
*	Support for multiple skins on a skeleton (click to see the alt goblin skin, using the same skeleton)
	*	Also supports partial replacement (e.g. just hands)
*	Start and stop animation
*	Slot Animation
*	Z Ordering (but not animation)
*	Queue system for animation (when you jump, it will automatically return to running/walking when the animation finishes)
*	Animations can be transitioned into each other (as opposed to hard cutting from one to the other)
*	**Supports non linear keyframe timing modes**
*	**Supports differing playback speeds**

*	Builds for OS X and iOS


Limitations:

*	~~Slot animation gets confused when you switch skins during an animation (in the example build, hold the mouse down for a while, then let go and watch the goblin eyes)~~
*	~~Animation is built using SKAction - therefore, easing of keyframes is limited to the simple enumerated versions of easy ease that SKAction includes (ease in, ease out, ease both, linear)~~
	*	~~This runtime automatically detects the closest approximation and applies it, however~~ See above
*	Z order keyframes are NOT implemented
*	Mixing animation (have your feet walking while your arms swing a weapon, for example) is not implemented.
*	Requires using the built in atlas management.
*	Notice how the elf stays down and doesn't reset his animation. I'm not sure why that is. I'm suspecting that the animation file itself is wonky, but I haven't delved into it.
*	Can't have slashes (/) in image names
*	I'm not sure if the animation sequence vs queuing system order of operations is the most efficient or logical or if another configuration would be superior.
	*	Currently, the priority is 
		1.	runAnimation method (called directly)
		2.	running the next animation in a sequence
		3.	running whatever animation is queued for repeat



Requirements:

*	Xcode 5+
*	SpriteKit project

Target requirements:

*	iOS 7+
or 
*	Mac OS X 10.9+ or whatever SpriteKit's requirements are. I'm not 100% sure and I don't care enough to look them up just for this. I'm not your mom.


## Method and Property Highlights

#### debugMode *property*
When set to YES, prints debug information in NSLog and shows a frame counter on the animation

#### isRunningAnimation *property*
Readonly BOOL that can tell you if an animation is currently running.

#### currentAnimationSequence *property*
If there is a sequence of animations running, this is an NSArray that will list their names. Will be nil if there is no sequence running. Does not activate for queued animations.

#### currentAnimation *property*
When an animation is running, this will be a read only NSString that will tell you the name of the current animation.

#### animationCount *property*
If an animation is set to repeat X number of times (before resorting to the queue or stopping), this will return the amount of times remaining.

#### queuedAnimation *property*
Use this NSString to set the queued animation to run after the current animation finishes. (Example, set this to "walk" to always walk, but transition to "jump" anytime a button is pressed).

#### queueIntro *property*
CGFloat value in seconds (affected by playbackSpeed) to transition from the previous animation to the queued animation. Will be ignored if the queued animation is the same as the previous animation that completed.

#### useQueue *property*
BOOL value that can be toggled to turn animation queuing on and off.

#### timeResolution *property*
CGFloat value to determine the "framerate" at which animations should be calculated. Default value is 1/120. This doesn't affect the playback speed.

For example, at 1/120 and a framerate of 1/60, the playback will skip approximately every other frame. The reason it's at 1/120 is to create smoother playback in the event of unevenly timed rendering of frames. It could very likely be lowered to 1/60 and see no harm.

If you intend to use slower motion, you will need more granularity and should set it to a "higher" denominator value.

#### playbackSpeed *property*
CGFloat value to determine how fast to play back the animation. *Can* be ramped, but you may notice stuttering.

#### currentFrame *property*
Read only NSInteger value to tell you what the currentFrame of animation being displayed is.


#### -skeletonFromFileNamed:andAtlasNamed:andUseSkinNamed:
Since the object will already have been created with a line such as

	spineSkeleton = [SGG_Spine node];

this method is used to set up the attachments, animations, bones, and all the other cool stuff Spine lets you do. This should be done AFTER the following property(ies) are set:

*	timeResolution

-(void)skeletonFromFileNamed:(NSString\*)name andAtlasNamed:(NSString\*)atlasName andUseSkinNamed:(NSString*)skinName;

###### Parameters
*	*name*
	*	NSString naming the file the skeleton resides in
*	*atlasName*
	*	NSString naming the .atlas file to pull imagery from
*	*skinName*
	*	NSString naming the skin to use. Defaults to "default" if nil.



#### -runAnimation:andCount:withIntroPeriodOf:andUseQueue:
Sets the spine object to play back the animation with the name you provide.

-(void)runAnimation:(NSString*)animationName andCount:(NSInteger)count withIntroPeriodOf:(const CGFloat)introPeriod andUseQueue:(BOOL)useQueue;

###### Parameters
*	*animationName*
	*	NSString value of animation to play back
*	*count*
	*	NSInteger value of number of times to repeat the animation (0 plays once, 1 plays twice)
*	*introPeriod*
	*	CGFloat value in seconds of duration to transition from the current status to the start of the new animation
*	*useQueue*
	*	BOOL value to determine whether to return to the queued animation after this animation finishes


#### -runAnimation:andCount:

-(void)runAnimation:(NSString*)animationName andCount:(NSInteger)count;

This is a shorthand of the previous method. Uses current setting for "useQueue".

###### Parameters
*	*animationName*
	*	NSString value of animation to play back
*	*count*
	*	NSInteger value of number of times to repeat the animation (0 plays once, 1 plays twice)
	
#### -runAnimationSequence:andUseQueue:
-(void)runAnimationSequence:(NSArray *)animationNames andUseQueue:(BOOL)useQueue;

Creates a sequence of animations with no transitions between them.

###### Parameters
*	*animationNames*
	*	NSArray of NSStrings naming the animations in order of playback
*	*useQueue*
	*	BOOL value to determine whether to return to the queued animation after this animation finishes

#### -stopAnimation

-(void)stopAnimation;

Stops the current animation (if there is one).

#### -jumpToFrame:
-(void)jumpToFrame:(NSInteger)frame;

Stops animation and jumps to a frame in the animation.

###### Parameters
*	*frame*
	*	NSInteger value of frame to jump to. Remember to take into account the timeResolution.
	
#### -jumpToNextFrame

Stops animation (if running) and jumps to the next frame. Remember to take into account the timeResolution.

#### -jumpToPreviousFrame

Stops animation (if running) and jumps to the previous frame. Remember to take into account the timeResolution.

#### -activateAnimations

Required method to playback animations. Must run every frame of the app (at least when animations are supposed to run), so it's best to put it in the scene update method.

#### -resetSkeleton
Resets the spine object back to its default state.

#### -changeSkinTo
-(void)changeSkinTo:(NSString*)skin;

Changes the current skin of the entire spine object to a new skin.

###### Parameters
*	*skin*
	*	NSString value name of the skin you want to change to
	

#### -changeSkinPartial:
-(void)changeSkinPartial:(NSDictionary *)slotsToReplace;

Replaces the skin of any nodes mentioned in the slotsToReplace dictionary with their accompanying skins.

###### Parameters
*	*slotsToReplace*
	*	NSDictionary with keys as the names of the slots you want to change and the value being the name of the skin to change to. Example:

```
	NSDictionary* partReplacement = @{@"part": @"skinName", @"torso": @"goblin", @"head": @"goblin"};
	[goblin changeSkinPartial:partReplacement];
```

#### -resetSkinPartial
-(void)resetSkinPartial;

Resets any changes made through changeSkinPartial; reverts the skeleton back to the skins used when the scene was created.
Should only be called after changeSkinPartial.


#### -changeTexturePartial:
-(void)changeTexturePartial:(NSDictionary *)attachmentsToReplace;

Replaces the texture of any nodes mentioned in the attachmentsToReplace dictionary with their accompanying texture.

###### Parameters
*	*attachmentsToReplace*
	*	NSDictionary with keys as the names of the attachments you want to change and the value being the name of the attachments to change to. Example:

```
	NSDictionary* partReplacement = @{@"attachmentToReplace": @"attachementToReplaceWith", @"torso": @"goblin-torso", @"head": @"goblin-head"};
	[goblin changeTexturePartial:partReplacement];
```

#### -resetTexturePartial
-(void)resetTexturePartial;

Resets any changes made through resetTexturePartial; reverts the skeleton back to the textures used when the scene was created.
Should only be called after changeTexturePartial.



#### -colorizeSlots:withColor:andIntensity:
-(void)colorizeSlots:(NSArray \*)slotsToColorize withColor:(SKColor \*)color andIntensity:(CGFloat)blendFactor;

Colorizes the slots listed in the slotsToColorize array using the specified color and blend factor.

Can be used to make a body part flash red, or to let the player change their hair/skin color.

###### Parameters
*	*slotsToColorize*
	*	NSArray of NSStrings naming the slots to colorize
*	*color*
	*	SKColor of the color to colorize with.
*	*blendFactor*
	*	CGFloat value from 0.0 to 1.0 to determine how much to colorize the slots.

#### -resetColorizedSlots
-(void)resetColorizedSlots;

Resets any changes made through resetColorizedSlots; reverts the skeleton back to the colors used when the scene was created.
Should only be called after colorizeSlots.


#### -findBoneNamed:
-(SGG_SpineBone\*)findBoneNamed:(NSString\*)boneName;

Finds and returns an SGG_SpineBone object (inherits from SKNode) with the name provided.

###### Parameters
*	*boneName*
	*	NSString value of the name of the bone you are looking for

## Questions or comments?
Let me know!

##### Additional Resource
https://github.com/massivepenguin/SGG_SKSpineImport
