//
//  SGG_MyScene.m
//  SpineTesting
//
//  Created by Michael Redig on 2/10/14.
//  Copyright (c) 2014 Secret Game Group LLC. All rights reserved.
//

#import "SGG_MyScene.h"
#import "SGG_SpineJSONTools.h"

@interface SGG_MyScene () {
	SGG_SpineJSONTools* reader;

}

@end

@implementation SGG_MyScene {

}

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        /* Setup your scene here */
		reader = [[SGG_SpineJSONTools alloc] init];
		NSDictionary* dict = [reader readJSONFileNamed:@"skeleton"];
		NSLog(@"dict: %@", dict);
    }
    return self;
}

#if TARGET_OS_IPHONE

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	[self enumerateChildNodesWithName:@"//*" usingBlock:^(SKNode *node, BOOL *stop) {
		NSLog(@"%@", node);
	}];
	
	
	
}


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
