//
//  SGG_SpineBoneAction.m
//  SGG_SKSpineImport
//
//  Created by Michael Redig on 6/2/14.
//  Copyright (c) 2014 Secret Game Group LLC. All rights reserved.
//

#import "SGG_SpineBoneAction.h"

#import "AlphaValueHelper.h"
#import "ColorValueHelper.h"
#import "SGG_SpineBone.h"
#import "SpineImport.h"

@interface SGG_SpineBoneAction () {
    
    NSMutableArray* translationInput;
    NSMutableArray* rotationInput;
    NSMutableArray* scaleInput;
    NSMutableArray* attachmentInput;
    NSMutableArray* colorInput;
    NSMutableArray* drawOrderInput;
}

@end


@implementation SGG_SpineBoneAction

-(id)init {
    if (self = [super init]) {
        
    }
    return self;
}

#pragma mark INPUT DATA

-(void)addTranslationAtTime:(CGFloat)time withPoint:(CGPoint)point andCurveInfo:(id)curve {
    if (!translationInput) {
        translationInput = [[NSMutableArray alloc] init];
    }
    
    if (time > self.totalLength) {
        self.totalLength = time;
    }
    
    NSNumber* timeObject = [NSNumber numberWithDouble:time];
    NSValue* pointObject = [self valueObjectFromPoint:point];
    NSDictionary* translationKeyframe;
    if (curve) {
        translationKeyframe = [NSDictionary dictionaryWithObjects:@[timeObject, pointObject, curve] forKeys:@[@"time", @"point", @"curve"]];
    } else {
        translationKeyframe = [NSDictionary dictionaryWithObjects:@[timeObject, pointObject] forKeys:@[@"time", @"point"]];
    }
    [translationInput addObject:translationKeyframe];
    
}

-(void)addRotationAtTime:(CGFloat)time withAngle:(CGFloat)angle andCurveInfo:(id)curve {
    if (!rotationInput) {
        rotationInput = [[NSMutableArray alloc] init];
    }
    
    if (time > self.totalLength) {
        self.totalLength = time;
    }
    
    while (angle > 360) {
        angle -= 360;
    }
    
    while (angle < 0) {
        angle += 360;
    }
    
    angle *= (M_PI / 180);
    
    NSNumber* timeObject = [NSNumber numberWithDouble:time];
    NSNumber* angleObject = [NSNumber numberWithDouble:angle];
    NSDictionary* rotationKeyFrame;
    if (curve) {
        rotationKeyFrame = [NSDictionary dictionaryWithObjects:@[timeObject, angleObject, curve] forKeys:@[@"time", @"angle", @"curve"]];
    } else {
        rotationKeyFrame = [NSDictionary dictionaryWithObjects:@[timeObject, angleObject] forKeys:@[@"time", @"angle"]];
    }
    [rotationInput addObject:rotationKeyFrame];
    
    //	NSLog(@"%@", rotationInput);
}

-(void)addScaleAtTime:(CGFloat)time withScale:(CGSize)scale andCurveInfo:(id)curve {
    if (!scaleInput) {
        scaleInput = [[NSMutableArray alloc] init];
    }
    
    NSNumber* timeObject = [NSNumber numberWithDouble:time];
    NSValue* scaleObject = [self valueObjectFromPoint:CGPointMake(scale.width, scale.height)];
    NSDictionary* translationKeyframe;
    if (curve) {
        translationKeyframe = [NSDictionary dictionaryWithObjects:@[timeObject, scaleObject, curve] forKeys:@[@"time", @"scale", @"curve"]];
    } else {
        translationKeyframe = [NSDictionary dictionaryWithObjects:@[timeObject, scaleObject] forKeys:@[@"time", @"scale"]];
    }
    [scaleInput addObject:translationKeyframe];
    
}

-(void)addAttachmentAnimationAtTime:(CGFloat)time withAttachmentName:(NSString*)attachmentName {
    
    if (!attachmentInput) {
        attachmentInput= [[NSMutableArray alloc] init];
    }
    
    NSNumber* timeObject = [NSNumber numberWithFloat:time];
    NSDictionary* attachmentKeyframe = [NSDictionary dictionaryWithObjects:@[timeObject, attachmentName] forKeys:@[@"time", @"attachmentName"]];
    
    [attachmentInput addObject:attachmentKeyframe];
}

