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
	[self addChild:sprite];

	
}



@end
