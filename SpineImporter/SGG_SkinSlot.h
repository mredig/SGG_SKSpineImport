//
//  SGG_SkinSlot.h
//  SpineTesting
//
//  Created by Michael Redig on 2/10/14.
//  Copyright (c) 2014 Secret Game Group LLC. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface SGG_SkinSlot : SKSpriteNode


@property (nonatomic, assign) NSString* currentAttachment;

@property (nonatomic, assign) NSString* defaultAttachment;


@property (nonatomic, assign) NSString* currentSkin;
@property (nonatomic, strong) NSMutableDictionary* skins;


@property (nonatomic, strong) NSMutableDictionary* animations;
@property (nonatomic, strong) NSArray* currentAnimation;


-(NSInteger)playAnimations:(NSArray*)animationNames;
-(bool)updateAnimationAtFrame:(NSInteger)currentFrame;
-(void)stopAnimation;

-(void)setAttachmentTo:(NSString*)attachmentName;
-(void)setToDefaultAttachment;


-(void)changeSkinTo:(NSString*)skin;

@end