-(void)addColorAnimationAtTime:(CGFloat)time withColor:(NSString*)colorInString {
    if (!colorInput) {
        colorInput = [[NSMutableArray alloc] init];
    }
    
    //Note: 4 two digit hex numbers in RGBA order. Assume "FF" for alpha if alpha is omitted. Assume "FFFFFFFF" if omitted.
    NSNumber* timeObject = [NSNumber numberWithFloat:time];
    NSString *rgbColor = [ColorValueHelper getRGBStringFromRGBAString:colorInString];
    NSNumber *alphaValue = [NSNumber numberWithFloat:[AlphaValueHelper getAlphaValueFromColorString:colorInString]];
    
    NSDictionary *colorKeyFrame = [NSDictionary dictionaryWithObjects:@[timeObject, rgbColor, alphaValue] forKeys:@[@"time", @"color", @"alpha"]];
    
    [colorInput addObject:colorKeyFrame];
}

-(void)addDrawOrderAnimationAtTime:(NSNumber*)time withOffset:(NSNumber*)offset {
    if (!drawOrderInput) {
        drawOrderInput = [NSMutableArray new];
    }
    
    NSDictionary *drawOrderKeyFrame = [NSDictionary dictionaryWithObjects:@[time, offset] forKeys:@[@"time", @"offset"]];
    
    [drawOrderInput addObject:drawOrderKeyFrame];
}

#pragma mark RENDER DATA

-(void)calculateBoneAction {
    
    if (self.timeFrameDelta == 0) {
        self.timeFrameDelta = TIME_FRAME_DELTA_DEFAULT;
    }
    NSInteger totalFrames = round(_totalLength / _timeFrameDelta);
    //	NSLog(@"total time: %f, delta: %f totalFrames = %i", _totalLength, _timeFrameDelta, (int)totalFrames);
    
    NSMutableArray* mutableAnimation = [[NSMutableArray alloc] initWithCapacity:totalFrames];
    
    [self calculateTranslationKeyframesInTotalAnimation:mutableAnimation];
    [self calculateRotationKeyframesInTotalAnimation:mutableAnimation];
    [self calculateScaleKeyframesInTotalAnimation:mutableAnimation];
    
    _animation = [NSArray arrayWithArray:mutableAnimation];
}

-(void)calculateSlotActionForSkinSlot:(SGG_SkinSlot*)skinSlot {
    
    if (self.timeFrameDelta == 0) {
        self.timeFrameDelta = TIME_FRAME_DELTA_DEFAULT;
    }
    NSInteger totalFrames = round(_totalLength / _timeFrameDelta);
    NSMutableArray* mutableAnimation = [[NSMutableArray alloc] initWithCapacity:totalFrames];
    
    [self calculateSlotKeyAttachmentFramesInTotalAnimation:mutableAnimation forSkinSlot:skinSlot];
    [self calculateSlotKeyColorAndAlphaFramesInTotalAnimation:mutableAnimation forSkinSlot:skinSlot];
    [self calculateSlotKeyDrawOrderFramesInTotalAnimation:mutableAnimation forSkinSlot:skinSlot];
    
    _animation = [NSArray arrayWithArray:mutableAnimation];
}

