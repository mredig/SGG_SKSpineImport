//
//  SGG_Spine.m
//  SpineTesting
//
//  Created by Michael Redig on 2/10/14.
//  Copyright (c) 2014 Secret Game Group LLC. All rights reserved.
//

#import "SGG_Spine.h"
#import "SGG_SpineJSONTools.h"

#import "AlphaValueHelper.h"
#import "ColorValueHelper.h"

@interface SGG_Spine () {
    
    //	SGG_SKUtilities* sharedUtilities;
    
    CFTimeInterval animationStartTime;
    NSInteger repeatAnimationCount;
    
    NSString* previousAnimation;
    
}

@end

@implementation SGG_Spine

-(id)init {
    
    if (self = [super init]) {
        //		sharedUtilities = [SGG_SKUtilities sharedUtilities];
        _isRunningAnimation = NO;
        _timeResolution = 1.0 / 120.0;
        _playbackSpeed = 1.0;
    }
    return self;
}

-(void)skeletonFromFileNamed:(NSString*)name andAtlasNamed:(NSString*)atlasName andUseSkinNamed:(NSString*)skinName {
    
    //	NSTimeInterval timea = CFAbsoluteTimeGetCurrent(); //benchmarking
    
    if (skinName) {
        self.currentSkin = skinName;
    } else {
        self.currentSkin = @"default";
    }
    
    SGG_SpineJSONTools* tools = [[SGG_SpineJSONTools alloc]init];
    NSDictionary* spineDict = [tools readJSONFileNamed:name];
    
    NSArray* boneArray = [NSArray arrayWithArray:[spineDict objectForKey:@"bones"]];
    [self createBonesFromArray:boneArray];
    
    self.slotsArray = [NSArray arrayWithArray:[spineDict objectForKey:@"slots"]];
    [self createSlotsAndAttachToBonesWithSlotsArray:self.slotsArray];
    
    NSDictionary* skinsDict = [NSDictionary dictionaryWithDictionary:[spineDict objectForKey:@"skins"]];
    [self createSkinsFromDict:skinsDict andAtlasNamed:atlasName];
    
    self.rawAnimationDictionary = [NSDictionary dictionaryWithDictionary:[spineDict objectForKey:@"animations"]];
    [self setUpAnimationsWithAnimationDictionary:self.rawAnimationDictionary withIntroPeriodOf:0.0f];
    
    [self changeSkinTo:_currentSkin];
    
    //	NSTimeInterval timeb = CFAbsoluteTimeGetCurrent(); //benchmarking
    //	NSLog(@"time taken: %f", timeb - timea); //benchmarking
    
}

#pragma mark PLAYBACK CONTROLS

-(void)runAnimation:(NSString*)animationName andCount:(NSInteger)count {
    
    
    bool useQueue;
    if  (self.queuedAnimation) {
        useQueue = YES;
    } else {
        useQueue = NO;
    }
    [self runAnimation:animationName andCount:count withIntroPeriodOf:0 andUseQueue:useQueue];
    
}


-(void)runAnimation:(NSString*)animationName andCount:(NSInteger)count withIntroPeriodOf:(const CGFloat)introPeriod andUseQueue:(BOOL)useQueue {
    
    
    if (introPeriod > 0) {
        [self createIntroAnimationIntoAnimation:animationName overDuration:introPeriod];
        [self runAnimationSequence:@[@"INTRO_ANIMATION", animationName] andUseQueue:useQueue];
        return;
    }
    
    if  (self.isRunningAnimation) {
        [self stopAnimation]; //clear any current animations
    }
    
    animationStartTime = CFAbsoluteTimeGetCurrent();
    
    _animationCount = count;
    
    
    _useQueue = useQueue;
    if (!self.queuedAnimation && useQueue) {
        self.queuedAnimation = animationName;
        NSLog(@"queue set");
    }
    
    
    NSInteger totalFrameCount = 0;
    for (SGG_SpineBone* bone in self.bones) {
        NSInteger thisFrameCount = [bone playAnimations:@[animationName]];
        totalFrameCount = MAX(totalFrameCount, thisFrameCount);
        if (thisFrameCount == 0 && self.debugMode) {
            NSLog(@"bone %@ has no frames.", bone.name);
        }
    }
    
    for (SGG_SkinSlot* skinSlot in self.skinSlots) {
        NSInteger thisFrameCount = [skinSlot playAnimations:@[animationName]];
        totalFrameCount = MAX(totalFrameCount, thisFrameCount);
        if (thisFrameCount == 0 && self.debugMode) {
            NSLog(@"slot %@ has no frames.", skinSlot.name);
        }
    }
    if  (self.debugMode) {
        NSLog(@"running animation: %@ : %i frames",animationName, (int)totalFrameCount);
    }
    
    //reset root rotation and stuff
    [self resetRootBoneOverDuration:introPeriod];
    
    if  (self.currentAnimationSequence.count <= 1) {
        _currentAnimationSequence = nil;
    }
    
    _currentAnimation = animationName;
    _isRunningAnimation = YES;
}

