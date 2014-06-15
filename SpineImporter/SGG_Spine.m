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
	
	NSDictionary* skinsDict = [NSDictionary dictionaryWithDictionary:[spineDict objectForKey:@"skins"]];
	[self createSkinsFromDict:skinsDict andAtlasNamed:atlasName];

	_slotsArray = [NSArray arrayWithArray:[spineDict objectForKey:@"slots"]];
	[self setUpAttachmentsWithSlotsArray:_slotsArray];

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
	
	animationStartTime = CFAbsoluteTimeGetCurrent();
	
	if (_isRunningAnimation) {
		[self stopAnimation]; //clear any current animations
	}
	
	if (!_queuedAnimation) {
		_queuedAnimation = animationName;
		_queueCount = count;
		_queueIntro = introPeriod;
	}
	
	NSString* animationNameWithIntro;
	if (introPeriod != 0) {
		animationNameWithIntro = [NSString stringWithFormat:@"%f-intro-%@", introPeriod, animationName];
	} else {
		animationNameWithIntro = animationName;
	}
	
	NSArray* thisAnimationWithIntro, *thisAnimation;
	if (![_animations objectForKey:animationNameWithIntro]) {
		[self setUpAnimationsWithAnimationDictionary:_rawAnimationDictionary withIntroPeriodOf:introPeriod];
	}
	thisAnimation = [_animations objectForKey:animationName];
	thisAnimationWithIntro = [_animations objectForKey:animationNameWithIntro];

	
	
	CGFloat longestAction = 0;
	
	for (int i = 0; i < thisAnimationWithIntro.count; i++) {
		NSDictionary* thisAniDictWithIntro = [thisAnimationWithIntro objectAtIndex:i];
		kSGG_SpineAnimationType animationType = [[thisAniDictWithIntro objectForKey:@"animationType"] intValue];
		NSString* attachmentName = [thisAniDictWithIntro objectForKey:@"attachmentName"];
		NSDictionary* skinDict = [_skins objectForKey:_currentSkin];
		NSDictionary* thisAniDict = [thisAnimation objectAtIndex:i];
		
		SKAction* action;
		SKAction* introAction;
		SKAction* totalAction;
		if (animationType == kSGG_SpineAnimationTypeBone) {
		
			SGG_SpineBone* bone = [self findBoneNamed:attachmentName];
			introAction = [thisAniDictWithIntro objectForKey:@"action"];
			action = [thisAniDict objectForKey:@"action"];
			if (count == -1) {
				action = [SKAction repeatActionForever:action];
			} else {
				action = [SKAction repeatAction:action count:count];
			}
			totalAction = [SKAction sequence:@[introAction, action]];
			[bone runAction:totalAction withKey:animationName];
			
		} else if (animationType == kSGG_SpineAnimationTypeSlots) {
			
			SGG_SkinSlot* slot = (SGG_SkinSlot*)[skinDict objectForKey:attachmentName];
			introAction = [thisAniDictWithIntro objectForKey:@"action"];
			action = [thisAniDict objectForKey:@"action"];
			if (count == -1) {
				action = [SKAction repeatActionForever:action];
			} else {
				action = [SKAction repeatAction:action count:count];
			}
			totalAction = [SKAction sequence:@[introAction, action]];
			[slot runAction:totalAction withKey:animationName];

		}
		
		if (totalAction.duration > longestAction) {
			longestAction = totalAction.duration;
		}
	}
	for (SGG_SpineBone* bone in _bones) {
		[bone playAnimations:@[animationName]];
	}
//	NSLog(@"pressed play");

//reset root rotation and stuff
	[self resetRootBoneOverDuration:introPeriod];
	
	_currentAnimationSequence = [NSArray arrayWithObject:animationName];
	_isRunningAnimation = YES;
	
	if (count != -1) { //only turn boolean off if the action ever turns off
		SKAction* turnBoolOff = [SKAction customActionWithDuration:0 actionBlock:^(SKNode* node, CGFloat elapsedTime){
			SGG_Spine* spine = (SGG_Spine*)node;
			[spine stopAnimationAndPlayNextInQueue:useQueue];
		}];
		
		turnBoolOff = [SKAction sequence:@[
										   [SKAction waitForDuration:longestAction],
										   turnBoolOff,
										   ]];
		[self runAction:turnBoolOff withKey:@"setToTurnIsRunningAnimationOff"];
	}

	
}