-(void)calculateTranslationKeyframesInTotalAnimation:(NSMutableArray*)mutableAnimation{
    NSInteger frameCounter = 0;
    NSDictionary* startKeyFrameDict = [translationInput firstObject];
    
    if ([startKeyFrameDict[@"time"] floatValue] != TIME_VALUE_ZERO) {
        NSValue* pointObject = [self valueObjectFromPoint:CGPointMake(TRANSLATION_VALUE_DEFAULT, TRANSLATION_VALUE_DEFAULT)];
        
        NSDictionary* translationKeyframe = [NSDictionary dictionaryWithObjects:@[[NSNumber numberWithFloat:TIME_VALUE_ZERO], pointObject] forKeys:@[@"time", @"point"]];
        [translationInput insertObject:translationKeyframe atIndex:0];
    }
    
    //translation keyframes
    for (int i = 0; i < translationInput.count; i++) {
        startKeyFrameDict = translationInput[i];
        NSDictionary* endKeyFrameDict = [self getEndKeyframeDictionaryFromArray:translationInput atIndex:i];
        
        CGFloat startingTime = [startKeyFrameDict[@"time"] doubleValue];
        CGPoint startingLocation = [self pointFromValueObject:startKeyFrameDict[@"point"]];
        id curveInfo = startKeyFrameDict[@"curve"];
        
        CGFloat endingTime = [self getEndingTimeFromDictionary:endKeyFrameDict withInputArray:translationInput atIndex:i];
        CGPoint endingLocation = [self pointFromValueObject:endKeyFrameDict[@"point"]];
        
        NSInteger keyFramesInSequence = [self getKeyFramesInSequenceForStartingTime:startingTime andEndingTime:endingTime];
        
        if (curveInfo) {
            NSString* curveString = (NSString*)curveInfo;
            if ([curveInfo isKindOfClass:[NSString class]] && [curveString isEqualToString:@"stepped"]) {
                //stepped
                for (int f = 0; f < keyFramesInSequence; f++) {
                    NSMutableDictionary* frameDict = [self getFrameDictionaryFromAnimation:mutableAnimation withFrameCounter:frameCounter andKeyFramesInSequence:keyFramesInSequence];
                    [frameDict setObject:[self valueObjectFromPoint:CGPointMake(startingLocation.x, startingLocation.y)] forKey:@"position"];
                    frameCounter++;
                }
            } else {
                //timing curve
                NSArray* curveArray = [NSArray arrayWithArray:curveInfo];
                CGPoint curvePointOne, curvePointTwo, curvePointThree, curvePointFour;
                curvePointOne = CGPointZero;
                curvePointTwo = CGPointMake([curveArray[0] doubleValue], [curveArray[1] doubleValue]);
                curvePointThree = CGPointMake([curveArray[2] doubleValue], [curveArray[3] doubleValue]);
                curvePointFour = CGPointMake(1.0f, 1.0f);
                
                CGFloat totalDeltaX = endingLocation.x - startingLocation.x;
                CGFloat totalDeltaY = endingLocation.y - startingLocation.y;
                
                for (int f = 0; f < keyFramesInSequence; f++) {
                    NSMutableDictionary* frameDict = [self getFrameDictionaryFromAnimation:mutableAnimation withFrameCounter:frameCounter andKeyFramesInSequence:keyFramesInSequence];
                    CGFloat timeProgress = ((CGFloat)f / (CGFloat)keyFramesInSequence);
                    CGFloat bezierProgress = [self getBezierPercentAtXValue:timeProgress withXValuesFromPoint0:curvePointOne.x point1:curvePointTwo.x point2:curvePointThree.x andPoint3:curvePointFour.x];
                    
                    CGPoint bezValues = [self calculateBezierPoint:bezierProgress andPoint0:curvePointOne andPoint1:curvePointTwo andPoint2:curvePointThree andPoint3:curvePointFour];
                    
                    [frameDict setObject:[self valueObjectFromPoint:CGPointMake(startingLocation.x + totalDeltaX * bezValues.y, startingLocation.y + totalDeltaY * bezValues.y)] forKey:@"position"];
                    frameCounter++;
                }
            }
        } else {
            //linear
            CGFloat deltaX = (endingLocation.x - startingLocation.x) / (keyFramesInSequence);
            CGFloat deltaY = (endingLocation.y - startingLocation.y) / (keyFramesInSequence);
            for (int f = 0; f < keyFramesInSequence; f++) {
                NSMutableDictionary* frameDict = [self getFrameDictionaryFromAnimation:mutableAnimation withFrameCounter:frameCounter andKeyFramesInSequence:keyFramesInSequence];
                [frameDict setObject:[self valueObjectFromPoint:CGPointMake(startingLocation.x + f * deltaX, startingLocation.y + f * deltaY)] forKey:@"position"];
                frameCounter++;
            }
        }
    }
}

