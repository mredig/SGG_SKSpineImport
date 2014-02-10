//
//  SGG_SkinSprite.h
//  SpineTesting
//
//  Created by Michael Redig on 2/10/14.
//  Copyright (c) 2014 Secret Game Group LLC. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

typedef enum {
	kSGG_SkinSpritePlaybackTypeForward,
	kSGG_SkinSpritePlaybackTypeBackward,
	kSGG_SkinSpritePlaybackTypeForwardLoop,
	kSGG_SkinSpritePlaybackTypeBackwardLoop,
	kSGG_SkinSpritePlaybackTypePingPong,
	kSGG_SkinSpritePlaybackTypeRandom
} kSGG_SkinSpritePlaybackType;

@interface SGG_SkinSprite : SKSpriteNode

@property (nonatomic, assign) CGPoint defaultPosition;
@property (nonatomic, assign) CGFloat defaultScaleX;
@property (nonatomic, assign) CGFloat defaultScaleY;
@property (nonatomic, assign) CGFloat defaultRotation;
@property (nonatomic, assign) CGSize defaultSize;
@property (nonatomic, assign) CGSize defaultFPS; //not implemented
@property (nonatomic, assign) kSGG_SkinSpritePlaybackType defaultPlaybackMode; //not implemented
@property (nonatomic, assign) CGRect defaultBoundingBox; //not implemented


@property (nonatomic, assign) CGSize sizeFromJSON;
@property (nonatomic, assign) NSString* actualAttachmentName;


-(void)setDefaults;
-(void)setToDefaults;


@end
