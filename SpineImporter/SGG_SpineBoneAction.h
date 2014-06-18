//
//  SGG_SpineBoneAction.h
//  SGG_SKSpineImport
//
//  Created by Michael Redig on 6/2/14.
//  Copyright (c) 2014 Secret Game Group LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SpriteKit/SpriteKit.h>

@interface SGG_SpineBoneAction : NSObject

@property (nonatomic) CGFloat totalLength; //currently does not account for slot animations
@property (nonatomic) CGFloat timeFrameDelta;

@property (strong, readonly) NSArray* animation;

-(void)addTranslationAtTime:(CGFloat)time withPoint:(CGPoint)point andCurveInfo:(id)curve;
-(void)addRotationAtTime:(CGFloat)time withAngle:(CGFloat)angle andCurveInfo:(id)curve;
-(void)addScaleAtTime:(CGFloat)time withScale:(CGSize)scale andCurveInfo:(id)curve;

-(void)addAttachmentAnimationAtTime:(CGFloat)time withAttachmentName:(NSString*)attachmentName;
-(void)addColorAnimationAtTime:(CGFloat)time withColor:(NSString*)colorInString; //not supported atm

-(void)calculateTotalAction;
-(void)calculateSlotAction;
@end