-(void)calculateRotationKeyframesInTotalAnimation:(NSMutableArray*)mutableAnimation{
    NSInteger frameCounter = 0;
    NSDictionary* startKeyFrameDict = [rotationInput firstObject];
    
    if ([startKeyFrameDict[@"time"] floatValue] != TIME_VALUE_ZERO) {
        NSDictionary* rotationKeyframe = [NSDictionary dictionaryWithObjects:@[[NSNumber numberWithFloat:TIME_VALUE_ZERO], [NSNumber numberWithFloat:ROTATION_VALUE_DEFAULT]] forKeys:@[@"time", @"rotation"]];
        
        [rotationInput insertObject:rotationKeyframe atIndex:0];
    }
    
    for (int i = 0; i < rotationInput.count; i++) {
        startKeyFrameDict = rotationInput[i];
        NSDictionary* endKeyFrameDict = [self getEndKeyframeDictionaryFromArray:rotationInput atIndex:i];
        
        CGFloat startingTime = [startKeyFrameDict[@"time"] doubleValue];
        CGFloat startingAngle = [startKeyFrameDict[@"angle"] doubleValue];
        id curveInfo = startKeyFrameDict[@"curve"];
        
        CGFloat endingTime = [self getEndingTimeFromDictionary:endKeyFrameDict withInputArray:rotationInput atIndex:i];
        CGFloat endingAngle = [endKeyFrameDict[@"angle"] doubleValue];
        
        NSInteger keyFramesInSequence = [self getKeyFramesInSequenceForStartingTime:startingTime andEndingTime:endingTime];
        
        if (curveInfo) {
            NSString* curveString = (NSString*)curveInfo;
            if ([curveInfo isKindOfClass:[NSString class]] && [curveString isEqualToString:@"stepped"]) {
                //stepped
                for (int f = 0; f < keyFramesInSequence; f++) {
                    NSMutableDictionary* frameDict = [self getFrameDictionaryFromAnimation:mutableAnimation withFrameCounter:frameCounter andKeyFramesInSequence:keyFramesInSequence];
                    
                    [frameDict setObject:[NSNumber numberWithDouble:startingAngle] forKey:@"rotation"];
                    frameCounter ++;
                }
            } else {
                //timing curve
                CGFloat twoPi = 2 * M_PI;
                CGFloat totalDelta = endingAngle - startingAngle;
                totalDelta = fmod((totalDelta + M_PI), (2 * M_PI)) - M_PI;
                
                if (startingAngle > M_PI && endingAngle < (startingAngle - M_PI)) {
                    endingAngle += twoPi;
                    totalDelta = endingAngle - startingAngle;
                }
                
                NSArray* curveArray = [NSArray arrayWithArray:curveInfo];
                CGPoint curvePointOne, curvePointTwo, curvePointThree, curvePointFour;
                curvePointOne = CGPointZero;
                curvePointTwo = CGPointMake([curveArray[0] doubleValue], [curveArray[1] doubleValue]);
                curvePointThree = CGPointMake([curveArray[2] doubleValue], [curveArray[3] doubleValue]);
                curvePointFour = CGPointMake(1.0f, 1.0f);
                
                for (int f = 0; f < keyFramesInSequence; f++) {
                    NSMutableDictionary* frameDict = [self getFrameDictionaryFromAnimation:mutableAnimation withFrameCounter:frameCounter andKeyFramesInSequence:keyFramesInSequence];
                    
                    CGFloat timeProgress = ((CGFloat)f / (CGFloat)keyFramesInSequence);
                    CGFloat bezierProgress = [self getBezierPercentAtXValue:timeProgress withXValuesFromPoint0:curvePointOne.x point1:curvePointTwo.x point2:curvePointThree.x andPoint3:curvePointFour.x];
                    
                    CGPoint bezValues = [self calculateBezierPoint:bezierProgress andPoint0:curvePointOne andPoint1:curvePointTwo andPoint2:curvePointThree andPoint3:curvePointFour];
                    
                    CGFloat deltaRotation = totalDelta * bezValues.y;
                    
                    [frameDict setObject:[NSNumber numberWithDouble:startingAngle + deltaRotation] forKey:@"rotation"];
                    frameCounter ++;
                }
            }
        } else {
            //linear
            CGFloat twoPi = 2 * M_PI;
            
            CGFloat totalDelta = endingAngle - startingAngle;
            
            totalDelta = fmod((totalDelta + M_PI), (2 * M_PI)) - M_PI;
            
            if (startingAngle > M_PI && endingAngle < (startingAngle - M_PI)) {
                endingAngle += twoPi;
                totalDelta = endingAngle - startingAngle;
            }
            
            CGFloat deltaRotation = totalDelta / keyFramesInSequence;
            
            for (int f = 0; f < keyFramesInSequence; f++) {
                NSMutableDictionary* frameDict = [self getFrameDictionaryFromAnimation:mutableAnimation withFrameCounter:frameCounter andKeyFramesInSequence:keyFramesInSequence];
                
                [frameDict setObject:[NSNumber numberWithDouble:startingAngle + deltaRotation * f] forKey:@"rotation"];
                frameCounter ++;
            }
        }
    }
}

