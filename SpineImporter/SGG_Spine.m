//
//  SGG_Spine.m
//  SpineTesting
//
//  Created by Michael Redig on 2/10/14.
//  Copyright (c) 2014 Secret Game Group LLC. All rights reserved.
//

#import "SGG_Spine.h"
#import "SGG_SpineJSONTools.h"


@interface SGG_Spine () {
	
//	SGG_SKUtilities* sharedUtilities;
	
	CFTimeInterval animationStartTime;
	NSInteger repeatAnimationCount;
	
}

@end

@implementation SGG_Spine

-(id)init {
	
	if (self = [super init]) {
//		sharedUtilities = [SGG_SKUtilities sharedUtilities];
		_isRunningAnimation = NO;
	}
	return self;
}

-(void)skeletonFromFileNamed:(NSString*)name andAtlasNamed:(NSString*)atlasName andUseSkinNamed:(NSString*)skinName { //add skin name as an option here

//	NSTimeInterval timea = CFAbsoluteTimeGetCurrent(); //benchmarking

	if (skinName) {
		_currentSkin = skinName;
	} else {
		_currentSkin = @"default";
	}

	SGG_SpineJSONTools* tools = [[SGG_SpineJSONTools alloc]init];
	NSDictionary* spineDict = [tools readJSONFileNamed:name];
	
	NSArray* boneArray = [NSArray arrayWithArray:[spineDict objectForKey:@"bones"]];
	[self createBonesFromArray:boneArray];
	
	_slotsArray = [NSArray arrayWithArray:[spineDict objectForKey:@"slots"]];
	[self creatSlotsAndAttachToBonesWithSlotsArray:_slotsArray];
	
	NSDictionary* skinsDict = [NSDictionary dictionaryWithDictionary:[spineDict objectForKey:@"skins"]];
	[self createSkinsFromDict:skinsDict andAtlasNamed:atlasName];

	[self changeSkinTo:_currentSkin];

	_rawAnimationDictionary = [NSDictionary dictionaryWithDictionary:[spineDict objectForKey:@"animations"]];
	[self setUpAnimationsWithAnimationDictionary:_rawAnimationDictionary withIntroPeriodOf:0.0f];
	
	
//	NSTimeInterval timeb = CFAbsoluteTimeGetCurrent(); //benchmarking
//	NSLog(@"time taken: %f", timeb - timea); //benchmarking

}

#pragma mark PLAYBACK CONTROLS

-(void)runAnimation:(NSString*)animationName andCount:(NSInteger)count {
	
	
//	[self runAnimation:animationName andCount:count withSpeedFactor:1];
	[self runAnimation:animationName andCount:count withSpeedFactor:1 withIntroPeriodOf:0 andUseQueue:YES];
	
}


-(void)runAnimation:(NSString*)animationName andCount:(NSInteger)count withSpeedFactor:(CGFloat)speedfactor withIntroPeriodOf:(const CGFloat)introPeriod andUseQueue:(BOOL)useQueue { //speedfactor currently does nothing
	
	
	if (introPeriod > 0) {
		[self createIntroAnimationIntoAnimation:animationName overDuration:introPeriod];
		[self runAnimationSequence:@[@"INTRO_ANIMATION", animationName] andUseQueue:useQueue];
		return;
	}

	if (_isRunningAnimation) {
		[self stopAnimation]; //clear any current animations
	}
	
	animationStartTime = CFAbsoluteTimeGetCurrent();
	
	_animationCount = count;
	

	_useQueue = useQueue;
	if (!_queuedAnimation && useQueue) {
		_queuedAnimation = animationName;
	}

	

	NSInteger totalFrameCount = 0;
	for (SGG_SpineBone* bone in _bones) {
		NSInteger thisFrameCount = [bone playAnimations:@[animationName]];
		totalFrameCount = MAX(totalFrameCount, thisFrameCount);
		if (thisFrameCount == 0 && _debugMode) {
			NSLog(@"bone %@ has no frames.", bone.name);
		}
	}
	
	for (SGG_SkinSlot* skinSlot in _skinSlots) {
		NSInteger thisFrameCount = [skinSlot playAnimations:@[animationName]];
		totalFrameCount = MAX(totalFrameCount, thisFrameCount);
		if (thisFrameCount == 0 && _debugMode) {
			NSLog(@"slot %@ has no frames.", skinSlot.name);
		}
	}
	if (_debugMode) {
		NSLog(@"running animation: %@ : %i frames",animationName, (int)totalFrameCount);
	}

//reset root rotation and stuff
	[self resetRootBoneOverDuration:introPeriod];
	
	if (_currentAnimationSequence.count <= 1) {
		_currentAnimationSequence = nil;
	}

	_currentAnimation = animationName;
	_isRunningAnimation = YES;
	



	
}

-(void)runAnimationSequence:(NSArray *)animationNames andUseQueue:(BOOL)useQueue {
	
	//fill in later
	_currentAnimationSequence = [NSMutableArray arrayWithArray:animationNames];

	[self runAnimation:_currentAnimationSequence[0] andCount:0 withSpeedFactor:1.0f withIntroPeriodOf:0 andUseQueue:useQueue];
}

-(void)stopAnimation {
	[self stopAnimationAndPlayNextInQueue:NO];
}

-(void)stopAnimationAndPlayNextInQueue:(BOOL)queueNext {
	
	for (SGG_SpineBone* bone in _bones) {
		[bone stopAnimation];
	}
	
	for (SGG_SkinSlot* skinSlot in _skinSlots) {
		[skinSlot stopAnimation];
	}
	
	[self setIsRunningAnimationNO];
	
	if (queueNext) {
		// play next in queue
		[self runAnimation:_queuedAnimation andCount:-1 withSpeedFactor:1 withIntroPeriodOf:_queueIntro andUseQueue:YES];
	}

}