-(void)runAnimationSequence:(NSArray *)animationNames andCount:(NSInteger)count {
	
	//fill in later
	
	
}

-(void)stopAnimation {
	[self stopAnimationAndPlayNextInQueue:NO];
}

-(void)stopAnimationAndPlayNextInQueue:(BOOL)queueNext {
	
//	for (int i = 0; i < _bones.count; i++) {
//		SGG_SpineBone* bone = (SGG_SpineBone*)[_bones objectAtIndex:i];
//		[bone removeAllActions];
//	}
	[self enumerateChildNodesWithName:@"//*" usingBlock:^(SKNode *node, BOOL *stop) {
		[node removeAllActions];
	}];
	
	[self setIsRunningAnimationNO];
	
	if (queueNext) {
		// play next in queue
		[self runAnimation:_queuedAnimation andCount:_queueCount withSpeedFactor:1 withIntroPeriodOf:_queueIntro andUseQueue:YES];
	}

}

-(void)changeSkinTo:(NSString*)skin {
	
	for (int i = 0; i < _currentSkinSlots.count; i++) {
		SKNode* slot = (SKNode*)[_currentSkinSlots objectAtIndex:i];
		[slot enumerateChildNodesWithName:@"//*" usingBlock:^(SKNode *node, BOOL *stop) {
			node.hidden = HIDDEN;
		}];
		[slot removeFromParent];
	}

	_currentSkin = skin;
	
	[self setUpAttachmentsWithSlotsArray:_slotsArray];
	
}

-(void)changeSkinPartial:(NSDictionary *)slotsToReplace {
    // replaces the skin for specified slots without redrawing the whole skin - useful for 'battle damage', etc.
    for (int i = 0; i < _currentSkinSlots.count; i++) {
		SKNode* slot = (SKNode*)[_currentSkinSlots objectAtIndex:i];
        [slot enumerateChildNodesWithName:@"//*" usingBlock:^(SKNode *node, BOOL *stop) {
            // loop through attached NSDictionary and find matching key...
            for(id key in slotsToReplace) {
                NSString *thisKey = (NSString *)key;
                if([thisKey isEqualToString:node.name]) {
                    SKSpriteNode* thisNode = (SKSpriteNode *)node;
                    SKTexture* originalTexture = thisNode.texture;
                    thisNode.texture = [SKTexture textureWithImageNamed:[slotsToReplace objectForKey:(key)]];
                    
                    // add the original texture to an array so that we can swap back later
                    if(!_swappedSkins.count) {
                        _swappedSkins = [[NSMutableDictionary alloc] init];
                    }
                    
                    [_swappedSkins setObject:(NSString *)originalTexture forKey:key];
                    break;
                }
            }
		}];
	}
}

-(void)resetSkinPartial {
    // resets any swapped slots
    if(_swappedSkins.count) {
        
        for (int i = 0; i < _currentSkinSlots.count; i++) {
            SKNode* slot = (SKNode*)[_currentSkinSlots objectAtIndex:i];
            [slot enumerateChildNodesWithName:@"//*" usingBlock:^(SKNode *node, BOOL *stop) {
                // loop through attached NSDictionary and find matching key...
                for(id key in _swappedSkins) {
                    NSString* thisKey = (NSString *)key;
                    if([thisKey isEqualToString:node.name]) {
                        SKSpriteNode* thisNode = (SKSpriteNode *)node;
                        thisNode.texture = (SKTexture *)[_swappedSkins objectForKey:(key)];
                        break;
                    }
                }
            }];
        }
        
        [_swappedSkins removeAllObjects];
    }
}