-(void)calculateScaleKeyframesInTotalAnimation:(NSMutableArray*)mutableAnimation{
    NSInteger frameCounter = 0;
    NSDictionary* startKeyFrameDict = [scaleInput firstObject];
    
    if ([startKeyFrameDict[@"time"] floatValue] != TIME_VALUE_ZERO) {
        NSValue *scaleObject = [self valueObjectFromPoint:CGPointMake(SCALE_VALUE_DEFAULT, SCALE_VALUE_DEFAULT)];
        
        NSDictionary* scaleKeyframe = [NSDictionary dictionaryWithObjects:@[[NSNumber numberWithFloat:TIME_VALUE_ZERO], scaleObject] forKeys:@[@"time", @"scale"]];
        [scaleInput insertObject:scaleKeyframe atIndex:0];
    }
    
    for (int i = 0; i < scaleInput.count; i++) {
        NSDictionary* startKeyFrameDict = scaleInput[i];
        NSDictionary* endKeyFrameDict = [self getEndKeyframeDictionaryFromArray:scaleInput atIndex:i];
        
        CGFloat startingTime = [startKeyFrameDict[@"time"] doubleValue];
        CGPoint startingSize = [self pointFromValueObject:startKeyFrameDict[@"scale"]];
        id curveInfo = startKeyFrameDict[@"curve"];
        
        CGFloat endingTime = [self getEndingTimeFromDictionary:endKeyFrameDict withInputArray:scaleInput atIndex:i];
        CGPoint endingSize = [self pointFromValueObject:endKeyFrameDict[@"scale"]];
        
        NSInteger keyFramesInSequence = [self getKeyFramesInSequenceForStartingTime:startingTime andEndingTime:endingTime];
        
        if (curveInfo) {
            NSString* curveString = (NSString*)curveInfo;
            if ([curveInfo isKindOfClass:[NSString class]] && [curveString isEqualToString:@"stepped"]) {
                //stepped
                
                for (int f = 0; f < keyFramesInSequence; f++) {
                    NSMutableDictionary* frameDict = [self getFrameDictionaryFromAnimation:mutableAnimation withFrameCounter:frameCounter andKeyFramesInSequence:keyFramesInSequence];
                    
                    NSValue* newScale = [self valueObjectFromPoint:startingSize];
                    
                    [frameDict setObject:newScale forKey:@"scale"];
                    frameCounter ++;
                }
            } else {
                //timing curve
                
                CGFloat totalDeltaWidth = endingSize.x - startingSize.x;
                CGFloat totalDeltaHeight = endingSize.y - startingSize.y;
                
                
                NSArray* curveArray = [NSArray arrayWithArray:curveInfo];
                CGPoint curvePointOne, curvePointTwo, curvePointThree, curvePointFour;
                curvePointOne = CGPointZero;
                curvePointTwo = CGPointMake([curveArray[0] doubleValue], [curveArray[1] doubleValue]);
                curvePointThree = CGPointMake([curveArray[2] doubleValue], [curveArray[3] doubleValue]);
                curvePointFour = CGPointMake(1.0f, 1.0f);
                
                
                for (int f = 0; f < keyFramesInSequence; f++) {
                    NSMutableDictionary* frameDict = [self getFrameDictionaryFromAnimation:mutableAnimation withFrameCounter:frameCounter andKeyFramesInSequence:keyFramesInSequence];
                    
                    CGFloat timeProgress = ((CGFloat)f / (CGFloat)keyFramesInSequence);
                    CGFloat bezierProgress = [self getBezierPercentAtXValue:timeProgress withXValuesFromPoint0:curvePointOne.x point1:curvePointTwo.x point2:curvePointThree.x andPoint3:curvePointFour.x];
                    
                    CGPoint bezValues = [self calculateBezierPoint:bezierProgress andPoint0:curvePointOne andPoint1:curvePointTwo andPoint2:curvePointThree andPoint3:curvePointFour];
                    
                    CGPoint newScalePoint = CGPointMake((startingSize.x + totalDeltaWidth * bezValues.y), (startingSize.y + totalDeltaHeight * bezValues.y));
                    
                    NSValue* newScale = [self valueObjectFromPoint:newScalePoint];
                    
                    [frameDict setObject:newScale forKey:@"scale"];
                    frameCounter ++;
                }
            }
        } else {
            //linear
            CGFloat totalDeltaWidth = endingSize.x - startingSize.x;
            CGFloat totalDeltaHeight = endingSize.y - startingSize.y;
            
            CGFloat deltaWidth = totalDeltaWidth / keyFramesInSequence;
            CGFloat deltaHeight = totalDeltaHeight / keyFramesInSequence;
            
            for (int f = 0; f < keyFramesInSequence; f++) {
                NSMutableDictionary* frameDict = [self getFrameDictionaryFromAnimation:mutableAnimation withFrameCounter:frameCounter andKeyFramesInSequence:keyFramesInSequence];
                
                CGPoint newScalePoint = CGPointMake((startingSize.x + deltaWidth * f), (startingSize.y + deltaHeight * f));
                
                NSValue* newScale = [self valueObjectFromPoint:newScalePoint];
                
                [frameDict setObject:newScale forKey:@"scale"];
                frameCounter ++;
            }
        }
    }
}