-(void)resetSkeleton {
	
	for (int i = 0; i < _bones.count; i++) {
		SGG_SpineBone* bone = (SGG_SpineBone*)[_bones objectAtIndex:i];
		[bone setToDefaults];
	}
//	NSDictionary* skinDict = [_skins objectForKey:_currentSkin];
//	NSArray* allSlots = [skinDict allKeys];
	for (int i = 0; i < _skinSlots.count; i++) {
		SGG_SkinSlot* skinSlot = (SGG_SkinSlot*)_skinSlots[i];
		[skinSlot setToDefaultAttachment];
	}
	
}

-(void)resetRootBoneOverDuration:(CGFloat)duration {
	
	//this section may need modification
	SGG_SpineBone* rootBone = [self findBoneNamed:@"root"];
	SKAction* setRootBoneRotation = [SKAction rotateToAngle:rootBone.defaultRotation duration:duration];
	SKAction* setRootBoneTranslate = [SKAction moveTo:rootBone.defaultPosition duration:duration];
	SKAction* setRootBoneScale = [SKAction scaleXTo:rootBone.xScale y:rootBone.yScale duration:duration];
	SKAction* rootBoneSRT = [SKAction group:@[setRootBoneRotation, setRootBoneTranslate, setRootBoneScale]];
	[rootBone runAction:rootBoneSRT withKey:@"rootReset"];
//	NSLog(@"root reset");
}

-(SGG_SpineBone*)findBoneNamed:(NSString*)boneName {
	
	for (int i = 0; i < _bones.count; i++) {
		SGG_SpineBone* bone = (SGG_SpineBone*)[_bones objectAtIndex:i];
		if ([bone.name isEqualToString:boneName]) {
			return bone;
		}
	}
	
	return nil;
}


-(void)activateAnimations {
	if (_isRunningAnimation) {

		CFTimeInterval time = CFAbsoluteTimeGetCurrent();
		
		double timeElapsed = time - animationStartTime;

		NSInteger framesElapsed = round(timeElapsed / 0.008333333333333333); // 1/120


		NSInteger currentFrame = 0;
		NSInteger totalFrames = 0;
		
		bool boneAnimationEnded = NO;
		bool slotAnimationEnded = NO;
		
		for (int i = 0; i < _bones.count; i++) {
			SGG_SpineBone* bone = (SGG_SpineBone*)_bones[i];
			if (bone.currentAnimation.count > 1 && !currentFrame) {
				currentFrame = framesElapsed;
				if (framesElapsed >= (bone.currentAnimation.count - 1)) {
//					currentFrame = framesElapsed % (bone.currentAnimation.count - 1);
					currentFrame = MIN(bone.currentAnimation.count, framesElapsed);
					boneAnimationEnded = YES;
				}
			}
			totalFrames = MAX(totalFrames, bone.currentAnimation.count);

			[bone updateAnimationAtFrame:currentFrame];
			
		}
		
		for (int i = 0; i < _skinSlots.count; i++) {
			SGG_SkinSlot* skinSlot = _skinSlots[i];
			if (skinSlot.currentAnimation.count > 1 && !currentFrame) {
				currentFrame = framesElapsed % (skinSlot.currentAnimation.count - 1);
			}
			if (framesElapsed >= (skinSlot.currentAnimation.count - 1)) {
				slotAnimationEnded = YES;
			}
			[skinSlot updateAnimationAtFrame:currentFrame];
		}
		
		if (_debugMode) {
			SKLabelNode* frameCounter = (SKLabelNode*)[self childNodeWithName:@"frameCounter"];
			frameCounter.text = [NSString stringWithFormat:@"%i of %i", (int)currentFrame, (int)totalFrames];
		}
		
		if (boneAnimationEnded) {
			[self endOfAnimation];
		}
		
	}
}

-(void)endOfAnimation {
	if ([_currentAnimation isEqualToString:@"INTRO_ANIMATION"]) { //clear out intro animation after it's been used
		NSLog(@"finished intro");
		for (SGG_SpineBone* bone in _bones) {
			[bone.animations removeObjectForKey:@"INTRO_ANIMATION"];
		}
		
		for (SGG_SkinSlot* skinSlot in _skinSlots) {
			[skinSlot.animations removeObjectForKey:@"INTRO_ANIMATION"];
		}
	}

	if (_currentAnimationSequence.count > 1) { //if running a sequence, remove the first listed animation in the sequence and move on to the next
		if ([_currentAnimation isEqualToString:_currentAnimationSequence[0]]) {
			[_currentAnimationSequence removeObjectAtIndex:0];
		}
		[self runAnimation:_currentAnimationSequence[0] andCount:0 withSpeedFactor:1.0f withIntroPeriodOf:0 andUseQueue:YES];
		
	} else if (_animationCount > 0){ //if animation is set to repeat x times start the same animation over and count -1 in count
		_animationCount -= 1;
		if (_animationCount == -1) {
			[self stopAnimation];
			_animationCount = 0;
			return;
		} else {
			[self runAnimation:_currentAnimation andCount:_animationCount withSpeedFactor:1.0 withIntroPeriodOf:0 andUseQueue:_useQueue];
		}
		
	} else if (_animationCount == -1) { //if animation is set to repeat infinite times, repeat animation
		[self runAnimation:_currentAnimation andCount:-1 withSpeedFactor:1.0 withIntroPeriodOf:0 andUseQueue:_useQueue];
	} else if (_queuedAnimation != 0 && _useQueue) { //if queue is set, intro into queue. if already playing the queue animation, ignore the intro
		if ([_currentAnimation isEqualToString:_queuedAnimation]) {
			NSLog(@"queued with no intro");
			[self runAnimation:_queuedAnimation andCount:-1 withSpeedFactor:1.0 withIntroPeriodOf:0 andUseQueue:YES];
		} else {
			NSLog(@"queued with intro: %f", _queueIntro);
			[self runAnimation:_queuedAnimation andCount:-1 withSpeedFactor:1.0 withIntroPeriodOf:_queueIntro andUseQueue:YES];
		}
		NSLog(@"set to queue");
	} else { //stop animation if nothing above qualifies
		[self stopAnimation];
		NSLog(@"stopped");
	}
	
}

