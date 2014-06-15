//
//  SGG_SpineBone.h
//  SpineTesting
//
//  Created by Michael Redig on 2/10/14.
//  Copyright (c) 2014 Secret Game Group LLC. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import "SGG_SpineBoneAction.h"

@interface SGG_SpineBone : SKNode

@property (nonatomic, assign) CGFloat length;
@property (nonatomic, assign) CGPoint defaultPosition;
@property (nonatomic, assign) CGFloat defaultScaleX;
@property (nonatomic, assign) CGFloat defaultScaleY;
@property (nonatomic, assign) CGFloat defaultRotation;
@property (nonatomic, assign) CGPoint basePosition;
@property (nonatomic, assign) CGFloat baseScaleX;
@property (nonatomic, assign) CGFloat baseScaleY;
@property (nonatomic, assign) CGFloat baseRotation;

@property (nonatomic, strong) NSMutableDictionary* animations;
@property (nonatomic, strong) NSArray* currentAnimation;




-(void)debugWithLength;

-(void)setDefaultsAndBase;
-(void)setToDefaults;
-(void)playAnimations:(NSArray*)animationNames;
-(void)updateAnimationAtFrame:(NSInteger)currentFrame;
@end
