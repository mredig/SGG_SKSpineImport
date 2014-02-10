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
		
		SKSpriteNode* sprite = [SKSpriteNode spriteNodeWithColor:[SKColor redColor] size:CGSizeMake(10, 10)];
		[self addChild:sprite];
		
		
	}
	return self;
}




@end