-(void)animationCounter {
	if (_animationCount >= 0) {
		_animationCount -= 1;
	}
}

#pragma mark SKINNING

-(void)changeSkinTo:(NSString*)skin {
	
	for (SGG_SkinSlot* skinSlot in _skinSlots) {
		[skinSlot changeSkinTo:skin];
	}
	
	_currentSkin = skin;
	
	//	[self creatSlotsAndAttachToBonesWithSlotsArray:_slotsArray];
	
}

-(void)changeSkinPartial:(NSDictionary *)slotsToReplace {
    // replaces the skin for specified slots without redrawing the whole skin - useful for 'battle damage', etc.
	NSArray* slotNames = [slotsToReplace allKeys];
	for (SGG_SkinSlot* skinSlot in _skinSlots) {
		for (NSString* slotName in slotNames) {
			if ([slotName isEqualToString:skinSlot.name]) {
				[skinSlot changeSkinTo:slotsToReplace[slotName]];
				break;
			}
		}
	}
}

-(void)changeTexturePartial:(NSDictionary *)attachmentsToReplace {
	//replaces attachments for the current skin in the current slot with the textures named in the dictionary
	for (SGG_SkinSlot* skinSlot in _skinSlots) {
		NSDictionary* thisSlotSkinDict = skinSlot.skins[_currentSkin];
		for (id key in attachmentsToReplace) {
			NSString* thisKey = (NSString*)key;
			SKSpriteNode* thisAttachment = thisSlotSkinDict[thisKey];
			if (thisAttachment) {
				//				NSLog(@"%@ attachement exists: %@", thisKey, thisSlotSkinDict[thisKey]);
				SKTexture* originalTexture = thisAttachment.texture;
				thisAttachment.texture = [SKTexture textureWithImageNamed:attachmentsToReplace[thisKey]];
				
				if (!_swappedTextures) {
					_swappedTextures = [[NSMutableDictionary alloc] init];
				}
				
				if (!_swappedTextures[thisAttachment.name]) {
					NSDictionary* resetDict = [NSDictionary dictionaryWithObjects:@[originalTexture, _currentSkin] forKeys:@[@"texture", @"originalSkin"]];
					
					[_swappedTextures setObject:resetDict forKey:thisAttachment.name];
				}
				break;
			}
		}
	}
}

-(void)resetTexturePartial {
	
	for (id key in _swappedTextures) {
		NSString* thisKey = (NSString*)key;
		NSDictionary* resetDict = _swappedTextures[thisKey];
		NSString* originalSkin = resetDict[@"originalSkin"];
		SKTexture* originalTexture = resetDict[@"texture"];
		for (SGG_SkinSlot* skinSlot in _skinSlots) {
			NSDictionary* thisSlotSkinDict = skinSlot.skins[originalSkin];
			SKSpriteNode* thisAttachment = thisSlotSkinDict[thisKey];
			if (thisAttachment) {
				thisAttachment.texture = originalTexture;
				break;
			}
		}
	}
	
	_swappedTextures = nil;
	
	
}


-(void)resetSkinPartial {
    // resets any swapped slots
	for (SGG_SkinSlot* skinSlot in _skinSlots) {
		[skinSlot changeSkinTo:_currentSkin];
	}
}

-(void)colorizeSlots:(NSArray *)slotsToColorize withColor:(SKColor *)color andIntensity:(CGFloat)blendFactor {
    // colorizes the specified parts of the skin with the supplied color, to the intensity indicated - can be used to change hair/skin color dynamically, or 'flashing' a body part when hit...
    
    for (int i = 0; i < _skinSlots.count; i++) {
		SKNode* slot = (SKNode*)[_skinSlots objectAtIndex:i];
		[slot enumerateChildNodesWithName:@"//*" usingBlock:^(SKNode *node, BOOL *stop) {
			for(NSString* colorizedNode in slotsToColorize){
                if([colorizedNode isEqualToString:node.name]) {
                    SKSpriteNode* thisNode = (SKSpriteNode *)node;
                    thisNode.color = color;
                    thisNode.colorBlendFactor = blendFactor;
                    
                    if(!_colorizedNodes.count) {
                        _colorizedNodes = [[NSMutableArray alloc] init];
                    }
                    
                    _colorizedNodes[_colorizedNodes.count] = node.name;
                    
                    break;
                }
            }
		}];
	}
}

-(void)resetColorizedSlots {
	
	[self colorizeSlots:_colorizedNodes withColor:[SKColor whiteColor] andIntensity:0];
	[_colorizedNodes removeAllObjects];
	
}



#pragma mark SETUP FUNCTIONS