-(void)runAnimationSequence:(NSArray *)animationNames andUseQueue:(BOOL)useQueue {
    
    //fill in later
    _currentAnimationSequence = [NSMutableArray arrayWithArray:animationNames];
    
    [self runAnimation:_currentAnimationSequence[0] andCount:0 withIntroPeriodOf:0 andUseQueue:useQueue];
}

-(void)stopAnimation {
    [self stopAnimationAndPlayNextInQueue:NO];
}

-(void)stopAnimationAndPlayNextInQueue:(BOOL)queueNext {
    
    if  (self.currentAnimation) {
        previousAnimation = self.currentAnimation;
        
    }
    
    for (SGG_SpineBone* bone in self.bones) {
        [bone stopAnimation];
    }
    
    for (SGG_SkinSlot* skinSlot in self.skinSlots) {
        [skinSlot stopAnimation];
    }
    
    [self setIsRunningAnimationNO];
    
    if (queueNext) {
        // play next in queue
        [self runAnimation:_queuedAnimation andCount:-1 withIntroPeriodOf:_queueIntro andUseQueue:YES];
    }
    
}



-(void)resetSkeleton {
    
    for (int i = 0; i < self.bones.count; i++) {
        SGG_SpineBone* bone = (SGG_SpineBone*)[_bones objectAtIndex:i];
        [bone setToDefaults];
    }
    for (int i = 0; i < self.skinSlots.count; i++) {
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
    
    for (int i = 0; i < self.bones.count; i++) {
        SGG_SpineBone* bone = (SGG_SpineBone*)[_bones objectAtIndex:i];
        if ([bone.name isEqualToString:boneName]) {
            return bone;
        }
    }
    
    return nil;
}


-(void)activateAnimations {
    if  (self.isRunningAnimation) {
        
        CFTimeInterval time = CFAbsoluteTimeGetCurrent();
        
        double timeElapsed = time - animationStartTime;
        
        
        CGFloat framerateCalcuator = (1.0 / self.playbackSpeed) * self.timeResolution;
        NSInteger framesElapsed = round(timeElapsed / framerateCalcuator);
        
        
        NSInteger currentFrame = 0;
        NSInteger totalFrames = 0;
        
        bool boneAnimationEnded = NO;
        bool slotAnimationEnded = NO;
        
        for (int i = 0; i < self.bones.count; i++) {
            SGG_SpineBone* bone = (SGG_SpineBone*)_bones[i];
            if (bone.currentAnimation.count > 1 && !currentFrame) {
                currentFrame = framesElapsed;
                if ((framesElapsed+1) >= bone.currentAnimation.count) {
                    //					currentFrame = framesElapsed % (bone.currentAnimation.count - 1);
                    currentFrame = MIN(bone.currentAnimation.count, framesElapsed);
                    boneAnimationEnded = YES;
                }
            }
            totalFrames = MAX(totalFrames, bone.currentAnimation.count);
            
            [bone updateAnimationAtFrame:currentFrame];
            
        }
        
        for (int i = 0; i < self.skinSlots.count; i++) {
            SGG_SkinSlot* skinSlot = self.skinSlots[i];
            if (skinSlot.currentAnimation.count > 1 && !currentFrame) {
                currentFrame = framesElapsed % (skinSlot.currentAnimation.count - 1);
            }
            if ((framesElapsed+1) >= skinSlot.currentAnimation.count) {
                slotAnimationEnded = YES;
            }
            [skinSlot updateAnimationAtFrame:currentFrame];
        }
        
        
        _currentFrame = currentFrame;
        
        
        if  (self.debugMode) {
            SKLabelNode* frameCounter = (SKLabelNode*)[self childNodeWithName:@"frameCounter"];
            frameCounter.text = [NSString stringWithFormat:@"%i of %i", (int)currentFrame, (int)totalFrames];
        }
        
        if (boneAnimationEnded && slotAnimationEnded) {
            [self endOfAnimation];
        }
        
    }
}

-(void)jumpToFrame:(NSInteger)frame {
    
    [self stopAnimation];
    
    for (SGG_SpineBone* bone in self.bones) {
        [bone playAnimations:@[previousAnimation]];
    }
    
    for (SGG_SkinSlot* skinSlot in self.skinSlots) {
        [skinSlot playAnimations:@[previousAnimation]];
    }
    
    for (int i = 0; i < self.bones.count; i++) {
        SGG_SpineBone* bone = (SGG_SpineBone*)_bones[i];
        NSInteger aniCount = (NSInteger)bone.currentAnimation.count;
        aniCount --;
        NSInteger boneframe = MIN(frame, aniCount);
        
        [bone updateAnimationAtFrame:boneframe];
        
    }
    
    for (int i = 0; i < self.skinSlots.count; i++) {
        SGG_SkinSlot* skinSlot = self.skinSlots[i];
        NSInteger aniCount = (NSInteger)(skinSlot.currentAnimation.count );
        aniCount --;
        
        NSInteger slotFrame = MIN(frame, aniCount);
        
        [skinSlot updateAnimationAtFrame:slotFrame];
    }
    
    [self stopAnimation];
}

-(void)jumpToNextFrame {
    
    
    
    _currentFrame ++;
    [self jumpToFrame:_currentFrame];
    
}

-(void)jumpToPreviousFrame {
    
    _currentFrame--;
    if  (self.currentFrame < 0) {
        _currentFrame = 0;
    }
    [self jumpToFrame:_currentFrame];
    
}

-(void)endOfAnimation {
    if ([_currentAnimation isEqualToString:@"INTRO_ANIMATION"]) { //clear out intro animation after it's been used
        if  (self.debugMode) {
            NSLog(@"finished intro");
            
        }
        for (SGG_SpineBone* bone in self.bones) {
            [bone.animations removeObjectForKey:@"INTRO_ANIMATION"];
        }
        
        for (SGG_SkinSlot* skinSlot in self.skinSlots) {
            [skinSlot.animations removeObjectForKey:@"INTRO_ANIMATION"];
        }
    }
    
    if  (self.currentAnimationSequence.count > 1) { //if running a sequence, remove the first listed animation in the sequence and move on to the next
        if ([_currentAnimation isEqualToString:_currentAnimationSequence[0]]) {
            [_currentAnimationSequence removeObjectAtIndex:0];
        }
        [self runAnimation:_currentAnimationSequence[0] andCount:0 withIntroPeriodOf:0 andUseQueue:YES];
        
    } else if  (self.animationCount > 0){ //if animation is set to repeat x times start the same animation over and count -1 in count
        _animationCount -= 1;
        if  (self.animationCount == -1) {
            [self stopAnimation];
            _animationCount = 0;
            return;
        } else {
            [self runAnimation:_currentAnimation andCount:_animationCount withIntroPeriodOf:0 andUseQueue:_useQueue];
        }
        
    } else if  (self.animationCount == -1) { //if animation is set to repeat infinite times, repeat animation
        [self runAnimation:_currentAnimation andCount:-1 withIntroPeriodOf:0 andUseQueue:_useQueue];
        if  (self.debugMode) {
            NSLog(@"repeat");
        }
    } else if  (self.queuedAnimation != nil && self.useQueue) { //if queue is set, intro into queue. if already playing the queue animation, ignore the intro
        if ([_currentAnimation isEqualToString:_queuedAnimation]) {
            if  (self.debugMode) {
                NSLog(@"queued with no intro");
            }
            [self runAnimation:_queuedAnimation andCount:-1 withIntroPeriodOf:0 andUseQueue:YES];
        } else {
            if  (self.debugMode) {
                NSLog(@"queued with intro: %f", self.queueIntro);
            }
            [self runAnimation:_queuedAnimation andCount:-1 withIntroPeriodOf:_queueIntro andUseQueue:YES];
        }
        if  (self.debugMode) {
            NSLog(@"set to queue");
        }
    } else { //stop animation if nothing above qualifies
        [self stopAnimation];
        if  (self.debugMode) {
            NSLog(@"stopped");
        }
    }
    
}

-(void)animationCounter {
    if  (self.animationCount >= 0) {
        _animationCount -= 1;
    }
}

#pragma mark SKINNING

-(void)changeSkinTo:(NSString*)skin {
    
    for (SGG_SkinSlot* skinSlot in self.skinSlots) {
        [skinSlot changeSkinTo:skin];
    }
    
    self.currentSkin = skin;
    
}

-(void)changeSkinPartial:(NSDictionary *)slotsToReplace {
    // replaces the skin for specified slots without redrawing the whole skin - useful for 'battle damage', etc.
    NSArray* slotNames = [slotsToReplace allKeys];
    for (SGG_SkinSlot* skinSlot in self.skinSlots) {
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
    for (SGG_SkinSlot* skinSlot in self.skinSlots) {
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
                    NSDictionary* resetDict = [NSDictionary dictionaryWithObjects:@[originalTexture, self.currentSkin] forKeys:@[@"texture", @"originalSkin"]];
                    
                    [_swappedTextures setObject:resetDict forKey:thisAttachment.name];
                }
                break;
            }
        }
    }
}

