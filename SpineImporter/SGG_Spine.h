//
//  SGG_Spine.h
//  SpineTesting
//
//  Created by Michael Redig on 2/10/14.
//  Copyright (c) 2014 Secret Game Group LLC. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import "SpineImport.h"
#import "SGG_SpineBone.h"

typedef enum {
	kSGG_SpineAnimationTypeBone,
	kSGG_SpineAnimationTypeDrawOrder,
	kSGG_SpineAnimationTypeSlots
} kSGG_SpineAnimationType;

@interface SGG_Spine : SKNode

@property (nonatomic, assign) BOOL debugMode;


@property (nonatomic, readonly) BOOL isRunningAnimation;
@property (nonatomic, strong, readonly) NSMutableArray* currentAnimationSequence;
@property (nonatomic, readonly) NSString* currentAnimation;
@property (nonatomic, readonly) NSInteger animationCount;

@property (nonatomic, assign) NSString* queuedAnimation;
@property (nonatomic, assign) CGFloat queueIntro;
@property (nonatomic) bool useQueue;
@property (nonatomic) CGFloat timeResolution; //defaults to 1/120 for smooth playback at 60 fps. If you are planning to have slower motion or ramp, you should increase the resolution (lower values are higher resolution). At 1/120, you will start noticing stutters at speeds lower than 0.5x.
@property (nonatomic) CGFloat playbackSpeed;


@property (nonatomic, strong) NSMutableDictionary* swappedTextures;
@property (nonatomic, strong) NSMutableArray* colorizedNodes;


@property (nonatomic, strong) NSArray* bones;
@property (nonatomic, strong) NSArray* skinSlots; //active slots in animation
@property (nonatomic, assign) NSString* currentSkin; //name of current skin
@property (nonatomic, readonly) NSInteger currentFrame;


@property (nonatomic, strong) NSArray* slotsArray; //raw array from json
@property (nonatomic, strong) NSDictionary* rawAnimationDictionary; //raw information from JSON

-(void)skeletonFromFileNamed:(NSString*)name andUseSkinNamed:(NSString*)skinName;
-(void)skeletonFromFileNamed:(NSString*)name andAtlasNamed:(NSString*)atlasName andUseSkinNamed:(NSString*)skinName;

-(void)runAnimation:(NSString*)animationName andCount:(NSInteger)count withIntroPeriodOf:(const CGFloat)introPeriod andUseQueue:(BOOL)useQueue;
-(void)runAnimation:(NSString*)animationName andCount:(NSInteger)count;
-(void)runAnimationSequence:(NSArray *)animationNames andUseQueue:(BOOL)useQueue;
-(void)stopAnimation;
-(void)jumpToFrame:(NSInteger)frame;
-(void)jumpToNextFrame;
-(void)jumpToPreviousFrame;
-(void)activateAnimations;


-(void)resetSkeleton;

-(void)changeSkinTo:(NSString*)skin;

-(void)changeSkinPartial:(NSDictionary *)slotsToReplace;
-(void)resetSkinPartial;

-(void)changeTexturePartial:(NSDictionary *)attachmentsToReplace;
-(void)resetTexturePartial;

-(void)colorizeAllSlotsWithColor:(SKColor *)color andIntensity:(CGFloat)blendFactor;
-(void)colorizeSlots:(NSArray *)slotsToColorize withColor:(SKColor *)color andIntensity:(CGFloat)blendFactor;
-(void)resetColorizedSlots;

-(SGG_SpineBone*)findBoneNamed:(NSString*)boneName;




@end