-(void)setDebugMode:(BOOL)debugMode {
	
	_debugMode = debugMode;
	
	if (_debugMode) {
		SKLabelNode* frameCounter = [SKLabelNode labelNodeWithFontNamed:@"Helvetica"];
		frameCounter.position = CGPointMake(0, -20);
		frameCounter.color = [SKColor whiteColor];
		frameCounter.text = @"nan";
		frameCounter.name = @"frameCounter";
		frameCounter.zPosition = 1000000;
		[self addChild:frameCounter];
	} else {
		SKNode* frameCounter = [self childNodeWithName:@"frameCounter"];
		[frameCounter removeFromParent];
	}
}

-(SKActionTimingMode)determineTimingMode:(NSArray*)bezierCurve {
	
	
	CGPoint point1 = CGPointMake([[bezierCurve objectAtIndex:0]doubleValue], [[bezierCurve objectAtIndex:1]doubleValue]);
	CGPoint point2 = CGPointMake([[bezierCurve objectAtIndex:2]doubleValue], [[bezierCurve objectAtIndex:3]doubleValue]);
	
	SKActionTimingMode modeIn = SKActionTimingLinear;
	SKActionTimingMode modeOut = SKActionTimingLinear;
	SKActionTimingMode finalMode;
	
	if (point1.x == point1.y) {
		//linear in
		modeIn = SKActionTimingLinear;
	} else if (point1.x > point1.y) {
		//ease in
		modeIn = SKActionTimingEaseIn;
	} else if (point1.x < point1.y) {
		//can't handle this
		modeIn = SKActionTimingLinear;
	}
	
	if (point2.x == point2.y) {
		//linear out
		modeOut = SKActionTimingLinear;
	} else if (point2.x > point2.y) {
		//can't handle this
		modeOut = SKActionTimingLinear;
	} else if (point2.x < point2.y) {
		//ease out
		modeOut = SKActionTimingEaseOut;
	}
	
	if (modeIn == modeOut) {
		finalMode = SKActionTimingLinear;
	} else if (modeIn == SKActionTimingEaseIn && modeOut == SKActionTimingEaseOut) {
		finalMode = SKActionTimingEaseInEaseOut;
	} else if (modeIn == SKActionTimingEaseIn) {
		finalMode = SKActionTimingEaseIn;
	} else {
		finalMode = SKActionTimingEaseOut;
	}
	
	
	return finalMode;
}

-(void)createBonesFromArray:(NSArray*)boneArray{
	
	NSMutableArray* mutableBones = [[NSMutableArray alloc] init];
	for (int i = 0; i < boneArray.count; i++) {
		NSDictionary* boneDict = [NSDictionary dictionaryWithDictionary:[boneArray objectAtIndex:i]];
		SGG_SpineBone* bone = [SGG_SpineBone node];
		
		bone.position = CGPointMake([[boneDict objectForKey:@"x"] doubleValue], [[boneDict objectForKey:@"y"] doubleValue]);
		bone.length = [[boneDict objectForKey:@"length"] doubleValue];
		if ([boneDict objectForKey:@"scaleX"]) {
			bone.xScale = [[boneDict objectForKey:@"scaleX"] doubleValue];
		}
		
		if ([boneDict objectForKey:@"scaleY"]) {
			bone.yScale = [[boneDict objectForKey:@"scaleY"] doubleValue];
			
		}
		bone.zRotation = [[boneDict objectForKey:@"rotation"] doubleValue] * SPINE_DEGTORADFACTOR;
		bone.name = [boneDict objectForKey:@"name"];
		NSString* parent = [boneDict objectForKey:@"parent"];
		if (parent) {
			for (int h = 0; h < mutableBones.count; h++) {
				SGG_SpineBone* parentBone = (SGG_SpineBone*)[mutableBones objectAtIndex:h];
				if ([parentBone.name isEqualToString:parent]) {
					[parentBone addChild:bone];
				}
			}
		} else {
			[self addChild:bone];
		}
		[bone setDefaultsAndBase];
		
		if (_debugMode) {
			[bone debugWithLength];
		}
		
		[mutableBones addObject:bone];
		//		NSLog(@"added bone: %@", bone);
	}
	
	_bones = [NSArray arrayWithArray:mutableBones];
	
	
}


-(void)creatSlotsAndAttachToBonesWithSlotsArray:(NSArray*)slotsArray {
	
	NSMutableArray* skinSlotsMutable = [[NSMutableArray alloc] init];

	
	
	for (int i = 0; i < slotsArray.count; i++) {
		NSDictionary* slotDict = [NSDictionary dictionaryWithDictionary:[slotsArray objectAtIndex:i]];
		NSString* attachment = [slotDict objectForKey:@"attachment"]; //image name
		NSString* boneString = [slotDict objectForKey:@"bone"];
		NSString* name = [slotDict objectForKey:@"name"];
		
		
		SGG_SkinSlot* skinSlot = [SGG_SkinSlot node];
		skinSlot.name = name;
		
		SKSpriteNode* debugSlot = [SKSpriteNode spriteNodeWithColor:[SKColor greenColor] size:CGSizeMake(50, 5)];
		debugSlot.anchorPoint = CGPointMake(0, 0.5);
		[skinSlot addChild:debugSlot];
		
		skinSlot.currentAttachment = attachment; // this just sets the names of the attachments to use... nothing is actually attached at this time
		skinSlot.defaultAttachment = attachment;
		
//		NSLog(@"currentAttachment: %@", skinSlot.currentAttachment);
		
		skinSlot.zPosition = i * 0.01;
		
		for (int b = 0; b < _bones.count; b++) { //find bone for slot
			SGG_SpineBone* bone = (SGG_SpineBone*)[_bones objectAtIndex:b];
			if ([bone.name isEqualToString:boneString]) {
				[bone addChild:skinSlot];
				break;
			}
		}
		
		[skinSlotsMutable addObject:skinSlot];
		
	}
	
	_skinSlots = [NSArray arrayWithArray:skinSlotsMutable];
	
	
}

