//
//  SGG_SpineBone.m
//  SpineTesting
//
//  Created by Michael Redig on 2/10/14.
//  Copyright (c) 2014 Secret Game Group LLC. All rights reserved.
//

#import "SGG_SpineBone.h"

@implementation SGG_SpineBone

-(id)init {
	if (self = [super init]) {
		_animations = [[NSMutableDictionary alloc] init];
	}
	return self;
}

-(void)debugWithLength{

	SKSpriteNode* sprite = [SKSpriteNode spriteNodeWithColor:[SKColor redColor] size:CGSizeMake(5, _length)];
	sprite.anchorPoint = CGPointMake(0.5, 0);
	sprite.zRotation = -M_PI_2;
	sprite.zPosition = 1000;
	[self addChild:sprite];

	
}


-(void)setDefaultsAndBase {
	
	_defaultPosition = self.position;
	_defaultRotation = self.zRotation;
	_defaultScaleX = self.xScale;
	_defaultScaleY = self.yScale;
	_basePosition = self.position;
	_baseRotation = self.zRotation;
	_baseScaleX = self.xScale;
	_baseScaleY = self.yScale;
	
}

-(void)setToDefaults {
	
	self.position = _defaultPosition;
	self.zRotation = _defaultRotation;
	self.xScale = _defaultScaleX;
	self.yScale = _defaultScaleY;
	_basePosition = self.position;
	_baseRotation = self.zRotation;
	_baseScaleX = self.xScale;
	_baseScaleY = self.yScale;
}

-(void)playAnimations:(NSArray*)animationNames {
	NSInteger maxFrameCount = 0;

	_currentAnimation = nil;
	NSMutableArray* sequentialAnimations = [[NSMutableArray alloc] init];
	for (int i = 0; i < animationNames.count; i++) {
		SGG_SpineBoneAction* action = _animations[animationNames[i]];
		maxFrameCount += (NSInteger)(action.totalLength / action.timeFrameDelta);
		
		NSMutableArray* tempAnimationArray = [NSMutableArray arrayWithArray:action.animation];
		
		while (sequentialAnimations.count + tempAnimationArray.count > maxFrameCount) {
			[tempAnimationArray removeObjectAtIndex:0];
		}
		
		[sequentialAnimations addObjectsFromArray:tempAnimationArray];
	}
	_currentAnimation = [NSArray arrayWithArray:sequentialAnimations];
//	NSLog(@"setting current animation: %@", _currentAnimation);

}

-(void)removeAllActions {
	[super removeAllActions];
	
	_currentAnimation = nil;
	
}

-(void)updateAnimationAtFrame:(NSInteger)currentFrame {
	
	if (_currentAnimation && _currentAnimation.count ) {

		
		if (currentFrame >= _currentAnimation.count) {
			currentFrame = _currentAnimation.count - 1;
		}
		NSDictionary* thisFrameDict = _currentAnimation[currentFrame];
		CGPoint offsetPos = [self pointFromValueObject:thisFrameDict[@"position"]];
		self.position = CGPointMake(_basePosition.x + offsetPos.x, _basePosition.y + offsetPos.y) ;
		self.zRotation = _baseRotation + [thisFrameDict[@"rotation"] doubleValue];
		
		
		
		CGPoint newScale;
		if (thisFrameDict[@"scale"]) {
			newScale = [self pointFromValueObject:thisFrameDict[@"scale"]];
			
			self.xScale = _baseScaleX * newScale.x;
			self.yScale = _baseScaleY * newScale.y;
		} else {
			self.xScale = _baseScaleX;
			self.yScale = _baseScaleY;
		}


		
	}
	
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

-(BOOL)distanceBetweenPointA:(CGPoint)pointA andPointB:(CGPoint)pointB isWithinXDistance:(CGFloat)distance {
	
	CGFloat deltaX = pointA.x - pointB.x;
	CGFloat deltaY = pointA.y - pointB.y;
	
	return (deltaX * deltaX) + (deltaY * deltaY) <= distance * distance;
}

@end
