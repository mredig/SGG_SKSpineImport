//
//  SGG_SpineBoneAction.m
//  SGG_SKSpineImport
//
//  Created by Michael Redig on 6/2/14.
//  Copyright (c) 2014 Secret Game Group LLC. All rights reserved.
//

#import "SGG_SpineBoneAction.h"

@interface SGG_SpineBoneAction () {
	
	NSMutableArray* translationInput;
	NSMutableArray* rotationInput;
	NSMutableArray* scaleInput;
	
	
}

@end


@implementation SGG_SpineBoneAction

-(id)init {
	if (self = [super init]) {

	}
	return self;
}

-(void)addTranslationAtTime:(CGFloat)time withPoint:(CGPoint)point andCurveInfo:(id)curve {
	if (!translationInput) {
		translationInput = [[NSMutableArray alloc] init];
	}
	
	if (time > _totalLength) {
		_totalLength = time;
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

//	NSLog(@"%@", translationInput);
	
}

-(void)addRotationAtTime:(CGFloat)time withAngle:(CGFloat)angle andCurveInfo:(id)curve {
	
}

-(void)addScaleAtTime:(CGFloat)time withScale:(CGSize)scale andCurveInfo:(id)curve {
	
}

-(void)calculateTotalAction {
	
	if (_timeFrameDelta == 0) {
		_timeFrameDelta = 1.0f/120.0f;
	}
	NSInteger totalFrames = round(_totalLength / _timeFrameDelta);
	NSLog(@"total time: %f, delta: %f totalFrames = %i", _totalLength, _timeFrameDelta, (int)totalFrames);
	
	NSMutableArray* mutableAnimation = [[NSMutableArray alloc] initWithCapacity:totalFrames];
	
	for (int i = 0; i < translationInput.count; i++) {
		NSDictionary* startKeyFrameDict = translationInput[i];
		NSDictionary* endKeyFrameDict;
		if (i == translationInput.count - 1) {
			endKeyFrameDict = translationInput[i];
		} else {
			endKeyFrameDict = translationInput[i + 1];
		}
		CGFloat startingTime = [startKeyFrameDict[@"time"] doubleValue];
		CGPoint startingLocation = [self pointFromValueObject:startKeyFrameDict[@"point"]];
		id curveInfo = startKeyFrameDict[@"curve"];
		
		CGFloat endingTime = [endKeyFrameDict[@"time"] doubleValue];
		CGPoint endingLocation = [self pointFromValueObject:endKeyFrameDict[@"point"]];
		
		CGFloat sequenceTime = endingTime - startingTime;
		
		NSInteger keyFramesInSequence;
		if (sequenceTime > 0) {
			CGFloat keyFrames = sequenceTime / _timeFrameDelta ;
			keyFramesInSequence = round(keyFrames);
			NSLog(@"float: %f int: %i", keyFrames, (int)keyFramesInSequence);
		} else {
			NSLog(@"fart");
			keyFramesInSequence = 1;
		}
		
		if (curveInfo) {
			NSString* curveString = (NSString*)curveInfo;
			if ([curveInfo isKindOfClass:[NSString class]] && [curveString isEqualToString:@"stepped"]) {
				//stepped
				for (int f = 0; f < keyFramesInSequence; f++) {
					NSMutableDictionary* frameDict = [[NSMutableDictionary alloc] init];
					[frameDict setObject:[self valueObjectFromPoint:CGPointMake(startingLocation.x, startingLocation.y)] forKey:@"position"];
					[mutableAnimation addObject:frameDict];
				}
			} else {
				//timing curve
//				NSArray* curveArray = [NSArray arrayWithArray:curveInfo];
			}
		} else {
			//linear
			CGFloat deltaX = (endingLocation.x - startingLocation.x) / (keyFramesInSequence);
			CGFloat deltaY = (endingLocation.y - startingLocation.y) / (keyFramesInSequence);
			NSLog(@"span %f to %f", startingTime, endingTime);
			for (int f = 0; f < keyFramesInSequence; f++) {
				NSMutableDictionary* frameDict = [[NSMutableDictionary alloc] init];
				[frameDict setObject:[self valueObjectFromPoint:CGPointMake(startingLocation.x + f * deltaX, startingLocation.y + f * deltaY)] forKey:@"position"];
				[mutableAnimation addObject:frameDict];
			}
		}
	}
	
	_animation = [NSArray arrayWithArray:mutableAnimation];

	
//	for (int i = 0; i < mutableAnimation.count; i++) {
//		NSDictionary* dict = mutableAnimation[i];
//		NSLog(@"frame: %i point: %f %f", i, [self pointFromValueObject:dict[@"position"]].x, [self pointFromValueObject:dict[@"position"]].y);
//	}
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

@end