-(void)calculateSlotKeyAttachmentFramesInTotalAnimation:(NSMutableArray*)mutableAnimation forSkinSlot:(SGG_SkinSlot*)skinSlot{
    NSDictionary* startKeyFrameDict = [attachmentInput firstObject];
    
    if ([startKeyFrameDict[@"time"] floatValue] != TIME_VALUE_ZERO) {
        NSNumber *time = [NSNumber numberWithFloat:TIME_VALUE_ZERO];
        NSString *name = skinSlot.defaultAttachment;
        if (!name) {
            name = ATTACHMENT_NAME_EMPTY;
        }
        
        NSDictionary* attachmentKeyframe = [NSDictionary dictionaryWithObjects:@[time, name] forKeys:@[@"time", @"attachmentName"]];
        [attachmentInput insertObject:attachmentKeyframe atIndex:0];
    }
    
    [self calculateSlotKeyFramesForAnimation:mutableAnimation withInputArray:attachmentInput skinSlot:skinSlot andKeys:@[@"attachmentName"]];
}

-(void)calculateSlotKeyColorAndAlphaFramesInTotalAnimation:(NSMutableArray*)mutableAnimation forSkinSlot:(SGG_SkinSlot*)skinSlot{
    NSDictionary* startKeyFrameDict = [colorInput firstObject];
    
    if ([startKeyFrameDict[@"time"] floatValue] != TIME_VALUE_ZERO) {
        NSNumber *time = [NSNumber numberWithFloat:TIME_VALUE_ZERO];
        NSString *color = skinSlot.defaultColor;
        NSNumber *alpha = [NSNumber numberWithFloat:skinSlot.alpha];
        
        NSDictionary* colorAndAlphaKeyframe = [NSDictionary dictionaryWithObjects:@[time, color, alpha] forKeys:@[@"time", @"color", @"alpha"]];
        [colorInput insertObject:colorAndAlphaKeyframe atIndex:0];
    }
    
    [self calculateSlotKeyFramesForAnimation:mutableAnimation withInputArray:colorInput skinSlot:skinSlot andKeys:@[@"color", @"alpha"]];
}

-(void)calculateSlotKeyDrawOrderFramesInTotalAnimation:(NSMutableArray*)mutableAnimation forSkinSlot:(SGG_SkinSlot*)skinSlot{
    NSDictionary* startKeyFrameDict = [drawOrderInput firstObject];
    
    if ([startKeyFrameDict[@"time"] floatValue] != TIME_VALUE_ZERO) {
        NSNumber *time = [NSNumber numberWithFloat:TIME_VALUE_ZERO];
        NSNumber *offset = [NSNumber numberWithFloat:skinSlot.zPosition];
        
        NSDictionary* drawOrderKeyframe = [NSDictionary dictionaryWithObjects:@[time, offset] forKeys:@[@"time", @"offset"]];
        [drawOrderInput insertObject:drawOrderKeyframe atIndex:0];
    }
    
    [self calculateSlotKeyFramesForAnimation:mutableAnimation withInputArray:drawOrderInput skinSlot:skinSlot andKeys:@[@"offset"]];
}


#pragma mark UTILITIES

-(NSDictionary*)getEndKeyframeDictionaryFromArray:(NSMutableArray*)inputArray atIndex:(NSUInteger)index{
    if (index == inputArray.count - 1) {
        return inputArray[index];
    } else {
        return inputArray[index + 1];
    }
}

-(CGFloat)getEndingTimeFromDictionary:(NSDictionary*)endKeyFrameDict withInputArray:(NSMutableArray*)inputArray atIndex:(NSUInteger)index{
    if (index == inputArray.count -1) {
        return self.totalLength;
    }else{
        return [endKeyFrameDict[@"time"] doubleValue];
    }
}