-(void)createSkinsFromDict:(NSDictionary*)skinsDict andAtlasNamed:(NSString*)atlasName{
	//pull in texture atlas
	SKTextureAtlas* atlas = [SKTextureAtlas atlasNamed:atlasName];
	
	//get all skins
	NSArray* skinKeys = [skinsDict allKeys];
	
	if (_debugMode) {
		NSLog(@"skinKeys: %@", skinKeys);
	}
	for (NSString* skinName in skinKeys) { //cycle through all the skin names in the JSON
	
		
		//get all skin slots
		NSDictionary* slotsFromSkin = [NSDictionary dictionaryWithDictionary:[skinsDict objectForKey:skinName]];
		NSArray* skinSlotNames = [slotsFromSkin allKeys];
		
		
		for (NSString* skinSlotName in skinSlotNames) {
			//get appropriate SkinSlot from public array
			SGG_SkinSlot* skinSlot;
			for (SGG_SkinSlot* skinSlotCycle in _skinSlots) {
				if ([skinSlotCycle.name isEqualToString:skinSlotName]) {
					skinSlot = skinSlotCycle;
					break;
				}
			}
//			NSLog(@"for skin %@ attachment %@ will be attached to skin slot %@", skinName, skinSlotName, skinSlot.name);
			NSMutableDictionary* slotSkinDict;
			if (!skinSlot.skins[skinName]) { //if this skin doesn't yet have an entry in the skin slot dict
				slotSkinDict = [[NSMutableDictionary alloc] init];
				[skinSlot.skins setObject:slotSkinDict forKey:skinName];
			} else { //else just use the one that's already there
				slotSkinDict = skinSlot.skins[skinName];
			}
			
			NSDictionary* attachmentsDict = slotsFromSkin[skinSlotName];
			
			NSArray* attachmentNames = [attachmentsDict allKeys];
			for (NSString* attachmentName in attachmentNames) {
				NSDictionary* attachmentDict = attachmentsDict[attachmentName];
				
				NSString* spriteNameString = attachmentDict[@"name"];
				if (spriteNameString) {
					spriteNameString = [spriteNameString stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
//					NSLog(@"spriteNameString after conversion: %@", spriteNameString);
				} else {
					spriteNameString = attachmentName;
				}
				
				SGG_SkinSprite* skinSprite = [SGG_SkinSprite spriteNodeWithTexture:[atlas textureNamed:spriteNameString]];
				skinSprite.name = attachmentName;


				skinSprite.position = CGPointMake([[attachmentDict objectForKey:@"x"] doubleValue], [[attachmentDict objectForKey:@"y"] doubleValue]);
				if ([attachmentDict objectForKey:@"scaleX"]) {
					skinSprite.xScale = [[attachmentDict objectForKey:@"scaleX"] doubleValue];
				}

				if ([attachmentDict objectForKey:@"scaleY"]) {
					skinSprite.yScale = [[attachmentDict objectForKey:@"scaleY"] doubleValue];
				}
				skinSprite.zRotation = [[attachmentDict objectForKey:@"rotation"] doubleValue] * SPINE_DEGTORADFACTOR;
				skinSprite.sizeFromJSON = CGSizeMake([[attachmentDict objectForKey:@"width"] doubleValue], [[attachmentDict objectForKey:@"height"] doubleValue]);


				[skinSprite setDefaults];
				skinSprite.hidden = HIDDEN;
				
				[slotSkinDict setObject:skinSprite forKey:attachmentName];
								
			}
	
		}

	}

}


-(void)setUpAnimationsWithAnimationDictionary:(NSDictionary*)animationDictionary withIntroPeriodOf:(CGFloat)introPeriod{

	
	NSArray* animationNames = [animationDictionary allKeys];
	for (int i = 0; i < animationNames.count; i++) {
	//cycle through all animations
	
		NSString* thisAnimationName = [animationNames objectAtIndex:i];
		NSDictionary* thisAnimationDict = [NSDictionary dictionaryWithDictionary:[animationDictionary objectForKey:thisAnimationName]];
		
		CGFloat longestDuration = [self longestTimeInAnimations:thisAnimationDict];
		if (_debugMode) {
			NSLog(@"longest duration in %@ is: %f",thisAnimationName, longestDuration);
		}
		
		NSDictionary* boneAnimationsDict = [NSDictionary dictionaryWithDictionary:[thisAnimationDict objectForKey:@"bones"]];
		for (int c = 0; c < _bones.count; c++) {
		//cycle through individual bone SRT animations
		
			SGG_SpineBone* bone = (SGG_SpineBone*)[_bones objectAtIndex:c];
			NSDictionary* SRTtimelinesForBone = [boneAnimationsDict objectForKey:bone.name];
			
			//set up scale actions for bone
//			SKAction* boneScale = [self createBoneScaleActionsFromArray:scales forBone:bone andTotalLengthOfAnimation:longestDuration andIntroPeriodOf:introPeriod];
			
			//set up actions for bone
			NSArray* translations = [SRTtimelinesForBone objectForKey:@"translate"];
			NSArray* rotations = [SRTtimelinesForBone objectForKey:@"rotate"];
			NSArray* scales = [SRTtimelinesForBone objectForKey:@"scale"];
			SGG_SpineBoneAction* boneAction = [self createBoneTranslationActionsFromArray:translations andRotationsFromArray:rotations andScalesFromArray:scales forBone:bone andTotalLengthOfAnimation:longestDuration];

			
			[bone.animations setObject:boneAction forKey:thisAnimationName];
		}
		
		
		NSDictionary* slotsAnimationsDict = [NSDictionary dictionaryWithDictionary:[thisAnimationDict objectForKey:@"slots"]];
		NSArray* slotNames = [slotsAnimationsDict allKeys];
		
		for (NSString* slotName in slotNames) {
			for (SGG_SkinSlot* skinSlot in _skinSlots) {
				if ([skinSlot.name isEqualToString:slotName]) {
					// matching names... do stuff here
					NSDictionary* slotDict = [slotsAnimationsDict objectForKey:slotName];

					SGG_SpineBoneAction* slotAction = [self createSpineSlotActionsFromDictionary:slotDict andTotalLengthOfAnimation:longestDuration andIntroPeriodOf:0];
			
					[skinSlot.animations setObject:slotAction forKey:thisAnimationName];
					
//					NSLog(@"slot: %@ animations: %@", skinSlot.name, skinSlot.animations);
					
					break;
				}
			}
		}


		
		
		//		NSDictionary* drawOrderAnimationsDict = [NSDictionary dictionaryWithDictionary:[thisAnimationDict objectForKey:@"draworder"]];
		
		
		//add this entire animation (individual animations for each bone and slot) to the animations dictionary
//		NSArray* immutableArray = [NSArray array]; // used to be where animatinos were stored... holding onto it in case it's needed again
		
		NSString* key;
		if (introPeriod == 0) {
			key = thisAnimationName;
		} else {
			key = [NSString stringWithFormat:@"%f-intro-%@", introPeriod, thisAnimationName];
		}
		
//		[_animations setObject:immutableArray forKey:key];
		
	}
}

-(CGFloat)longestTimeInAnimations:(NSDictionary*)animation {
	CGFloat longestDuration = 0;
	
	NSDictionary* boneAnimationsDict = [NSDictionary dictionaryWithDictionary:[animation objectForKey:@"bones"]];
	for (int c = 0; c < _bones.count; c++) {
		SGG_SpineBone* bone = (SGG_SpineBone*)[_bones objectAtIndex:c];
		NSDictionary* SRTtimelinesForBone = [boneAnimationsDict objectForKey:bone.name]; //does this work?!
		
		NSArray* rotations = [SRTtimelinesForBone objectForKey:@"rotate"];
		for (int d = 0; d < rotations.count; d++) {
			NSDictionary* rotation = [rotations objectAtIndex:d];
			CGFloat duration = [[rotation objectForKey:@"time"] doubleValue];
			//set up rotation actions here
			if (duration > longestDuration) {
				longestDuration = duration;
				if (_debugMode) {
					NSLog(@"duration lengthened to: %f %@ rotation", longestDuration, rotation);
				}
			}
		}
		
		NSArray* scales = [SRTtimelinesForBone objectForKey:@"scale"];
		for (int d = 0; d < scales.count; d++) {
			NSDictionary* scale = [scales objectAtIndex:d];
			CGFloat duration = [[scale objectForKey:@"time"] doubleValue];
			//set up scale actions here
			if (duration > longestDuration) {
				longestDuration = duration;
				if (_debugMode) {
					NSLog(@"duration lengthened to: %f %@ scale", longestDuration, scale);
				}
			}
		}
		
		NSArray* translates = [SRTtimelinesForBone objectForKey:@"translate"];
		for (int d = 0; d < translates.count; d++) {
			NSDictionary* translate = [translates objectAtIndex:d];
			CGFloat duration = [[translate objectForKey:@"time"] doubleValue];
			//set up translate actions here
			if (duration > longestDuration) {
				longestDuration = duration;
				if (_debugMode) {
					NSLog(@"duration lengthened to: %f %@ translate", longestDuration, translate);
				}
			}
		}
	}
	
	NSDictionary* slotAnimationsDict = [NSDictionary dictionaryWithDictionary:[animation objectForKey:@"slots"]];
	NSArray* slotsWithAnimation = [slotAnimationsDict allKeys];
	for (int c = 0; c < slotsWithAnimation.count; c++) {
		//attachments and colors
		
		NSArray* attachmentArray = [NSArray arrayWithArray:[slotAnimationsDict objectForKey:@"attachment"] ];
		for (int d = 0; d < attachmentArray.count; d++) {
			NSDictionary* attachment = [attachmentArray objectAtIndex:d];
			CGFloat duration = [[attachment objectForKey:@"time"] doubleValue];
			//set up slot actions here
			if (duration > longestDuration) {
				longestDuration = duration;
				if (_debugMode) {
					NSLog(@"duration lengthened to: %f %@ attachment", longestDuration, attachment);
				}
			}
		}
		
		NSArray* colorArray = [NSArray arrayWithArray:[slotAnimationsDict objectForKey:@"color"] ];
		for (int d = 0; d < colorArray.count; d++) {
			NSDictionary* color = [colorArray objectAtIndex:d];
			CGFloat duration = [[color objectForKey:@"time"] doubleValue];
			//set up color actions here
			if (duration > longestDuration) {
				longestDuration = duration;
				if (_debugMode) {
					NSLog(@"duration lengthened to: %f %@ color", longestDuration, color);
				}
			}
		}
	}
	
	
	NSArray* drawOrderArray = [NSArray arrayWithArray:[animation objectForKey:@"draworder"]];
	for (int c = 0; c < drawOrderArray.count; c++) {
		NSDictionary* drawOrderInfo = [NSDictionary dictionaryWithDictionary:[drawOrderArray objectAtIndex:c]];
		CGFloat duration = [[drawOrderInfo objectForKey:@"time"] doubleValue];
		//set up draw order actions here
		if (duration > longestDuration) {
			longestDuration = duration;
			if (_debugMode) {
				NSLog(@"duration lengthened to: %f %@ draw order", longestDuration, drawOrderInfo);
			}
			
		}
	}
	
	
	
	return longestDuration;
}

-(void)createIntroAnimationIntoAnimation:(NSString*)animationName overDuration:(CGFloat)duration {
//	NSLog(@"creating intro");
	
	NSDictionary* thisAnimationDict = _rawAnimationDictionary[animationName];
	
	NSDictionary* boneAnimationsDict = [NSDictionary dictionaryWithDictionary:[thisAnimationDict objectForKey:@"bones"]];
	CGFloat longestDuration = duration;

	
	for (SGG_SpineBone* bone in _bones) {
		
		
		NSDictionary* SRTtimelinesForBone = [boneAnimationsDict objectForKey:bone.name];
		
		//set up scale actions for bone
		//			SKAction* boneScale = [self createBoneScaleActionsFromArray:scales forBone:bone andTotalLengthOfAnimation:longestDuration andIntroPeriodOf:introPeriod];
		
		//set up actions for bone
		NSArray* translations = [SRTtimelinesForBone objectForKey:@"translate"];
		NSArray* rotations = [SRTtimelinesForBone objectForKey:@"rotate"];
		NSArray* scales = [SRTtimelinesForBone objectForKey:@"scale"];

		NSDictionary* destTranDict, *destRotDict, *destScaleDict;
		
		destTranDict = translations[0];
		destRotDict = rotations[0];
		destScaleDict = scales[0];
		
		CGFloat destXPos, destYPos, destRot, destXScale, destYScale;
		destXPos = [destTranDict[@"x"] doubleValue];
		destYPos = [destTranDict[@"y"] doubleValue];
		destRot = [destRotDict[@"angle"] doubleValue];
		if (destScaleDict[@"x"]) {
			destXScale = [destScaleDict[@"x"] doubleValue];
		} else {
			destXScale = 1.0;
		}
		
		if (destScaleDict[@"y"]) {
			destYScale = [destScaleDict[@"y"] doubleValue];
		} else {
			destYScale = 1.0;
		}
		
		NSDictionary* startTransDict = [NSDictionary dictionaryWithObjects:@[
																			 [NSNumber numberWithDouble:0],
																			 [NSNumber numberWithDouble:bone.position.x - bone.defaultPosition.x],
																			 [NSNumber numberWithDouble:bone.position.y - bone.defaultPosition.y],
																			 ]
																   forKeys:@[
																			 @"time",
																			 @"x",
																			 @"y",
																			 ]];
		
		
		NSDictionary* endTransDict = [NSDictionary dictionaryWithObjects:@[
																			 [NSNumber numberWithDouble:longestDuration],
																			 [NSNumber numberWithDouble:destXPos],
																			 [NSNumber numberWithDouble:destYPos],
																			 ]
																   forKeys:@[
																			 @"time",
																			 @"x",
																			 @"y",
																			 ]];
		
		CGFloat startRotationModified = (bone.zRotation * SPINE_RADTODEGFACTOR);
//		NSLog(@"startRot: %f", startRotationModified);
		startRotationModified -= bone.defaultRotation * SPINE_RADTODEGFACTOR;
//		NSLog(@"modded: %f", startRotationModified);

		
		NSDictionary* startRotationDict = [NSDictionary dictionaryWithObjects:@[
																				[NSNumber numberWithDouble:0],
																				[NSNumber numberWithDouble:startRotationModified],
																				]
																	  forKeys:@[
																				@"time",
																				@"angle",
																				]];
		NSDictionary* endRotationDict = [NSDictionary dictionaryWithObjects:@[
																				[NSNumber numberWithDouble:longestDuration],
																				[NSNumber numberWithDouble:destRot],
																				]
																	  forKeys:@[
																				@"time",
																				@"angle",
																				]];
		
		NSDictionary* startScaleDict = [NSDictionary dictionaryWithObjects:@[
																				[NSNumber numberWithDouble:0],
																				[NSNumber numberWithDouble:bone.xScale * bone.defaultScaleX],
																				[NSNumber numberWithDouble:bone.yScale * bone.defaultScaleY],
																				]
																   forKeys:@[
																			 @"time",
																			 @"x",
																			 @"y",
																			 ]];
		
		NSDictionary* endScaleDict = [NSDictionary dictionaryWithObjects:@[
																			 [NSNumber numberWithDouble:longestDuration],
																			 [NSNumber numberWithDouble:destXScale],
																			 [NSNumber numberWithDouble:destYScale],
																			 ]
																   forKeys:@[
																			 @"time",
																			 @"x",
																			 @"y",
																			 ]];
		
		NSArray* newTrans = [NSArray arrayWithObjects:startTransDict,
													endTransDict,
													nil];
//		NSLog(@"%@ newTrans: %@", bone.name, newTrans);
		NSArray* newRot = [NSArray arrayWithObjects:startRotationDict, endRotationDict, nil];
		NSArray* newScale = [NSArray arrayWithObjects:startScaleDict, endScaleDict, nil];
		
		if (translations[0] || rotations[0] || scales[0]) {
			SGG_SpineBoneAction* boneAction = [self createBoneTranslationActionsFromArray:newTrans andRotationsFromArray:newRot andScalesFromArray:newScale forBone:bone andTotalLengthOfAnimation:longestDuration];
			
			[boneAction calculateTotalAction];
			
			[bone.animations setObject:boneAction forKey:@"INTRO_ANIMATION"];
			
//			NSLog(@"made intro for %@: %i frames", bone.name, (int)boneAction.animation.count);
		}
		

	}
	
//	for (SGG_SkinSlot* skinSlot in _skinSlots) {
//		NSDictionary* startDict = [NSDictionary dictionaryWithObjects:@[
//																		[NSNumber numberWithDouble:0],
//																		skinSlot.currentAttachment,
//																		]
//															  forKeys:@[
//																		@"time",
//																		@"name",
//																		]];
//		NSDictionary* endDict = [NSDictionary dictionaryWithObjects:@[
//																	  [NSNumber numberWithDouble:longestDuration],
//																	  skinSlot.currentAttachment,
//																		]
//															  forKeys:@[
//																		@"time",
//																		@"name",
//																		]];
//
//		NSArray* aniArray = [NSArray arrayWithObjects:@[startDict, endDict], nil];
//		NSDictionary* totalDict = [NSDictionary dictionaryWithObject:aniArray forKey:@"attachment"];
//		SGG_SpineBoneAction* slotAction = [self createSpineSlotActionsFromDictionary:totalDict andTotalLengthOfAnimation:longestDuration andIntroPeriodOf:0];
//		
//		[slotAction calculateSlotAction];
//		
//		[skinSlot.animations setObject:slotAction forKey:@"INTRO_ANIMATION"];
//		NSLog(@"%@", skinSlot.animations[@"INTRO_ANIMATION"]);
//
//	}
	
//	NSLog(@"set intro");

}



-(SGG_SpineBoneAction*)createBoneTranslationActionsFromArray:(NSArray*)translations andRotationsFromArray:(NSArray*)rotations andScalesFromArray:(NSArray*)scales forBone:(SGG_SpineBone*)bone andTotalLengthOfAnimation:(const CGFloat)longestDuration {
	
//	CGFloat totalTimeForThisAnimation = 0;
	
	SGG_SpineBoneAction* boneAction = [[SGG_SpineBoneAction alloc] init];
	[boneAction setTotalLength:longestDuration];
	
	for (int d = 0; d < translations.count; d++) {
		NSDictionary* translation = [translations objectAtIndex:d];
		CGFloat x, y, time;
		id curveInfo;
		
		x = [[translation objectForKey:@"x"] doubleValue];
		y = [[translation objectForKey:@"y"] doubleValue];
		time = [[translation objectForKey:@"time"] doubleValue];
		curveInfo = [translation objectForKey:@"curve"];
		
		[boneAction addTranslationAtTime:time withPoint:CGPointMake(x, y) andCurveInfo:curveInfo];
		
		
	}
	
	for (int d = 0; d < rotations.count; d++) {
		NSDictionary* rotation = [rotations objectAtIndex:d];
		CGFloat angle, time;
		id curveInfo;
		
		angle = [[rotation objectForKey:@"angle"] doubleValue];
		curveInfo = [rotation objectForKey:@"curve"];
		time = [[rotation objectForKey:@"time"] doubleValue];
		
		[boneAction addRotationAtTime:time withAngle:angle andCurveInfo:curveInfo];
	}
	
	for (int d = 0; d < scales.count; d++) {
		NSDictionary* scale = [scales objectAtIndex:d];
		CGFloat x, y, time;
		id curveInfo;
		
		if ([scale objectForKey:@"x"]) {
			x = [[scale objectForKey:@"x"] doubleValue];
		} else {
			x = 1;
		}
		
		if ([scale objectForKey:@"y"]) {
			y = [[scale objectForKey:@"y"] doubleValue];
		} else {
			y = 1;
		}
		
		curveInfo = [scale objectForKey:@"curve"];
		time = [[scale objectForKey:@"time"] doubleValue];
		
		[boneAction addScaleAtTime:time withScale:CGSizeMake(x, y) andCurveInfo:curveInfo];
	}
	
	
	[boneAction calculateTotalAction];
	
	
	return boneAction;
}

-(SGG_SpineBoneAction*)createSpineSlotActionsFromDictionary:(NSDictionary*)slotDict  andTotalLengthOfAnimation:(const CGFloat)longestDuration andIntroPeriodOf:(const CGFloat)intro {
	SGG_SpineBoneAction* slotAction = [[SGG_SpineBoneAction alloc] init];
	[slotAction setTotalLength:longestDuration];
	
	NSArray* attachmentArray = slotDict[@"attachment"];
	NSArray* colorArray = slotDict[@"color"];
	
	for (NSDictionary* keyFrameDict in attachmentArray) {
		CGFloat time = [keyFrameDict[@"time"] doubleValue];
		NSString* name = keyFrameDict[@"name"];
		[slotAction addAttachmentAnimationAtTime:time withAttachmentName:name];
	}
	
	for (NSDictionary* keyFrameDict in colorArray) {
		CGFloat time = [keyFrameDict[@"time"] doubleValue];
		NSString* color = keyFrameDict[@"color"];
		[slotAction addColorAnimationAtTime:time withColor:color];
	}
	
	[slotAction calculateSlotAction];

	return slotAction;
	
}


#pragma mark PROPERTY HANDLERS

-(void)setIsRunningAnimationYES {
	_isRunningAnimation = YES;
}

-(void)setIsRunningAnimationNO {
	_isRunningAnimation = NO;
	_currentAnimation = nil;
//	NSLog(@"animation done");
	
}

@end
