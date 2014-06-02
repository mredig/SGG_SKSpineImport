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
	
}


@end