-(NSInteger)getKeyFramesInSequenceForStartingTime:(CGFloat)startingTime andEndingTime:(CGFloat)endingTime{
    CGFloat sequenceTime = endingTime - startingTime;
    
    NSInteger keyFramesInSequence = 0;
    if (sequenceTime > 0) {
        CGFloat keyFrames = sequenceTime / self.timeFrameDelta ;
        keyFramesInSequence = round(keyFrames);
    }else {
        keyFramesInSequence = 1;
    }
    
    return keyFramesInSequence;
}

-(NSMutableDictionary*)getFrameDictionaryFromAnimation:(NSMutableArray*)mutableAnimation withFrameCounter:(NSInteger)frameCounter andKeyFramesInSequence:(NSInteger)keyFramesInSequence{
    if (keyFramesInSequence == 1) {
        return [mutableAnimation lastObject];
    }else{
        return [self getFrameDictionaryFromAnimation:mutableAnimation withFrameCounter:frameCounter];
    }
}

-(NSMutableDictionary*)getFrameDictionaryFromAnimation:(NSMutableArray*)mutableAnimation withFrameCounter:(NSInteger)frameCounter{
    NSMutableDictionary* frameDict;
    if (frameCounter > (int)(mutableAnimation.count - 1)) {
        frameDict = [[NSMutableDictionary alloc] init];
        [mutableAnimation addObject:frameDict];
    } else {
        frameDict = mutableAnimation[frameCounter];
    }
    
    return frameDict;
}

-(void)calculateSlotKeyFramesForAnimation:(NSMutableArray*)mutableAnimation withInputArray:(NSMutableArray*)inputArray skinSlot:(SGG_SkinSlot*)skinSlot andKeys:(NSArray<NSString*> *)keys {
    NSInteger frameCounter = 0;
    
    NSDictionary *startKeyFrameDict;
    NSDictionary *endKeyFrameDict;
    for (int i = 0; i < inputArray.count; i++) {
        startKeyFrameDict = inputArray[i];
        CGFloat startingTime = [startKeyFrameDict[@"time"] floatValue];
        
        endKeyFrameDict = [self getEndKeyframeDictionaryFromArray:inputArray atIndex:i];
        CGFloat endingTime = [self getEndingTimeFromDictionary:endKeyFrameDict withInputArray:inputArray atIndex:i];
        
        NSInteger keyFramesInSequence = [self getKeyFramesInSequenceForStartingTime:startingTime andEndingTime:endingTime];
        
        NSMutableDictionary* frameDict;
        if (keyFramesInSequence == 1) {
            //case last keyFrame is set on total length:
            //update only the last keyframe in mutableAnimation to display last keyframe correctly
            frameDict =  mutableAnimation[frameCounter - 1];
            [self updateFrameDictionary:frameDict withStartKeyFrameDictionary:startKeyFrameDict forKeys:keys];
        }else{
            for (int f = 0; f < keyFramesInSequence; f++) {
                frameDict = [self getFrameDictionaryFromAnimation:mutableAnimation withFrameCounter:frameCounter];
                [self updateFrameDictionary:frameDict withStartKeyFrameDictionary:startKeyFrameDict forKeys:keys];
                frameCounter ++;
            }
        }
    }
}

-(void)updateFrameDictionary:(NSMutableDictionary*)frameDict withStartKeyFrameDictionary:(NSDictionary*)startKeyFrameDict forKeys:(NSArray<NSString*>*)keys {
    [keys enumerateObjectsUsingBlock:^(NSString * _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
        [frameDict setObject:[startKeyFrameDict objectForKey:key] forKey:key];
    }];
}

-(NSValue*)valueObjectFromPoint:(CGPoint)point {
#if TARGET_OS_IPHONE
    return [NSValue valueWithCGPoint:point];
#else
    return [NSValue valueWithPoint:point];
#endif
    
}

-(CGPoint)pointFromValueObject:(NSValue*)valueObject {
#if TARGET_OS_IPHONE
    return [valueObject CGPointValue];
#else
    return [valueObject pointValue];
#endif
    
}



#pragma mark BEZIER MATH

