//
//  SGG_MyScene.m
//  SpineTesting
//
//  Created by Michael Redig on 2/10/14.
//  Copyright (c) 2014 Secret Game Group LLC. All rights reserved.
//

#import "SGG_MyScene.h"
#import "DZSpineScene.h"
#import "DZSpineSceneBuilder.h"

@interface SGG_MyScene () {
}

@end

@implementation SGG_MyScene {
	SpineSkeleton* _skeleton;
	DZSpineSceneBuilder* _builder;
	SKNode* _elf;
	SKNode* _spineNode;
}

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        /* Setup your scene here */
		_skeleton = [DZSpineSceneBuilder loadSkeletonName:@"skeleton" scale:0.5];
		
		_builder = [DZSpineSceneBuilder builder];
		
		_elf = [SKNode node];
		_elf.position = CGPointMake(self.size.width/2, 0);
		[self addChild:_elf];
		
//		_spineNode = [_builder nodeWithSkeleton:_skeleton animationName:@"trip" loop:YES];
		SpineAnimation* animation1 = [_skeleton animationWithName:@"trip"];
		SpineAnimation* animation2 = [_skeleton animationWithName:@"standing"];

//		_spineNode = [_builder nodeWithSkeleton:_skeleton animationNames:@[@"trip", @"standing"] loop:YES];
		_spineNode = [_builder nodeWithSkeleton:_skeleton animations:@[animation1, animation2] loop:YES];
		[_elf addChild:_spineNode];
		
		
    }
    return self;
}

#if TARGET_OS_IPHONE




#else

-(void)mouseDown:(NSEvent *)theEvent {
     /* Called when a mouse click occurs */
    
    CGPoint location = [theEvent locationInNode:self];
    
    SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithImageNamed:@"Spaceship"];
    
    sprite.position = location;
    sprite.scale = 0.5;
    
    SKAction *action = [SKAction rotateByAngle:M_PI duration:1];
    
    [sprite runAction:[SKAction repeatActionForever:action]];
    
    [self addChild:sprite];
}

#endif
-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
}

@end
