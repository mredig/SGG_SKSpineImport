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

#pragma mark INPUT DATA

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
	
}

-(void)addRotationAtTime:(CGFloat)time withAngle:(CGFloat)angle andCurveInfo:(id)curve {
	if (!rotationInput) {
		rotationInput = [[NSMutableArray alloc] init];
	}
	
	if (time > _totalLength) {
		_totalLength = time;
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

#pragma mark RENDER DATA

-(void)calculateTotalAction {
	
	if (_timeFrameDelta == 0) {
		_timeFrameDelta = 1.0f/120.0f;
	}
	NSInteger totalFrames = round(_totalLength / _timeFrameDelta);
//	NSLog(@"total time: %f, delta: %f totalFrames = %i", _totalLength, _timeFrameDelta, (int)totalFrames);
	
	NSMutableArray* mutableAnimation = [[NSMutableArray alloc] initWithCapacity:totalFrames];
	
	[self calculateTranslationKeyframesInTotalAnimation:mutableAnimation];
	
	[self calculateRotationKeyframesInTotalAnimation:mutableAnimation];
	
	[self calculateScaleKeyframesInTotalAnimation:mutableAnimation];
	
	[mutableAnimation removeLastObject];
	
	_animation = [NSArray arrayWithArray:mutableAnimation];

//	NSLog(@"frameCount: %lu", (unsigned long)mutableAnimation.count);
//	for (int i = 0; i < mutableAnimation.count; i++) {
//		NSInteger spineFrame = i % 4;
//		if (spineFrame == 0) {
//			NSDictionary* dict = mutableAnimation[i];
//			NSLog(@"frame: %i point: %f %f rotation: %f", i, [self pointFromValueObject:dict[@"position"]].x, [self pointFromValueObject:dict[@"position"]].y, [dict[@"rotation"] doubleValue] * (180/M_PI));
//		}
//
//	}
}


-(void)calculateTranslationKeyframesInTotalAnimation:(NSMutableArray*)mutableAnimation {
	
	
	//translation keyframes
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
//			NSLog(@"float: %f int: %i", keyFrames, (int)keyFramesInSequence);
		} else {
//			NSLog(@"end of sequence");
			keyFramesInSequence = 1;
		}
		
		//		NSLog(@"curve: %@", curveInfo);
		
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
				NSArray* curveArray = [NSArray arrayWithArray:curveInfo];
//				NSLog(@"curveArray: %@", curveArray);
				CGPoint curvePointOne, curvePointTwo, curvePointThree, curvePointFour;
				curvePointOne = CGPointZero;
				curvePointTwo = CGPointMake([curveArray[0] doubleValue], [curveArray[1] doubleValue]);
				curvePointThree = CGPointMake([curveArray[2] doubleValue], [curveArray[3] doubleValue]);
				curvePointFour = CGPointMake(1.0f, 1.0f);
				
				
				
				CGFloat totalDeltaX = endingLocation.x - startingLocation.x;
				CGFloat totalDeltaY = endingLocation.y - startingLocation.y;
				
//				NSLog(@"p2: %f %f p3: %f %f tDelX: %f yDelY: %f", curvePointTwo.x, curvePointTwo.y, curvePointThree.x, curvePointThree.y, totalDeltaX, totalDeltaY);
				
				for (int f = 0; f < keyFramesInSequence; f++) {
					NSMutableDictionary* frameDict = [[NSMutableDictionary alloc] init];
					CGFloat timeProgress = ((CGFloat)f / (CGFloat)keyFramesInSequence);
					CGFloat bezierProgress = [self getBezierPercentAtXValue:timeProgress withXValuesFromPoint0:curvePointOne.x point1:curvePointTwo.x point2:curvePointThree.x andPoint3:curvePointFour.x];
					
					
					CGPoint bezValues = [self calculateBezierPoint:bezierProgress andPoint0:curvePointOne andPoint1:curvePointTwo andPoint2:curvePointThree andPoint3:curvePointFour];
//					NSLog(@"prog: %f value: %f", bezierProgress, bezValues.y);
//					NSLog(@"p2: %f p3: %f timeProg: %f bezProg: %f value: %f\n\n\n", curvePointTwo.x, curvePointThree.x, timeProgress, bezierProgress, bezValues.y);
					
					[frameDict setObject:[self valueObjectFromPoint:CGPointMake(startingLocation.x + totalDeltaX * bezValues.y, startingLocation.y + totalDeltaY * bezValues.y)] forKey:@"position"];
					[mutableAnimation addObject:frameDict];
				}
			}
		} else {
			//linear
			CGFloat deltaX = (endingLocation.x - startingLocation.x) / (keyFramesInSequence);
			CGFloat deltaY = (endingLocation.y - startingLocation.y) / (keyFramesInSequence);
//			NSLog(@"span %f to %f", startingTime, endingTime);
			for (int f = 0; f < keyFramesInSequence; f++) {
				NSMutableDictionary* frameDict = [[NSMutableDictionary alloc] init];
				[frameDict setObject:[self valueObjectFromPoint:CGPointMake(startingLocation.x + f * deltaX, startingLocation.y + f * deltaY)] forKey:@"position"];
				[mutableAnimation addObject:frameDict];
//				NSLog(@"rotation added");
			}
		}
	}
}