-(void)resetTexturePartial {
    
    for (id key in self.swappedTextures) {
        NSString* thisKey = (NSString*)key;
        NSDictionary* resetDict = self.swappedTextures[thisKey];
        NSString* originalSkin = resetDict[@"originalSkin"];
        SKTexture* originalTexture = resetDict[@"texture"];
        for (SGG_SkinSlot* skinSlot in self.skinSlots) {
            NSDictionary* thisSlotSkinDict = skinSlot.skins[originalSkin];
            SKSpriteNode* thisAttachment = thisSlotSkinDict[thisKey];
            if (thisAttachment) {
                thisAttachment.texture = originalTexture;
                break;
            }
        }
    }
    
    self.swappedTextures = nil;
    
    
}


-(void)resetSkinPartial {
    // resets any swapped slots
    for (SGG_SkinSlot* skinSlot in self.skinSlots) {
        [skinSlot changeSkinTo:_currentSkin];
    }
}

-(void)colorizeAllSlotsWithColor:(SKColor *)color andIntensity:(CGFloat)blendFactor {
    // colorizes all parts of the skin with the supplied color, to the intensity indicated
    
    NSMutableArray *allSlots = [NSMutableArray array];
    
    for (NSDictionary *slot in self.slotsArray) {
        if (slot[@"attachment"])
            [allSlots addObject:[slot objectForKey:@"attachment"]];
    }
    
    [self colorizeSlots:allSlots withColor:color andIntensity:blendFactor];
}

