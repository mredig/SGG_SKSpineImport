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
	

	_currentAnimation = nil;
	NSMutableArray* sequentialAnimations = [[NSMutableArray alloc] init];
	for (int i = 0; i < animationNames.count; i++) {
		SGG_SpineBoneAction* action = _animations[animationNames[i]];
		
		[sequentialAnimations addObjectsFromArray:action.animation];
	}
	_currentAnimation = [NSArray arrayWithArray:sequentialAnimations];
//	NSLog(@"setting current animation: %@", _currentAnimation);

}

-(void)updateAnimationAtTime:(double)time thatStartedAt:(double)startTime {
	
	
//	NSLog(@"%@ updating", self.name);
	
	if (_currentAnimation && startTime != 0 && _currentAnimation.count ) {
		double timeElapsed = time - startTime;

		NSInteger framesElapsed = round(timeElapsed / 0.008333333333333333); // 1/120
		NSInteger currentFrame = framesElapsed % (_currentAnimation.count - 1);
		
		NSDictionary* thisFrameDict = _currentAnimation[currentFrame];
		CGPoint offsetPos = [self pointFromValueObject:thisFrameDict[@"position"]];
		self.position = CGPointMake(_basePosition.x + offsetPos.x, _basePosition.y + offsetPos.y) ;
		self.zRotation = _baseRotation + [thisFrameDict[@"rotation"] doubleValue];

	}
//	NSLog(@"%@ updated", self.name);

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