-(CGPoint)calculateBezierPoint:(CGFloat)t andPoint0:(CGPoint)p0 andPoint1:(CGPoint)p1 andPoint2:(CGPoint)p2 andPoint3:(CGPoint)p3 {
    
    CGFloat u = 1 - t;
    CGFloat tt = t * t;
    CGFloat uu = u * u;
    CGFloat uuu = uu * u;
    CGFloat ttt = tt * t;
    
    
    CGPoint finalPoint = CGPointMake(p0.x * uuu, p0.y * uuu);
    finalPoint = CGPointMake(finalPoint.x + (3 * uu * t * p1.x), finalPoint.y + (3 * uu * t * p1.y));
    finalPoint = CGPointMake(finalPoint.x + (3 * u * tt * p2.x), finalPoint.y + (3 * u * tt * p2.y));
    finalPoint = CGPointMake(finalPoint.x + (ttt * p3.x), finalPoint.y + (ttt * p3.y));
    
    
    return finalPoint;
}


//following algorithm sourced from this page: http://stackoverflow.com/a/17546429/2985369
//start x bezier algorithm

-(NSArray*)solveQuadraticEquationWithA:(double)a andB:(double)b andC:(double)c {
    
    double discriminant = b * b - 4 * a * c;
    
    if (discriminant < 0) {
        NSLog(@"1");
        return nil;
    } else {
        double possibleA = (-b + sqrt(discriminant) / (2 * a));
        double possibleB = (-b - sqrt(discriminant) / (2 * a));
        NSLog(@"2");
        return @[[NSNumber numberWithDouble:possibleA], [NSNumber numberWithDouble:possibleB]];
    }
}

-(NSArray*)solveCubicEquationWithA:(double)a andB:(double)b andC:(double)c andD:(double)d {
    
    //used http://www.1728.org/cubic.htm as source for formula instead of the one included with the overall algorithm
    
    double f = ((3 * c / a) - ((b * b) / (a * a))) / 3;
    double g = (((2 * b * b * b) / (a * a * a)) - ((9 * b * c) / (a * a)) + ((27 * d) / a)) / 27;
    double h = (g * g / 4) + ((f * f * f) / 27);
    
    if (h == 0 && g == 0 && h == 0) {
        //3 real roots and all equal
        
        double x = (d / a);
        x = pow(x, 0.3333333333333333) * -1;
        
        
        NSArray* roots = @[[NSNumber numberWithDouble:x]];
        return roots;
        
    } else if (h > 0) {
        // 1 real root
        double R = -(g / 2) + sqrt(h);
        double S = pow(R, 0.3333333333333333); //may need to do 0.3333333333
        double T = -(g / 2) - sqrt(h);
        double U;
        if (T < 0) {
            U = pow(-T, 0.3333333333333333);
            U *= -1;
        } else {
            U = pow(T, 0.3333333333333333);
        }
        double x = (S + U) - (b / (3 * a));
        
        NSArray* roots = @[[NSNumber numberWithDouble:x]];
        
        
        return roots;
    } else if (h <= 0) {
        //all three real
        double i = sqrt(( (g * g) / 4) - h);
        double j = pow(i, 0.333333333333);
        double k = acos(-(g / (2 * i)));
        double L = -j;
        double M = cos(k / 3);
        double N = (sqrt(3) * sin(k /3));
        double P = (b / (3 * a)) * -1;
        
        double xOne = 2 * j * cos(k / 3) - (b / (3 * a));
        double xTwo = L * (M + N) + P;
        double xThree = L * (M - N) + P;
        
        NSArray* roots = @[[NSNumber numberWithDouble:xOne], [NSNumber numberWithDouble:xTwo], [NSNumber numberWithDouble:xThree]];
        
        return roots;
    } else {
        NSLog(@"I've made a huge mistake: Cubic equation seemingly impossible.");
    }
    return nil;
}


-(double)getBezierPercentAtXValue:(double)x withXValuesFromPoint0:(double)p0x point1:(double)p1x point2:(double)p2x andPoint3:(double)p3x {
    
    if (x == 0 || x == 1) {
        return x;
    }
    
    p0x -= x;
    p1x -= x;
    p2x -= x;
    p3x -= x;
    
    double a = p3x - 3 * p2x + 3 * p1x - p0x;
    double b = 3 * p2x - 6 * p1x + 3 * p0x;
    double c = 3 * p1x - 3 * p0x;
    double d = p0x;
    
    
    NSArray* roots = [self solveCubicEquationWithA:a andB:b andC:c andD:d];
    
    
    double closest = 0;
    
    for (int i = 0; i < roots.count; i++) {
        double root = [roots[i] doubleValue];
        
        if (root >= 0 && root <= 1) {
            return root;
        } else {
            if (fabs(root) < 0.5) {
                closest = 0;
            } else {
                closest = 1;
            }
        }
    }
    
    
    
    return fabs(closest);
}

//end x bezier algorithm

@end