-(void)colorizeSlots:(NSArray *)slotsToColorize withColor:(SKColor *)color andIntensity:(CGFloat)blendFactor {
    // colorizes the specified parts of the skin with the supplied color, to the intensity indicated - can be used to change hair/skin color dynamically, or 'flashing' a body part when hit...
    
    for (int i = 0; i < self.skinSlots.count; i++) {
        SKNode* slot = (SKNode*)[_skinSlots objectAtIndex:i];
        [slot enumerateChildNodesWithName:@".//*" usingBlock:^(SKNode *node, BOOL *stop) {
            for(NSString* colorizedNode in slotsToColorize){
                if([colorizedNode isEqualToString:node.name]) {
                    SKSpriteNode* thisNode = (SKSpriteNode *)node;
                    thisNode.color = color;
                    thisNode.colorBlendFactor = blendFactor;
                    
                    if(!_colorizedNodes.count) {
                        self.colorizedNodes = [[NSMutableArray alloc] init];
                    }
                    
                    self.colorizedNodes[_colorizedNodes.count] = node.name;
                    
                    break;
                }
            }
        }];
    }
}

-(void)resetColorizedSlots {
    
    [self colorizeSlots:_colorizedNodes withColor:[SKColor whiteColor] andIntensity:0];
    [self.colorizedNodes removeAllObjects];
    
}



#pragma mark SETUP FUNCTIONS

