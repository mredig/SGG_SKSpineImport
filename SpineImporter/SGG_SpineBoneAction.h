//
//  SGG_SpineBoneAction.h
//  SGG_SKSpineImport
//
//  Created by Michael Redig on 6/2/14.
//  Copyright (c) 2014 Secret Game Group LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SpriteKit/SpriteKit.h>

#import "SGG_SkinSlot.h"

@class SGG_SpineBone;

@interface SGG_SpineBoneAction : NSObject

@property (nonatomic) CGFloat totalLength;
@property (nonatomic) CGFloat timeFrameDelta;

@property (strong, readonly) NSArray* animation;

-(void)addTranslationAtTime:(CGFloat)time withPoint:(CGPoint)point andCurveInfo:(id)curve;
-(void)addRotationAtTime:(CGFloat)time withAngle:(CGFloat)angle andCurveInfo:(id)curve;
-(void)addScaleAtTime:(CGFloat)time withScale:(CGSize)scale andCurveInfo:(id)curve;

-(void)addAttachmentAnimationAtTime:(CGFloat)time withAttachmentName:(NSString*)attachmentName;
-(void)addColorAnimationAtTime:(CGFloat)time withColor:(NSString*)colorInString;
-(void)addDrawOrderAnimationAtTime:(NSNumber*)time withOffset:(NSNumber*)offset;

-(void)calculateBoneAction;
-(void)calculateSlotActionForSkinSlot:(SGG_SkinSlot*)skinSlot;
@end
