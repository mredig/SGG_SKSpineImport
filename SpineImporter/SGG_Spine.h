//
//  SGG_Spine.h
//  SpineTesting
//
//  Created by Michael Redig on 2/10/14.
//  Copyright (c) 2014 Secret Game Group LLC. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import "SpineImport.h"

typedef enum {
	kSGG_SpineAnimationTypeBone,
	kSGG_SpineAnimationTypeDrawOrder,
	kSGG_SpineAnimationTypeSlots
} kSGG_SpineAnimationType;

@interface SGG_Spine : SKNode

@property (nonatomic, assign) BOOL debugMode;


@property (nonatomic, readonly) BOOL isRunningAnimation;
@property (nonatomic, strong) NSArray* currentAnimationSequence; //currently only supports one animation at a time, but is an array for future compatibilty with a sequence

@property (nonatomic, assign) NSString* queuedAnimation;
@property (nonatomic, assign) CGFloat queueIntro;
@property (nonatomic, assign) NSInteger queueCount;





@property (nonatomic, strong) NSArray* bones;
@property (nonatomic, strong) NSMutableDictionary* skins;
@property (nonatomic, strong) NSMutableDictionary* animations;
@property (nonatomic, strong) NSArray* currentSkinSlots;
@property (nonatomic, assign) NSString* currentSkin;


@property (nonatomic, strong) NSArray* slotsArray;
@property (nonatomic, strong) NSDictionary* rawAnimationDictionary;

-(void)skeletonFromFileNamed:(NSString*)name andAtlasNamed:(NSString*)atlasName andUseSkinNamed:(NSString*)skinName;
-(void)stopAnimation;
-(void)resetSkeleton;
-(void)changeSkinTo:(NSString*)skin;
-(void)runAnimation:(NSString*)animationName andCount:(NSInteger)count;
-(void)runAnimation:(NSString*)animationName andCount:(NSInteger)count withSpeedFactor:(CGFloat)speedfactor withIntroPeriodOf:(const CGFloat)introPeriod andUseQueue:(BOOL)useQueue;//speedfactor currently has no effect




@end