-(void)setDebugMode:(BOOL)debugMode {
    
    _debugMode = debugMode;
    
    if  (self.debugMode) {
        SKLabelNode* frameCounter = [SKLabelNode labelNodeWithFontNamed:@"Helvetica"];
        frameCounter.position = CGPointMake(0, 0);
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
        
        if  (self.debugMode) {
            [bone debugWithLength];
        }
        
        [mutableBones addObject:bone];
        //		NSLog(@"added bone: %@", bone);
    }
    
    self.bones = [NSArray arrayWithArray:mutableBones];
    
    
}


-(void)createSlotsAndAttachToBonesWithSlotsArray:(NSArray*)slotsArray {
    
    NSMutableArray* skinSlotsMutable = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < slotsArray.count; i++) {
        NSDictionary* slotDict = [NSDictionary dictionaryWithDictionary:[slotsArray objectAtIndex:i]];
        NSString* attachment = [slotDict objectForKey:@"attachment"]; //image name
        NSString* boneString = [slotDict objectForKey:@"bone"];
        NSString* name = [slotDict objectForKey:@"name"];
        NSString* color = [slotDict objectForKey:@"color"];
        
        
        SGG_SkinSlot* skinSlot = [SGG_SkinSlot node];
        skinSlot.name = name;
        
        SKSpriteNode* debugSlot = [SKSpriteNode spriteNodeWithColor:[SKColor greenColor] size:CGSizeMake(50, 5)];
        debugSlot.anchorPoint = CGPointMake(0, 0.5);
        [skinSlot addChild:debugSlot];
        
        skinSlot.currentAttachment = attachment; // this just sets the names of the attachments to use... nothing is actually attached at this time
        skinSlot.defaultAttachment = attachment;
        if (!color) {
            skinSlot.defaultColor = COLOR_VALUE_DEFAULT_RGBA;
            skinSlot.alpha = ALPHA_VALUE_DEFAULT;
        }else{
            skinSlot.defaultColor = [ColorValueHelper getRGBStringFromRGBAString:color];
            skinSlot.alpha = [AlphaValueHelper getAlphaValueFromColorString:color];
        }
        
        //Note: Slots are ordered in the setup pose draw order. Images in higher index slots are drawn on top of those in lower index slots
        skinSlot.zPosition = i * 0.01;
        skinSlot.defaultDrawOrder = skinSlot.zPosition;
        
        for (int b = 0; b < self.bones.count; b++) { //find bone for slot
            SGG_SpineBone* bone = (SGG_SpineBone*)[self.bones objectAtIndex:b];
            if ([bone.name isEqualToString:boneString]) {
                [bone addChild:skinSlot];
                break;
            }
        }
        
        [skinSlotsMutable addObject:skinSlot];
        
    }
    
    self.skinSlots = [NSArray arrayWithArray:skinSlotsMutable];
    
    
}

