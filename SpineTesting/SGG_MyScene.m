//
//  SGG_MyScene.m
//  SpineTesting
//
//  Created by Michael Redig on 2/10/14.
//  Copyright (c) 2014 Secret Game Group LLC. All rights reserved.
//

#import "SGG_MyScene.h"
#import "SpineImport.h"

@interface SGG_MyScene () {
	SGG_Spine* spineTest;
	SGG_SKUtilities* sharedUtilities;
	
	
}

@end

@implementation SGG_MyScene {

}

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        /* Setup your scene here */
		
		
		spineTest = [SGG_Spine node];
		spineTest.debugMode = YES;
//		[spineTest skeletonFromFileNamed:@"skeleton" andAtlasNamed:@"elf"] ;
		[spineTest skeletonFromFileNamed:@"goblins" andAtlasNamed:@"goblin"] ;
		spineTest.position = CGPointMake(self.size.width/2, self.size.height/4);
		[spineTest runAnimation:@"walk" andCount:-1];
		[self addChild:spineTest];
		
		SKTextureAtlas* goblins = [SKTextureAtlas atlasNamed:@"goblin"];
		
		SKSpriteNode* spriteTest = [SKSpriteNode spriteNodeWithTexture:[goblins textureNamed:@"goblingirlhead"]];
		spriteTest.position = CGPointMake(self.size.width/2, self.size.height/2);
		[self addChild: spriteTest];

    }
    return self;
}


#if TARGET_OS_IPHONE

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
//	[self enumerateChildNodesWithName:@"//*" usingBlock:^(SKNode *node, BOOL *stop) {
//		NSLog(@"%@", node);
//	}];
	
	
	
}


#else

-(void)mouseDown:(NSEvent *)theEvent {
     /* Called when a mouse click occurs */
    
    CGPoint location = [theEvent locationInNode:self];
	[spineTest runAnimation:@"jump" andCount:1];


}

-(void)mouseDragged:(NSEvent *)theEvent {
	CGPoint location = [theEvent locationInNode:self];

	[spineTest stopAnimation];
	[spineTest resetSkeleton];

}

#endif
-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
}





@end