-(void)calculateRotationKeyframesInTotalAnimation:(NSMutableArray*)mutableAnimation {

	int frameCounter = 0;
	for (int i = 0; i < rotationInput.count; i++) {
		NSDictionary* startKeyFrameDict = rotationInput[i];
		NSDictionary* endKeyFrameDict;
		if (i == rotationInput.count - 1) {
			endKeyFrameDict = rotationInput[i];
		} else {
			endKeyFrameDict = rotationInput[i + 1];
		}
		CGFloat startingTime = [startKeyFrameDict[@"time"] doubleValue];
		CGFloat startingAngle = [startKeyFrameDict[@"angle"] doubleValue];
		id curveInfo = startKeyFrameDict[@"curve"];
		
		CGFloat endingTime = [endKeyFrameDict[@"time"] doubleValue];
		CGFloat endingAngle = [endKeyFrameDict[@"angle"] doubleValue];

		CGFloat sequenceTime = endingTime - startingTime;
		
		NSInteger keyFramesInSequence;
		if (sequenceTime > 0) {
			CGFloat keyFrames = sequenceTime / _timeFrameDelta ;
			keyFramesInSequence = round(keyFrames);
			//			NSLog(@"float: %f int: %i", keyFrames, (int)keyFramesInSequence);
		} else {
			//			NSLog(@"end of sequence");
			keyFramesInSequence = 1;
		}
		
		//		NSLog(@"curve: %@", curveInfo);
		
		if (curveInfo) {
			NSString* curveString = (NSString*)curveInfo;
			if ([curveInfo isKindOfClass:[NSString class]] && [curveString isEqualToString:@"stepped"]) {
				//stepped

				for (int f = 0; f < keyFramesInSequence; f++) {
					NSMutableDictionary* frameDict;
					if (frameCounter >= (int)(mutableAnimation.count - 1)) {
						frameDict = [[NSMutableDictionary alloc] init];
						[mutableAnimation addObject:frameDict];
					} else {
						frameDict = mutableAnimation[frameCounter];
					}

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
					NSMutableDictionary* frameDict;
					if (frameCounter >= (int)(mutableAnimation.count - 1)) {
						frameDict = [[NSMutableDictionary alloc] init];
						[mutableAnimation addObject:frameDict];
					} else {
						frameDict = mutableAnimation[frameCounter];
					}
					
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
				NSMutableDictionary* frameDict;
				if (frameCounter >= (int)(mutableAnimation.count - 1)) {
					frameDict = [[NSMutableDictionary alloc] init];
					[mutableAnimation addObject:frameDict];
				} else {
					frameDict = mutableAnimation[frameCounter];
				}

				
				[frameDict setObject:[NSNumber numberWithDouble:startingAngle + deltaRotation * f] forKey:@"rotation"];
				frameCounter ++;
			}
		}
	}
}

-(void)calculateScaleKeyframesInTotalAnimation:(NSMutableArray*)mutableAnimation {
	
	int frameCounter = 0;
	for (int i = 0; i < scaleInput.count; i++) {
		NSDictionary* startKeyFrameDict = scaleInput[i];
		NSDictionary* endKeyFrameDict;
		if (i == scaleInput.count - 1) {
			endKeyFrameDict = scaleInput[i];
		} else {
			endKeyFrameDict = scaleInput[i + 1];
		}
		CGFloat startingTime = [startKeyFrameDict[@"time"] doubleValue];
		CGPoint startingSize = [self pointFromValueObject:startKeyFrameDict[@"scale"]];
		id curveInfo = startKeyFrameDict[@"curve"];
		
		CGFloat endingTime = [endKeyFrameDict[@"time"] doubleValue];
		CGPoint endingSize = [self pointFromValueObject:endKeyFrameDict[@"scale"]];

		CGFloat sequenceTime = endingTime - startingTime;
		
		NSInteger keyFramesInSequence;
		if (sequenceTime > 0) {
			CGFloat keyFrames = sequenceTime / _timeFrameDelta ;
			keyFramesInSequence = round(keyFrames);
		} else {
			keyFramesInSequence = 1;
		}
		
		//		NSLog(@"curve: %@", curveInfo);
		
		if (curveInfo) {
			NSString* curveString = (NSString*)curveInfo;
			if ([curveInfo isKindOfClass:[NSString class]] && [curveString isEqualToString:@"stepped"]) {
				//stepped
				
				for (int f = 0; f < keyFramesInSequence; f++) {
					NSMutableDictionary* frameDict;
					if (frameCounter >= (int)(mutableAnimation.count - 1)) {
						frameDict = [[NSMutableDictionary alloc] init];
						[mutableAnimation addObject:frameDict];
					} else {
						frameDict = mutableAnimation[frameCounter];
					}
					
					
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
					NSMutableDictionary* frameDict;
					if (frameCounter >= (int)(mutableAnimation.count - 1)) {
						frameDict = [[NSMutableDictionary alloc] init];
						[mutableAnimation addObject:frameDict];
					} else {
						frameDict = mutableAnimation[frameCounter];
					}
					
					CGFloat timeProgress = ((CGFloat)f / (CGFloat)keyFramesInSequence);
					CGFloat bezierProgress = [self getBezierPercentAtXValue:timeProgress withXValuesFromPoint0:curvePointOne.x point1:curvePointTwo.x point2:curvePointThree.x andPoint3:curvePointFour.x];
					
					
					CGPoint bezValues = [self calculateBezierPoint:bezierProgress andPoint0:curvePointOne andPoint1:curvePointTwo andPoint2:curvePointThree andPoint3:curvePointFour];
					
					
					
					CGPoint newScalePoint = CGPointMake((startingSize.x + totalDeltaWidth * bezValues.y), (startingSize.y + totalDeltaHeight * bezValues.y));
//				NSLog(@"scale: %f %f", newScalePoint.x, newScalePoint.y);

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
				NSMutableDictionary* frameDict;
				if (frameCounter >= (int)(mutableAnimation.count - 1)) {
					frameDict = [[NSMutableDictionary alloc] init];
					[mutableAnimation addObject:frameDict];
				} else {
					frameDict = mutableAnimation[frameCounter];
				}
				
				CGPoint newScalePoint = CGPointMake((startingSize.x + deltaWidth * f), (startingSize.y + deltaHeight * f));
//				NSLog(@"scale: %f %f", newScalePoint.x, newScalePoint.y);
				
				NSValue* newScale = [self valueObjectFromPoint:newScalePoint];
				
				[frameDict setObject:newScale forKey:@"scale"];
				frameCounter ++;
			}
		}
	}
}

#pragma mark UTILITIES


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
	
	
//	NSLog(@"  a: %f b: %f c: %f d: %f", a, b, c, d);
	NSArray* roots = [self solveCubicEquationWithA:a andB:b andC:c andD:d];
	
//	NSLog(@"roots: %@", roots);

	double closest;

	for (int i = 0; i < roots.count; i++) {
		double root = [roots[i] doubleValue];
		
		if (root >= 0 && root <= 1) {
//			NSLog(@"root exists");
			return root;
		} else {
			if (fabs(root) < 0.5) {
				closest = 0;
//			} else if (1 - fabs(root) > closest) {
			} else {
				closest = 1;
			}
		}
	}
//	
//	NSLog(@"problems: %@", roots);
//	NSLog(@"closest: %f", closest);

	
	return fabs(closest);
}

//end x bezier algorithm

@end