-(void)createSkinsFromDict:(NSDictionary*)skinsDict andAtlasNamed:(NSString*)atlasName{
    //pull in texture atlas
    SKTextureAtlas* atlas = [SKTextureAtlas atlasNamed:atlasName];
    
    //get all skins
    NSArray* skinKeys = [skinsDict allKeys];
    
    if  (self.debugMode) {
        NSLog(@"skinKeys: %@", skinKeys);
    }
    for (NSString* skinName in skinKeys) { //cycle through all the skin names in the JSON
        
        
        //get all skin slots
        NSDictionary* slotsFromSkin = [NSDictionary dictionaryWithDictionary:[skinsDict objectForKey:skinName]];
        NSArray* skinSlotNames = [slotsFromSkin allKeys];
        
        
        for (NSString* skinSlotName in skinSlotNames) {
            //get appropriate SkinSlot from public array
            SGG_SkinSlot* skinSlot;
            for (SGG_SkinSlot* skinSlotCycle in self.skinSlots) {
                if ([skinSlotCycle.name isEqualToString:skinSlotName]) {
                    skinSlot = skinSlotCycle;
                    break;
                }
            }
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
        if  (self.debugMode) {
            NSLog(@"longest duration in %@ is: %f",thisAnimationName, longestDuration);
        }
        
        NSDictionary* boneAnimationsDict = [NSDictionary dictionaryWithDictionary:[thisAnimationDict objectForKey:@"bones"]];
        for (int c = 0; c < self.bones.count; c++) {
            //cycle through individual bone SRT animations
            
            SGG_SpineBone* bone = (SGG_SpineBone*)[_bones objectAtIndex:c];
            NSDictionary* SRTtimelinesForBone = [boneAnimationsDict objectForKey:bone.name];
            
            
            //set up actions for bone
            NSArray* translations = [SRTtimelinesForBone objectForKey:@"translate"];
            NSArray* rotations = [SRTtimelinesForBone objectForKey:@"rotate"];
            NSArray* scales = [SRTtimelinesForBone objectForKey:@"scale"];
            SGG_SpineBoneAction* boneAction = [self createBoneTranslationActionsFromArray:translations andRotationsFromArray:rotations andScalesFromArray:scales forBone:bone andTotalLengthOfAnimation:longestDuration];
            
            
            [bone.animations setObject:boneAction forKey:thisAnimationName];
        }
        
        
        NSDictionary* slotsAnimationsDict = [NSDictionary dictionaryWithDictionary:[thisAnimationDict objectForKey:@"slots"]];
        NSArray* slotNames = [slotsAnimationsDict allKeys];
        NSArray* drawOrderArray = [NSArray arrayWithArray:[thisAnimationDict objectForKey:@"drawOrder"]];
        
        for (NSString* slotName in slotNames) {
            for (SGG_SkinSlot* skinSlot in self.skinSlots) {
                if ([skinSlot.name isEqualToString:slotName]) {
                    // matching names... do stuff here
                    NSDictionary* slotDict = [slotsAnimationsDict objectForKey:slotName];
                    
                    SGG_SpineBoneAction* slotAction = [self createSpineSlotActionsFromDictionary:slotDict forSkinSlot:skinSlot withDrawOrder:(NSArray*)drawOrderArray totalLengthOfAnimation:longestDuration andIntroPeriodOf:0];
                    
                    [skinSlot.animations setObject:slotAction forKey:thisAnimationName];
                    break;
                }
            }
        }
    }
}

-(void)addDrawOrderAnimationForSlot:(NSString*)slotName andSlotAction:(SGG_SpineBoneAction*)slotAction fromDrawOrder:(NSArray*)drawOrderArray{
    [drawOrderArray enumerateObjectsUsingBlock:^(NSDictionary *drawOrderDict, NSUInteger idx, BOOL * _Nonnull stop) {
        NSArray *offsets = [NSArray arrayWithArray:[drawOrderDict objectForKey:@"offsets"]];
        [offsets enumerateObjectsUsingBlock:^(NSDictionary*  offset, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *offsetSlotName = [offset objectForKey:@"slot"];
            if ([offsetSlotName isEqualToString:slotName]) {
                NSNumber *time = [drawOrderDict objectForKey:@"time"];
                NSNumber *offsetValue = [offset objectForKey:@"offset"];
                
                [slotAction addDrawOrderAnimationAtTime:time withOffset:offsetValue];
                *stop = YES;
            }
        }];
    }];
}

-(CGFloat)longestTimeInAnimations:(NSDictionary*)animation {
    CGFloat longestDuration = 0;
    
    NSDictionary* boneAnimationsDict = [NSDictionary dictionaryWithDictionary:[animation objectForKey:@"bones"]];
    for (int c = 0; c < self.bones.count; c++) {
        SGG_SpineBone* bone = (SGG_SpineBone*)[_bones objectAtIndex:c];
        NSDictionary* SRTtimelinesForBone = [boneAnimationsDict objectForKey:bone.name]; //does this work?!
        
        NSArray* rotations = [SRTtimelinesForBone objectForKey:@"rotate"];
        for (int d = 0; d < rotations.count; d++) {
            NSDictionary* rotation = [rotations objectAtIndex:d];
            CGFloat duration = [[rotation objectForKey:@"time"] doubleValue];
            //set up rotation actions here
            if (duration > longestDuration) {
                longestDuration = duration;
                if  (self.debugMode) {
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
                if  (self.debugMode) {
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
                if  (self.debugMode) {
                    NSLog(@"duration lengthened to: %f %@ translate", longestDuration, translate);
                }
            }
        }
    }
    
    NSDictionary* slotAnimationsDict = [NSDictionary dictionaryWithDictionary:[animation objectForKey:@"slots"]];
    NSArray* slotsWithAnimation = [slotAnimationsDict allKeys];
    NSDictionary *currentSlotAnimation;
    for (int c = 0; c < slotsWithAnimation.count; c++) {
        currentSlotAnimation = [slotAnimationsDict objectForKey:[slotsWithAnimation objectAtIndex:c]];
        
        //attachments and colors
        NSArray* attachmentArray = [NSArray arrayWithArray:[currentSlotAnimation objectForKey:@"attachment"] ];
        for (int d = 0; d < attachmentArray.count; d++) {
            NSDictionary* attachment = [attachmentArray objectAtIndex:d];
            CGFloat duration = [[attachment objectForKey:@"time"] doubleValue];
            //set up slot actions here
            if (duration > longestDuration) {
                longestDuration = duration;
                if  (self.debugMode) {
                    NSLog(@"duration lengthened to: %f %@ attachment", longestDuration, attachment);
                }
            }
        }
        
        NSArray* colorArray = [NSArray arrayWithArray:[currentSlotAnimation objectForKey:@"color"] ];
        for (int d = 0; d < colorArray.count; d++) {
            NSDictionary* color = [colorArray objectAtIndex:d];
            CGFloat duration = [[color objectForKey:@"time"] doubleValue];
            //set up color actions here
            if (duration > longestDuration) {
                longestDuration = duration;
                if  (self.debugMode) {
                    NSLog(@"duration lengthened to: %f %@ color", longestDuration, color);
                }
            }
        }
    }
    
    
    NSArray* drawOrderArray = [NSArray arrayWithArray:[animation objectForKey:@"drawOrder"]];
    for (int c = 0; c < drawOrderArray.count; c++) {
        NSDictionary* drawOrderInfo = [NSDictionary dictionaryWithDictionary:[drawOrderArray objectAtIndex:c]];
        CGFloat duration = [[drawOrderInfo objectForKey:@"time"] doubleValue];
        //set up draw order actions here
        if (duration > longestDuration) {
            longestDuration = duration;
            if  (self.debugMode) {
                NSLog(@"duration lengthened to: %f %@ draw order", longestDuration, drawOrderInfo);
            }
            
        }
    }
    
    
    
    return longestDuration;
}

-(void)createIntroAnimationIntoAnimation:(NSString*)animationName overDuration:(CGFloat)duration {
    //	NSLog(@"creating intro");
    
    NSDictionary* thisAnimationDict = self.rawAnimationDictionary[animationName];
    
    NSDictionary* boneAnimationsDict = [NSDictionary dictionaryWithDictionary:[thisAnimationDict objectForKey:@"bones"]];
    CGFloat longestDuration = duration;
    
    
    for (SGG_SpineBone* bone in self.bones) {
        
        
        NSDictionary* SRTtimelinesForBone = [boneAnimationsDict objectForKey:bone.name];
        
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
        startRotationModified -= bone.defaultRotation * SPINE_RADTODEGFACTOR;
        
        
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
        NSArray* newRot = [NSArray arrayWithObjects:startRotationDict, endRotationDict, nil];
        NSArray* newScale = [NSArray arrayWithObjects:startScaleDict, endScaleDict, nil];
        
        if (translations[0] || rotations[0] || scales[0]) {
            SGG_SpineBoneAction* boneAction = [self createBoneTranslationActionsFromArray:newTrans andRotationsFromArray:newRot andScalesFromArray:newScale forBone:bone andTotalLengthOfAnimation:longestDuration];
            
            [boneAction calculateBoneAction];
            
            [bone.animations setObject:boneAction forKey:@"INTRO_ANIMATION"];
            
            //			NSLog(@"made intro for %@: %i frames", bone.name, (int)boneAction.animation.count);
        }
        
        
    }
    
    
    
    //	NSLog(@"set intro");
    
}



-(SGG_SpineBoneAction*)createBoneTranslationActionsFromArray:(NSArray*)translations andRotationsFromArray:(NSArray*)rotations andScalesFromArray:(NSArray*)scales forBone:(SGG_SpineBone*)spineBone andTotalLengthOfAnimation:(const CGFloat)longestDuration {
    
    
    SGG_SpineBoneAction* boneAction = [[SGG_SpineBoneAction alloc] init];
    [boneAction setTotalLength:longestDuration];
    boneAction.timeFrameDelta = self.timeResolution;
    
    for (int d = 0; d < translations.count; d++) {
        NSDictionary* translation = [translations objectAtIndex:d];
        CGFloat x, y, time;
        id curveInfo;
        
        x = [[translation objectForKey:@"x"] floatValue];
        y = [[translation objectForKey:@"y"] floatValue];
        time = [[translation objectForKey:@"time"] floatValue];
        curveInfo = [translation objectForKey:@"curve"];
        
        [boneAction addTranslationAtTime:time withPoint:CGPointMake(x, y) andCurveInfo:curveInfo];
        
        
    }
    
    for (int d = 0; d < rotations.count; d++) {
        NSDictionary* rotation = [rotations objectAtIndex:d];
        CGFloat angle, time;
        id curveInfo;
        
        angle = [[rotation objectForKey:@"angle"] floatValue];
        curveInfo = [rotation objectForKey:@"curve"];
        time = [[rotation objectForKey:@"time"] floatValue];
        
        [boneAction addRotationAtTime:time withAngle:angle andCurveInfo:curveInfo];
    }
    
    for (int d = 0; d < scales.count; d++) {
        NSDictionary* scale = [scales objectAtIndex:d];
        CGFloat x, y, time;
        id curveInfo;
        
        if ([scale objectForKey:@"x"]) {
            x = [[scale objectForKey:@"x"] floatValue];
        } else {
            x = 1;
        }
        
        if ([scale objectForKey:@"y"]) {
            y = [[scale objectForKey:@"y"] floatValue];
        } else {
            y = 1;
        }
        
        curveInfo = [scale objectForKey:@"curve"];
        time = [[scale objectForKey:@"time"] floatValue];
        
        [boneAction addScaleAtTime:time withScale:CGSizeMake(x, y) andCurveInfo:curveInfo];
    }
    
    [boneAction calculateBoneAction];
    
    return boneAction;
}

-(SGG_SpineBoneAction*)createSpineSlotActionsFromDictionary:(NSDictionary*)slotDict  forSkinSlot:(SGG_SkinSlot*)skinSlot withDrawOrder:(NSArray*)drawOrderArray totalLengthOfAnimation:(const CGFloat)longestDuration andIntroPeriodOf:(const CGFloat)intro {
    SGG_SpineBoneAction* slotAction = [[SGG_SpineBoneAction alloc] init];
    [slotAction setTotalLength:longestDuration];
    slotAction.timeFrameDelta = self.timeResolution;
    
    NSArray* attachmentArray = slotDict[@"attachment"];
    NSArray* colorArray = slotDict[@"color"];
    
    for (NSDictionary* keyFrameDict in attachmentArray) {
        CGFloat time = [keyFrameDict[@"time"] floatValue];
        NSString* name = keyFrameDict[@"name"];
        if ([name isKindOfClass:[NSNull class]]) {
            name = ATTACHMENT_NAME_EMPTY;
        }
        [slotAction addAttachmentAnimationAtTime:time withAttachmentName:name];
    }
    
    if (!colorArray) {
        //map color and alpha value from initial state for displaying in animation frames correctly
        CGFloat time = TIME_VALUE_ZERO;
        [slotAction addColorAnimationAtTime:time withColor:skinSlot.defaultColor];
    }else{
        for (NSDictionary* keyFrameDict in colorArray) {
            CGFloat time = [keyFrameDict[@"time"] floatValue];
            NSString* color = keyFrameDict[@"color"];
            [slotAction addColorAnimationAtTime:time withColor:color];
        }
    }
    
    [self addDrawOrderAnimationForSlot:skinSlot.name andSlotAction:slotAction fromDrawOrder:drawOrderArray];
    
    [slotAction calculateSlotActionForSkinSlot:skinSlot];
    
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

-(void)setPlaybackSpeed:(CGFloat)playbackSpeed {
    
    
    
    if (playbackSpeed < 0) {
        playbackSpeed = 0;
    }
    
    _playbackSpeed = playbackSpeed;
    
    //	feeble attempt to get the animation to not jump when ramping the speed (doesn't quite work 100%)
    CFTimeInterval time = CFAbsoluteTimeGetCurrent();
    
    double timeElapsed = time - animationStartTime;
    
    CFTimeInterval timeFix = timeElapsed * ( 1.0f / self.playbackSpeed);
    
    animationStartTime = time - timeFix;
    
    
}



@end