-(void)colorizeSlots:(NSArray *)slotsToColorize withColor:(SKColor *)color andIntensity:(CGFloat)blendFactor {
    // colorizes the specified parts of the skin with the supplied color, to the intensity indicated - can be used to change hair/skin color dynamically, or 'flashing' a body part when hit...
    
    for (int i = 0; i < _currentSkinSlots.count; i++) {
		SKNode* slot = (SKNode*)[_currentSkinSlots objectAtIndex:i];
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

-(void)resetSkeleton {
	
	for (int i = 0; i < _bones.count; i++) {
		SGG_SpineBone* bone = (SGG_SpineBone*)[_bones objectAtIndex:i];
		[bone setToDefaults];
	}
	NSDictionary* skinDict = [_skins objectForKey:_currentSkin];
	NSArray* allSlots = [skinDict allKeys];
	for (int i = 0; i < allSlots.count; i++) {
		SGG_SkinSlot* skinSlot = (SGG_SkinSlot*)[skinDict objectForKey:[allSlots objectAtIndex:i]];
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

//-(void)activateAnimations {
//	CFTimeInterval time = CFAbsoluteTimeGetCurrent();
//	for (SGG_SpineBone* bone in _bones) {
//		[bone updateAnimationAtTime:time thatStartedAt:animationStartTime];
//	}
//}

-(void)activateAnimations {
	CFTimeInterval time = CFAbsoluteTimeGetCurrent();
	
	double timeElapsed = time - animationStartTime;

	NSInteger framesElapsed = round(timeElapsed / 0.008333333333333333); // 1/120


	NSInteger currentFrame = 0;
	
//	for (SGG_SpineBone* bone in _bones) {
	for (int i = 0; i < _bones.count; i++) {
		SGG_SpineBone* bone = (SGG_SpineBone*)_bones[i];
		if (bone.currentAnimation.count && !currentFrame) {
			currentFrame = framesElapsed % (bone.currentAnimation.count - 1);
		}
		

		[bone updateAnimationAtFrame:currentFrame];
	}
	
	if (_debugMode) {
		SKLabelNode* frameCounter = (SKLabelNode*)[self childNodeWithName:@"frameCounter"];
		frameCounter.text = [NSString stringWithFormat:@"%i", (int)currentFrame];
	}
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

-(void)createSkinsFromDict:(NSDictionary*)skinsDict andAtlasNamed:(NSString*)atlasName{
	//pull in texture atlas
	SKTextureAtlas* atlas = [SKTextureAtlas atlasNamed:atlasName];
	
	_skins = [[NSMutableDictionary alloc] init];
	//get all skins
	NSArray* skinKeys = [skinsDict allKeys];
	
	if (_debugMode) {
		NSLog(@"skinKeys: %@", skinKeys);
	}
	for (int i = 0; i < skinKeys.count; i++) {
		NSString* skinName = [skinKeys objectAtIndex:i];
		
		NSMutableDictionary* skinSlotsDictionary = [[NSMutableDictionary alloc] init];
		
		//get all skin slots
		NSDictionary* skinSlots = [NSDictionary dictionaryWithDictionary:[skinsDict objectForKey:skinName]];
		NSArray* skinSlotNames = [skinSlots allKeys];
		//		NSLog(@"skinSlotNames: %@", skinSlotNames);
		
		for (int h = 0; h < skinSlotNames.count; h++) {
			SGG_SkinSlot* skinSlot = [SGG_SkinSlot node];
			skinSlot.name = [skinSlotNames objectAtIndex:h];
			// get all skin sprites
			
			NSDictionary* skinSprites = [NSDictionary dictionaryWithDictionary:[skinSlots objectForKey:skinSlot.name]];
			NSArray* skinSpriteNames = [skinSprites allKeys];
			//			NSLog(@"skinSpriteNames: %@", skinSpriteNames);
			for (int j = 0; j < skinSpriteNames.count; j++) {
				
				NSString* spriteString = [skinSpriteNames objectAtIndex:j];
				NSDictionary* spriteDict = [NSDictionary dictionaryWithDictionary:[skinSprites objectForKey: spriteString]];
				
				NSString* spriteNameString;
				if ([spriteDict objectForKey:@"name"]) {
					spriteNameString = [spriteDict objectForKey:@"name"];
					spriteNameString = [spriteNameString stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
//					NSLog(@"spriteNameString after conversion: %@", spriteNameString);
				} else {
					spriteNameString = spriteString;
				}
				
				SGG_SkinSprite* skinSprite = [SGG_SkinSprite spriteNodeWithTexture:[atlas textureNamed:spriteNameString]];
				skinSprite.name = spriteString;
//				if ([spriteDict objectForKey:@"name"]) {
//					skinSprite.actualAttachmentName = [spriteDict objectForKey:@"name"];
//				} else {
//					skinSprite.actualAttachmentName = skinSprite.name;
//				}
				
				skinSprite.position = CGPointMake([[spriteDict objectForKey:@"x"] doubleValue], [[spriteDict objectForKey:@"y"] doubleValue]);
				if ([spriteDict objectForKey:@"scaleX"]) {
					skinSprite.xScale = [[spriteDict objectForKey:@"scaleX"] doubleValue];
				}
				
				if ([spriteDict objectForKey:@"scaleY"]) {
					skinSprite.yScale = [[spriteDict objectForKey:@"scaleY"] doubleValue];
				}
				skinSprite.zRotation = [[spriteDict objectForKey:@"rotation"] doubleValue] * SPINE_DEGTORADFACTOR;
				skinSprite.sizeFromJSON = CGSizeMake([[spriteDict objectForKey:@"width"] doubleValue], [[spriteDict objectForKey:@"height"] doubleValue]);
				

				[skinSprite setDefaults];
				skinSprite.hidden = HIDDEN;
	
//				NSLog(@"skinSprite %@ added to skinSlot %@", skinSprite.name, skinSlot.name);
				[skinSlot addChild:skinSprite];
			}
			//			[skin addChild:skinSlot];
			[skinSlotsDictionary setObject:skinSlot forKey:skinSlot.name];
		}
//		NSLog(@"skinSlotsDictionary: %@", skinSlotsDictionary);
		[_skins setObject:skinSlotsDictionary forKey:skinName];
	}
	
	
	
	
}

-(void)setUpAttachmentsWithSlotsArray:(NSArray*)slotsArray {
	
	NSMutableArray* currentSkinSlotsMutable = [[NSMutableArray alloc] init];
	
	NSDictionary* skinDict = [_skins objectForKey:_currentSkin];
	NSDictionary* defaultDict;
	if (![_currentSkin isEqualToString:@"default"]) {
		defaultDict = [_skins objectForKey:@"default"];
	}
	
	//	NSLog(@"skinDict: %@", skinDict);
	
	for (int i = 0; i < slotsArray.count; i++) {
		NSDictionary* slotDict = [NSDictionary dictionaryWithDictionary:[slotsArray objectAtIndex:i]];
		NSString* attachment = [slotDict objectForKey:@"attachment"]; //image name
		NSString* boneString = [slotDict objectForKey:@"bone"];
		NSString* name = [slotDict objectForKey:@"name"];
		
		bool usesDefaultSkin = YES;

		
		SGG_SkinSlot* skinSlot;
		if ([skinDict objectForKey:name]) {
			skinSlot = (SGG_SkinSlot*)[skinDict objectForKey:name];
			if (_debugMode) {
				NSLog(@"using %@ for %@", _currentSkin, skinSlot.name);
			}
			usesDefaultSkin = NO;
		} else {
			skinSlot = (SGG_SkinSlot*)[defaultDict objectForKey:name];
			if (_debugMode) {
				NSLog(@"using default for %@", skinSlot.name);
			}
			usesDefaultSkin = YES;
		}
		
//		if ([_currentSkin isEqualToString:@"default"] || usesDefaultSkin) {
			skinSlot.currentAttachment = attachment;
			skinSlot.defaultAttachment = attachment;
//		} else {
//			NSString* attachmentName = [NSString stringWithFormat:@"%@-%@", _currentSkin, attachment];
//			skinSlot.currentAttachment = attachmentName;
//			skinSlot.defaultAttachment = attachmentName;
//		}
		
//		NSLog(@"currentAttachment: %@", skinSlot.currentAttachment);
		
		skinSlot.zPosition = i * 0.1;

		for (int b = 0; b < _bones.count; b++) { //find bone for slot
			SGG_SpineBone* bone = (SGG_SpineBone*)[_bones objectAtIndex:b];
			if ([bone.name isEqualToString:boneString]) {
				[bone addChild:skinSlot];
			}
		}
		
		
		
		[skinSlot enumerateChildNodesWithName:skinSlot.currentAttachment usingBlock:^(SKNode *node, BOOL *stop) {
			node.hidden = VISIBLE;
		}];
		
		[currentSkinSlotsMutable addObject:skinSlot];
		
	}
	
	_currentSkinSlots = [NSArray arrayWithArray:currentSkinSlotsMutable];
	
	
}

-(void)setUpAnimationsWithAnimationDictionary:(NSDictionary*)animationDictionary withIntroPeriodOf:(CGFloat)introPeriod{
	
	if (!_animations) {
		_animations = [[NSMutableDictionary alloc]init];
	}
	
	NSArray* animationNames = [animationDictionary allKeys];
	for (int i = 0; i < animationNames.count; i++) {
	//cycle through all animations
	
		NSMutableArray* thisTempAnimationArray = [[NSMutableArray alloc]init];
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
			NSDictionary* SRTtimelinesForBone = [boneAnimationsDict objectForKey:bone.name]; //does this work?!
			
			//set up scale actions for bone
//			SKAction* boneScale = [self createBoneScaleActionsFromArray:scales forBone:bone andTotalLengthOfAnimation:longestDuration andIntroPeriodOf:introPeriod];
			
			//set up actions for bone
			NSArray* translations = [SRTtimelinesForBone objectForKey:@"translate"];
			NSArray* rotations = [SRTtimelinesForBone objectForKey:@"rotate"];
			NSArray* scales = [SRTtimelinesForBone objectForKey:@"scale"];
			SGG_SpineBoneAction* boneAction = [self createBoneTranslationActionsFromArray:translations andRotationsFromArray:rotations andScalesFromArray:scales forBone:bone andTotalLengthOfAnimation:longestDuration andIntroPeriodOf:introPeriod];

			//start old stuff
//			SKAction* totalBoneAnimation = [[SKAction alloc] init];
			//			totalBoneAnimation.animationType = kSGG_SpineAnimationTypeBone;
			//			totalBoneAnimation.attachmentName = bone.name;
			
//			totalBoneAnimation = (SKAction*)[SKAction group:@[
//															  ]]; //group SRT animations together here and add this to the dict
//			NSArray* keys = @[@"action", @"animationType", @"attachmentName"];
//			NSArray* objects = @[totalBoneAnimation, [NSNumber numberWithInteger:kSGG_SpineAnimationTypeBone], bone.name];
			
//			NSDictionary* thisBoneAniDict = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
//			[thisTempAnimationArray addObject:thisBoneAniDict];
			
			//end old stuff
			
			[bone.animations setObject:boneAction forKey:thisAnimationName];
		}
		
		
		NSDictionary* slotsAnimationsDict = [NSDictionary dictionaryWithDictionary:[thisAnimationDict objectForKey:@"slots"]];
		NSArray* slotNames = [slotsAnimationsDict allKeys];
		NSDictionary* skinDict = [_skins objectForKey:_currentSkin];
		for (int i = 0; i < slotNames.count; i++) {
		// cycle through individual slot animations
		
			NSString* slotName = [slotNames objectAtIndex:i];
			NSDictionary* slotDict = [slotsAnimationsDict objectForKey:slotName];
			SGG_SkinSlot* slot = (SGG_SkinSlot*)[skinDict objectForKey:[skinDict objectForKey:slotName]];

			SKAction* slotActions = [self createSlotActionsFromDictionary:slotDict forSlot:slot andTotalLengthOfAnimation:longestDuration andIntroPeriodOf:introPeriod];

			NSArray* keys = @[@"action", @"animationType", @"attachmentName"];
			NSArray* objects = @[slotActions, [NSNumber numberWithInteger:kSGG_SpineAnimationTypeSlots], slotName];
			NSDictionary* thisSlotAniDict = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
			[thisTempAnimationArray addObject:thisSlotAniDict];

			
		}

		
		
		
		//		NSDictionary* drawOrderAnimationsDict = [NSDictionary dictionaryWithDictionary:[thisAnimationDict objectForKey:@"draworder"]];
		
		
		//add this entire animation (individual animations for each bone and slot) to the animations dictionary
		NSArray* immutableArray = [NSArray arrayWithArray:thisTempAnimationArray];
		
		NSString* key;
		if (introPeriod == 0) {
			key = thisAnimationName;
		} else {
			key = [NSString stringWithFormat:@"%f-intro-%@", introPeriod, thisAnimationName];
		}
		
		[_animations setObject:immutableArray forKey:key];
		
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




-(SGG_SpineBoneAction*)createBoneTranslationActionsFromArray:(NSArray*)translations andRotationsFromArray:(NSArray*)rotations andScalesFromArray:(NSArray*)scales forBone:(SGG_SpineBone*)bone andTotalLengthOfAnimation:(const CGFloat)longestDuration andIntroPeriodOf:(const CGFloat)intro {
	
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



-(SKAction*)createSlotActionsFromDictionary:(NSDictionary*)slotDict forSlot:(SGG_SkinSlot*)slot andTotalLengthOfAnimation:(const CGFloat)longestDuration andIntroPeriodOf:(const CGFloat)intro {
	
	//	NSLog(@"slotDict: %@", slotDict);
	
	
	NSArray* attachmentTimings = [NSArray arrayWithArray:[slotDict objectForKey:@"attachment"]];
	NSArray* colorTimings = [slotDict objectForKey:@"color"];
	SKAction* slotAction = [[SKAction alloc] init];
	
	//attachments
	SKAction* attachmentAction = [[SKAction alloc] init];
	
	if (attachmentTimings) {
		
		CGFloat totalTimeForThisAnimation = 0;
		
		for (int c = 0; c < attachmentTimings.count; c++) {
			NSDictionary* attachmentDict = [attachmentTimings objectAtIndex:c];
			NSString* attachmentName = [attachmentDict objectForKey:@"name"];
			CGFloat time = [[attachmentDict objectForKey:@"time"] doubleValue];
			
			CGFloat timeForThisAnimationSegment = time - totalTimeForThisAnimation + intro;
			totalTimeForThisAnimation += timeForThisAnimationSegment;
			
			SKAction* waitingAction = [SKAction waitForDuration:timeForThisAnimationSegment];
			attachmentAction = [SKAction sequence:@[
													attachmentAction,
													waitingAction,
													[SKAction customActionWithDuration:0 actionBlock:^(SKNode* node, CGFloat elapsedTime){
				SGG_SkinSlot* skinSlot = (SGG_SkinSlot*)node;
				[skinSlot setAttachmentTo:attachmentName];
				//														NSLog(@"custom action ran");
			}]
													]];
			
			
		}
		
		if (totalTimeForThisAnimation < (longestDuration + intro)) {
			SKAction* waiting = [SKAction waitForDuration:((longestDuration + intro) - totalTimeForThisAnimation)];
			attachmentAction = [SKAction sequence:@[attachmentAction, waiting]];
		}
	}
	
	
	
	//colors
//	SKAction* colorAction = [SKAction colorizeWithColor:[SKColor whiteColor] colorBlendFactor:0 duration:0];
	if (colorTimings) {
		CGFloat totalTimeForThisAnimation = 0;
		
		for (int c = 0; c < attachmentTimings.count; c++) {
			NSDictionary* attachmentDict = [attachmentTimings objectAtIndex:c];
			NSString* attachmentName = [attachmentDict objectForKey:@"name"];
			CGFloat time = [[attachmentDict objectForKey:@"time"] doubleValue];
			
			CGFloat timeForThisAnimationSegment = time - totalTimeForThisAnimation;
			totalTimeForThisAnimation += timeForThisAnimationSegment;
			
			SKAction* waitingAction = [SKAction waitForDuration:timeForThisAnimationSegment];
			attachmentAction = [SKAction sequence:@[
													attachmentAction,
													waitingAction,
													[SKAction customActionWithDuration:0 actionBlock:^(SKNode* node, CGFloat elapsedTime){
				SGG_SkinSlot* skinSlot = (SGG_SkinSlot*)node;
				[skinSlot setAttachmentTo:attachmentName];
				//														NSLog(@"custom action ran");
			}]
													]];
			
			
		}
		
		if (totalTimeForThisAnimation < longestDuration) {
			SKAction* waiting = [SKAction waitForDuration:(longestDuration - totalTimeForThisAnimation)];
			attachmentAction = [SKAction sequence:@[attachmentAction, waiting]];
		}
	}
	
	
	slotAction = [SKAction group:@[
								   attachmentAction,
								   //								   colorAction,
								   ]];
	
	return slotAction;
}

#pragma mark PROPERTY HANDLERS

-(void)setIsRunningAnimationYES {
	_isRunningAnimation = YES;
}

-(void)setIsRunningAnimationNO {
	_isRunningAnimation = NO;
	_currentAnimationSequence = nil;
//	NSLog(@"animation done");
	
}

@end
