//
//  SGG_SkinSlot.h
//  SpineTesting
//
//  Created by Michael Redig on 2/10/14.
//  Copyright (c) 2014 Secret Game Group LLC. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface SGG_SkinSlot : SKNode


@property (nonatomic, assign) NSString* currentAttachment;

@property (nonatomic, assign) NSString* defaultAttachment;

@property (nonatomic, strong) NSMutableDictionary* animations;
@property (nonatomic, strong) NSArray* currentAnimation;


-(void)playAnimations:(NSArray*)animationNames;
-(void)updateAnimationAtFrame:(NSInteger)currentFrame;


-(void)setAttachmentTo:(NSString*)attachmentName;
-(void)setToDefaultAttachment;


@end
