//
//  SGG_MyScene.m
//  SpineTesting
//
//  Created by Michael Redig on 2/10/14.
//  Copyright (c) 2014 Secret Game Group LLC. All rights reserved.
//

#import "SGG_MyScene.h"
#import "SpineImport.h"
#import "SGG_SKUtilities.h"

@interface SGG_MyScene () {
	SGG_Spine* spineTest;
	SGG_Spine* spineTest2;
	SGG_Spine* spineTest3;
	SGG_SKUtilities* sharedUtilities;
	
	
}

@end

@implementation SGG_MyScene {

}

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        /* Setup your scene here */
		
		
		spineTest = [SGG_Spine node];
//		spineTest.debugMode = YES;
		[spineTest skeletonFromFileNamed:@"spineboy" andAtlasNamed:@"spineboy" andUseSkinNamed:Nil];
		spineTest.position = CGPointMake(self.size.width/4, self.size.height/4);
		[spineTest runAnimation:@"walk" andCount:-1];
		spineTest.queueCount = -1;
		spineTest.queuedAnimation = @"walk";
		spineTest.queueIntro = 0.1;
		spineTest.zPosition = 0;
		[self addChild:spineTest];
		
		
		spineTest2 = [SGG_Spine node];
		[spineTest2 skeletonFromFileNamed:@"goblins" andAtlasNamed:@"goblin" andUseSkinNamed:@"goblingirl"];
		spineTest2.position = CGPointMake((self.size.width/4)*3, self.size.height/4);
		[spineTest2 runAnimation:@"walk" andCount:-1];
		spineTest2.zPosition = 10;
		[self addChild:spineTest2];
		
		
		spineTest3 = [SGG_Spine node];
		[spineTest3 skeletonFromFileNamed:@"dragon" andAtlasNamed:@"dragon" andUseSkinNamed:nil];
		spineTest3.position = CGPointMake((self.size.width/2), self.size.height/2);
		[spineTest3 runAnimation:@"flying" andCount:-1];
		spineTest3.zPosition = 20;
		spineTest3.xScale = kPhone4Scale;
		spineTest3.yScale = kPhone4Scale;
		[self addChild:spineTest3];

//		SKTextureAtlas* goblins = [SKTextureAtlas atlasNamed:@"goblin"];
//		
//		SKSpriteNode* spriteTest = [SKSpriteNode spriteNodeWithTexture:[goblins textureNamed:@"goblingirl-head"]];
//		spriteTest.position = CGPointMake(self.size.width/2, self.size.height/2);
//		[self addChild: spriteTest];

//		NSString* string = @"this is a test - badabing";
//		NSLog(@"%@",string);
//		string = [string stringByReplacingOccurrencesOfString:@" - " withString:@"///"];
//		NSLog(@"%@", string);

		SKLabelNode* label1 = [SKLabelNode labelNodeWithFontNamed:@"Helvetica Neue Light"];
		label1.text = @"space to make boy jump";
		label1.color = [SKColor whiteColor];
		label1.position = CGPointMake(self.size.width/2, self.size.height/4 - 20);
		[self addChild:label1];
		
		SKLabelNode* label2 = [SKLabelNode labelNodeWithFontNamed:@"Helvetica Neue Light"];
		label2.text = @"\"a\" and \"d\" to change directions for boy";
		label2.color = [SKColor whiteColor];
		label2.position = CGPointMake(self.size.width/2, label1.position.y - 30);
		[self addChild:label2];
		
		SKLabelNode* label3 = [SKLabelNode labelNodeWithFontNamed:@"Helvetica Neue Light"];
		label3.text = @"click to change goblin skin";
		label3.color = [SKColor whiteColor];
		label3.position = CGPointMake(self.size.width/2, label2.position.y - 30);
		[self addChild:label3];

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
    
//    CGPoint location = [theEvent locationInNode:self];
	[spineTest2 changeSkinTo:@"goblin"];


}

-(void)mouseDragged:(NSEvent *)theEvent {
//	CGPoint location = [theEvent locationInNode:self];

//	[spineTest stopAnimation];
//	[spineTest resetSkeleton];
}

-(void)mouseUp:(NSEvent *)theEvent {
	
	[spineTest2 changeSkinTo:@"goblingirl"];

}

-(void)keyDown:(NSEvent *)theEvent {
	
	NSString *characters = [theEvent characters];
	if ([characters length]) {
		for (int s = 0; s<[characters length]; s++) {
			unichar character = [characters characterAtIndex:s];
			switch (character) {
				case ' ':{
					[spineTest runAnimation:@"jump" andCount:0 withSpeedFactor:1 withIntroPeriodOf:0.1 andUseQueue:YES];
					
				}
					break;
				case 'a': spineTest.xScale = -1;
					break;
				case 'd': spineTest.xScale = 1;
					break;
			}
		}
	}
	
	
	
}

#endif
-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
}





@end
