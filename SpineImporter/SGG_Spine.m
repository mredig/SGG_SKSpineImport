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
	
	SGG_SKUtilities* sharedUtilities;
	
}

@end

@implementation SGG_Spine

-(id)init {
	
	if (self = [super init]) {
		sharedUtilities = [SGG_SKUtilities sharedUtilities];
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
	
	
	[self runAnimation:animationName andCount:count withSpeedFactor:1];
	
}

-(void)runAnimation:(NSString *)animationName andCount:(NSInteger)count withSpeedFactor:(CGFloat)speedfactor { //intended to change speed of the animation, but isn't working with any value other than 1
	
	[self stopAnimation];
//	[self resetSkeleton];
	
	NSArray* thisAnimation = [_animations objectForKey:animationName];

	CGFloat longestAction = 0;
	
	for (int i = 0; i < thisAnimation.count; i++) {
		NSDictionary* thisAniDict = [thisAnimation objectAtIndex:i];
		kSGG_SpineAnimationType animationType = [[thisAniDict objectForKey:@"animationType"] intValue];
		NSString* attachmentName = [thisAniDict objectForKey:@"attachmentName"];
		NSDictionary* skinDict = [_skins objectForKey:_currentSkin];

		SKAction* action;
		if (animationType == kSGG_SpineAnimationTypeBone) {
			SGG_SpineBone* bone = [self findBoneNamed:attachmentName];
			action = [thisAniDict objectForKey:@"action"];
			if (count == -1) {
				action = [SKAction repeatActionForever:action];
			} else {
				action = [SKAction repeatAction:action count:count];
			}
			[bone runAction:action withKey:animationName];
		} else if (animationType == kSGG_SpineAnimationTypeSlots) {
			
			SGG_SkinSlot* slot = (SGG_SkinSlot*)[skinDict objectForKey:attachmentName];
			action = [thisAniDict objectForKey:@"action"];
			if (count == -1) {
				action = [SKAction repeatActionForever:action];
			} else {
				action = [SKAction repeatAction:action count:count];
			}
			[slot runAction:action withKey:animationName];
//			NSLog(@"slot animation linked: %@ to slot %@", action, slot);
//			NSLog(@"skinDict: %@", skinDict);
		}
		
		if (action.duration > longestAction) {
			longestAction = action.duration;
		}
	}
	
	//reset root rotation and stuff
	[self resetRootBoneOverDuration:0];
	
	_currentAnimationSequence = [NSArray arrayWithObject:animationName];
	_isRunningAnimation = YES;
	
	if (count > -1) {
		SKAction* turnBoolOff = [SKAction performSelector:@selector(setIsRunningAnimationNO) onTarget:self];
		turnBoolOff = [SKAction sequence:@[
										   [SKAction waitForDuration:longestAction],
										   turnBoolOff,
										   ]];
		[self runAction:turnBoolOff withKey:@"setToTurnIsRunningAnimationOff"];
//		[self performSelector:@selector(setIsRunningAnimationNO) withObject:nil afterDelay:longestAction];
	}
	
}

-(void)runAnimation:(NSString *)animationName andCount:(NSInteger)count withIntroPeriodOf:(const CGFloat)introPeriod { 	

	[self stopAnimation];
	
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

//reset root rotation and stuff
	[self resetRootBoneOverDuration:introPeriod];
	
	_currentAnimationSequence = [NSArray arrayWithObject:animationName];
	_isRunningAnimation = YES;
	
	if (count != -1) { //only turn boolean off if the action ever turns off
		SKAction* turnBoolOff = [SKAction performSelector:@selector(setIsRunningAnimationNO) onTarget:self];
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
	
//	for (int i = 0; i < _bones.count; i++) {
//		SGG_SpineBone* bone = (SGG_SpineBone*)[_bones objectAtIndex:i];
//		[bone removeAllActions];
//	}
	[self enumerateChildNodesWithName:@"//*" usingBlock:^(SKNode *node, BOOL *stop) {
		[node removeAllActions];
	}];
	
	[self setIsRunningAnimationNO];

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

#pragma mark SETUP FUNCTIONS

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
		bone.zRotation = [[boneDict objectForKey:@"rotation"] doubleValue] * sharedUtilities.degreesToRadiansConversionFactor;
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
		[bone setDefaults];
		
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
				skinSprite.zRotation = [[spriteDict objectForKey:@"rotation"] doubleValue] * sharedUtilities.degreesToRadiansConversionFactor;
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
			
			//set up rotation actions for bone
			NSArray* rotations = [SRTtimelinesForBone objectForKey:@"rotate"];
			SKAction* boneRotation = [self createBoneRotationActionsFromArray:rotations forBone:bone andTotalLengthOfAnimation:longestDuration andIntroPeriodOf:introPeriod];
			
			//set up translation actions for bone
			NSArray* translations = [SRTtimelinesForBone objectForKey:@"translate"];
			SKAction* boneTranslation = [self createBoneTranslationActionsFromArray:translations forBone:bone andTotalLengthOfAnimation:longestDuration andIntroPeriodOf:introPeriod];
			
			
			//set up scale actions for bone
			NSArray* scales = [SRTtimelinesForBone objectForKey:@"scale"];
			SKAction* boneScale = [self createBoneScaleActionsFromArray:scales forBone:bone andTotalLengthOfAnimation:longestDuration andIntroPeriodOf:introPeriod];
			
			SKAction* totalBoneAnimation = [[SKAction alloc] init];
			//			totalBoneAnimation.animationType = kSGG_SpineAnimationTypeBone;
			//			totalBoneAnimation.attachmentName = bone.name;
			
			totalBoneAnimation = (SKAction*)[SKAction group:@[boneRotation,
															  boneTranslation,
															  boneScale,
															  ]]; //group SRT animations together here and add this to the dict
			NSArray* keys = @[@"action", @"animationType", @"attachmentName"];
			NSArray* objects = @[totalBoneAnimation, [NSNumber numberWithInteger:kSGG_SpineAnimationTypeBone], bone.name];
			
			NSDictionary* thisBoneAniDict = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
			[thisTempAnimationArray addObject:thisBoneAniDict];
			
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

-(SKAction*)createBoneRotationActionsFromArray:(NSArray*)rotations forBone:(SGG_SpineBone*)bone andTotalLengthOfAnimation:(const CGFloat)longestDuration andIntroPeriodOf:(const CGFloat)intro {
	
	CGFloat totalTimeForThisAnimation = 0;
	SKAction* boneRotation = [[SKAction alloc] init];
	
	for (int d = 0; d < rotations.count; d++) {
		NSDictionary* rotation = [rotations objectAtIndex:d];
		CGFloat angle, time;
		id curveInfo;
		
		angle = [[rotation objectForKey:@"angle"] doubleValue] * sharedUtilities.degreesToRadiansConversionFactor;
		time = [[rotation objectForKey:@"time"] doubleValue];
		
		CGFloat timeForThisAnimationSegment = time - totalTimeForThisAnimation + intro;
		totalTimeForThisAnimation += timeForThisAnimationSegment;
		
		curveInfo = [rotation objectForKey:@"curve"];
		
		if (curveInfo) {
			NSString* curveString = (NSString*)curveInfo;
			if ([curveInfo isKindOfClass:[NSString class]] && [curveString isEqualToString:@"stepped"]) {
				angle += bone.defaultRotation;
				SKAction* waitingAction = [SKAction waitForDuration:timeForThisAnimationSegment];
				SKAction* rotationAction = [SKAction rotateToAngle:angle duration:0 shortestUnitArc:YES];
				boneRotation = [SKAction sequence:@[waitingAction, boneRotation, rotationAction]];
				if (_debugMode) {
					NSLog(@"stepped");
				}
			} else {
				NSArray* curveArray = [NSArray arrayWithArray:curveInfo];
				angle += bone.defaultRotation;
				SKAction* rotationAction = [SKAction rotateToAngle:angle duration:timeForThisAnimationSegment shortestUnitArc:YES];
				rotationAction.timingMode = [self determineTimingMode:curveArray];
				boneRotation = [SKAction sequence:@[boneRotation, rotationAction]];
				if (_debugMode) {
					NSLog(@"eased with mode: %i", (int)rotationAction.timingMode);
				}
			}
		} else {
			angle += bone.defaultRotation;
			SKAction* rotationAction = [SKAction rotateToAngle:angle duration:timeForThisAnimationSegment shortestUnitArc:YES];
			boneRotation = [SKAction sequence:@[boneRotation, rotationAction]];
			if (_debugMode) {
				NSLog(@"lineared");
			}
		}
		
	}
	if (totalTimeForThisAnimation < (longestDuration + intro)) {
		SKAction* waiting = [SKAction waitForDuration:((longestDuration + intro) - totalTimeForThisAnimation)];
		boneRotation = [SKAction sequence:@[boneRotation, waiting]];
	}
	
	return boneRotation;
}

-(SKAction*)createBoneTranslationActionsFromArray:(NSArray*)translations forBone:(SGG_SpineBone*)bone andTotalLengthOfAnimation:(const CGFloat)longestDuration andIntroPeriodOf:(const CGFloat)intro {
	
	CGFloat totalTimeForThisAnimation = 0;
	SKAction* boneTranslation = [[SKAction alloc] init];
	
	for (int d = 0; d < translations.count; d++) {
		NSDictionary* translation = [translations objectAtIndex:d];
		CGFloat x, y, time;
		id curveInfo;
		
		x = [[translation objectForKey:@"x"] doubleValue];
		y = [[translation objectForKey:@"y"] doubleValue];
		time = [[translation objectForKey:@"time"] doubleValue];
		
		
		CGFloat timeForThisAnimationSegment = time - totalTimeForThisAnimation + intro;
		totalTimeForThisAnimation += timeForThisAnimationSegment;
		
		curveInfo = [translation objectForKey:@"curve"];
		
		if (curveInfo) {
			NSString* curveString = (NSString*)curveInfo;
			if ([curveInfo isKindOfClass:[NSString class]] && [curveString isEqualToString:@"stepped"]) {
				SKAction* waitingAction = [SKAction waitForDuration:timeForThisAnimationSegment];
				CGPoint translateDestination = CGPointMake(bone.defaultPosition.x + x, bone.defaultPosition.y + y);
				SKAction* translationAction = [SKAction moveTo:translateDestination duration:0];
				boneTranslation = [SKAction sequence:@[waitingAction, boneTranslation, translationAction]];
				if (_debugMode) {
					NSLog(@"stepped");
				}
			} else {
				NSArray* curveArray = [NSArray arrayWithArray:curveInfo];
				CGPoint translateDestination = CGPointMake(bone.defaultPosition.x + x, bone.defaultPosition.y + y);
				SKAction* translationAction = [SKAction moveTo:translateDestination duration:timeForThisAnimationSegment];
				translationAction.timingMode = [self determineTimingMode:curveArray];
				boneTranslation = [SKAction sequence:@[boneTranslation, translationAction]];
				if (_debugMode) {
					NSLog(@"eased with mode: %i", (int)translationAction.timingMode);
				}
			}
		} else {
			CGPoint translateDestination = CGPointMake(bone.defaultPosition.x + x, bone.defaultPosition.y + y);
			SKAction* translationAction = [SKAction moveTo:translateDestination duration:timeForThisAnimationSegment];
			boneTranslation = [SKAction sequence:@[boneTranslation, translationAction]];
			if (_debugMode) {
				NSLog(@"lineared");
			}
		}
		
	}
	if (totalTimeForThisAnimation < (longestDuration + intro)) {
		SKAction* waiting = [SKAction waitForDuration:((longestDuration + intro) - totalTimeForThisAnimation)];
		boneTranslation = [SKAction sequence:@[boneTranslation, waiting]];
	}
	
	return boneTranslation;
}

-(SKAction*)createBoneScaleActionsFromArray:(NSArray*)scales forBone:(SGG_SpineBone*)bone andTotalLengthOfAnimation:(const CGFloat)longestDuration andIntroPeriodOf:(const CGFloat)intro {
	
	CGFloat totalTimeForThisAnimation = 0;
	SKAction* boneScale = [[SKAction alloc] init];
	
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
		
		time = [[scale objectForKey:@"time"] doubleValue];
		
		
		CGFloat timeForThisAnimationSegment = time - totalTimeForThisAnimation + intro;
		totalTimeForThisAnimation += timeForThisAnimationSegment;
		
		curveInfo = [scale objectForKey:@"curve"];
		
		if (curveInfo) {
			NSString* curveString = (NSString*)curveInfo;
			if ([curveInfo isKindOfClass:[NSString class]] && [curveString isEqualToString:@"stepped"]) {
				SKAction* waitingAction = [SKAction waitForDuration:timeForThisAnimationSegment];
				
				CGFloat scaleXby = bone.defaultScaleX * x;
				CGFloat scaleYby = bone.defaultScaleY * y;
				SKAction* scaleAction = [SKAction scaleXTo:scaleXby y:scaleYby duration:0];
				boneScale = [SKAction sequence:@[waitingAction, boneScale, scaleAction]];
				
				if (_debugMode) {
					NSLog(@"stepped");
				}
			} else {
				NSArray* curveArray = [NSArray arrayWithArray:curveInfo];
				
				CGFloat scaleXby = bone.defaultScaleX * x;
				CGFloat scaleYby = bone.defaultScaleY * y;
				SKAction* scaleAction = [SKAction scaleXTo:scaleXby y:scaleYby duration:timeForThisAnimationSegment];
				scaleAction.timingMode = [self determineTimingMode:curveArray];
				boneScale = [SKAction sequence:@[boneScale, scaleAction]];
				
				if (_debugMode) {
					NSLog(@"eased with mode: %i", (int)scaleAction.timingMode);
				}
			}
		} else {
			CGFloat scaleXby = bone.defaultScaleX * x;
			CGFloat scaleYby = bone.defaultScaleY * y;
			SKAction* scaleAction = [SKAction scaleXTo:scaleXby y:scaleYby duration:timeForThisAnimationSegment];
			boneScale = [SKAction sequence:@[boneScale, scaleAction]];
			if (_debugMode) {
				NSLog(@"lineared");
			}
		}
		
		
		
	}
	if (totalTimeForThisAnimation < (longestDuration + intro)) {
		SKAction* waiting = [SKAction waitForDuration:((longestDuration + intro) - totalTimeForThisAnimation)];
		boneScale = [SKAction sequence:@[boneScale, waiting]];
	}
	
	return boneScale;
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
	SKAction* colorAction = [SKAction colorizeWithColor:[SKColor whiteColor] colorBlendFactor:0 duration:0];
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
