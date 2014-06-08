//
//  SGG_MyScene.m
//  SpineTesting
//
//  Created by Michael Redig on 2/10/14.
//  Copyright (c) 2014 Secret Game Group LLC. All rights reserved.
//

#import "SGG_MyScene.h"
#import "SpineImport.h"
#import "SGG_SpineBoneAction.h"

@interface SGG_MyScene () {
	SGG_Spine* boy;
	SGG_Spine* elf;
	SGG_Spine* goblin;
	SGG_Spine* stepTest;
	
	CGPoint startLocation;
	CGPoint ballPosition;
	
}

@end

@implementation SGG_MyScene {

}

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        /* Setup your scene here */
		
		
//		boy = [SGG_Spine node];
////		boy.debugMode = YES;
//		[boy skeletonFromFileNamed:@"spineboy" andAtlasNamed:@"spineboy" andUseSkinNamed:Nil];
//		boy.position = CGPointMake(self.size.width/4, self.size.height/4);
//		[boy runAnimation:@"walk" andCount:-1];
//		boy.queueCount = -1;
//		boy.queuedAnimation = @"walk";
//		boy.queueIntro = 0.1;
//		boy.zPosition = 0;
////		[self addChild:boy];
//		
//		
//		
//		elf = [SGG_Spine node];
//		[elf skeletonFromFileNamed:@"elf" andAtlasNamed:@"elf" andUseSkinNamed:Nil];
//		elf.position = CGPointMake(self.size.width/2, self.size.height/4);
//		[elf runAnimation:@"standing" andCount:-1];
//		elf.queueCount = -1;
//		elf.queuedAnimation = @"standing";
//		elf.queueIntro = 0.1;
//		elf.zPosition = 20;
//		elf.xScale = 0.6;
//		elf.yScale = 0.6;
////		[self addChild:elf];
//		
//		
//		goblin = [SGG_Spine node];
//		[goblin skeletonFromFileNamed:@"goblins" andAtlasNamed:@"goblin" andUseSkinNamed:@"goblingirl"];
//		goblin.position = CGPointMake((self.size.width/4)*3, self.size.height/4);
//		[goblin runAnimation:@"walk" andCount:-1];
//		goblin.zPosition = 10;
////		[self addChild:goblin];
		
		stepTest = [SGG_Spine node];
//		stepTest.debugMode = YES;
		[stepTest skeletonFromFileNamed:@"simpleAnimation" andAtlasNamed:@"stepTesting" andUseSkinNamed:nil];
		stepTest.position = CGPointMake(self.size.width/2, self.size.height/2);
		[stepTest runAnimation:@"curved" andCount:-1];
		stepTest.zPosition = 10;
		[self addChild:stepTest];
		



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
	CGPoint location = [[touches anyObject] locationInNode:self];
	[self inputBegan:location];
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	CGPoint location = [[touches anyObject] locationInNode:self];
	[self inputMoved:location];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	CGPoint location = [[touches anyObject] locationInNode:self];
	[self inputEnded:location];
}


#else

-(void)mouseDown:(NSEvent *)theEvent {
     /* Called when a mouse click occurs */
    
    CGPoint location = [theEvent locationInNode:self];
	[self inputBegan:location];

}

-(void)mouseDragged:(NSEvent *)theEvent {
    CGPoint location = [theEvent locationInNode:self];
	[self inputMoved:location];

}

-(void)mouseUp:(NSEvent *)theEvent {
	CGPoint location = [theEvent locationInNode:self];
	[self inputEnded:location];

}

-(void)keyDown:(NSEvent *)theEvent {
	
	NSString *characters = [theEvent characters];
	if ([characters length]) {
		for (int s = 0; s<[characters length]; s++) {
			unichar character = [characters characterAtIndex:s];
			switch (character) {
				case ' ':{
					if (![[boy.currentAnimationSequence objectAtIndex:0] isEqualToString:@"jump"]) {
						[boy runAnimation:@"jump" andCount:0 withSpeedFactor:1 withIntroPeriodOf:0.1 andUseQueue:YES];
					}
					
				}
					break;
				case 'a': boy.xScale = -1;
					break;
				case 'd':boy.xScale = 1;
					break;
			}
		}
	}
	
	
	
}

#endif


-(void)inputBegan:(CGPoint)location {

	startLocation = location;
	
	//[goblin changeSkinTo:@"goblin"];
	[elf runAnimation:@"trip" andCount:0 withSpeedFactor:1 withIntroPeriodOf:0.1 andUseQueue:YES];
    
    NSDictionary* partReplacement = @{@"torso": @"goblin-torso", @"head": @"goblin-head"};
    
    NSArray* partsToColorize = @[@"head", @"left shoulder", @"torso"];
    SKColor* color = [SKColor redColor];
	
    [goblin changeSkinPartial:partReplacement];
    [boy colorizeSlots:partsToColorize withColor:color andIntensity:1];

	
	
//	[stepTest runAnimation:@"animation" andCount:-1];

	
	//NSValue testing
	/*
	CGFloat xa = arc4random() % 100;
	CGFloat xb = arc4random() % 100;
	CGFloat ya = arc4random() % 100;
	CGFloat yb = arc4random() % 100;
	
	xb = xb / 100;
	yb = yb / 100;
	
	CGFloat x = xa + xb;
	CGFloat y = ya + yb;
	
	bool xc = arc4random() % 2;
	bool yc = arc4random() % 2;
	
	if (xc) {
		x *= -1;
	}
	if (yc) {
		y *= -1;
	}
	
	[[[SGG_SpineBoneAction alloc] init] addTranslationAtTime:0 withPoint:CGPointMake(x, y) andCurveInfo:@[@"1.2, 2.1"]];*/
	
}

-(void)inputMoved:(CGPoint)location {

	if (location.y > startLocation.y + 20) {
		if (![boy.currentAnimationSequence[0] isEqualToString:@"jump"]) {
			[boy runAnimation:@"jump" andCount:0 withSpeedFactor:1 withIntroPeriodOf:0.1 andUseQueue:YES];
		}
	}
	
	if (location.x > startLocation.x + 20) {
		boy.xScale = 1;
	} else if (location.x < startLocation.x -20) {
		boy.xScale = -1;
	}

	
}

-(void)inputEnded:(CGPoint)location {

	//[goblin changeSkinTo:@"goblingirl"];
    
    [goblin resetSkinPartial];
    
    //reset the colors
	[boy resetColorizedSlots];
    
    //[goblin resetSkeleton];
	
}



-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
//	CFTimeInterval before = CFAbsoluteTimeGetCurrent();
	[stepTest activateAnimations];
//	CFTimeInterval after = CFAbsoluteTimeGetCurrent();
//	CFTimeInterval elapsed = after - before;
//	NSLog(@"elapsed: %f", elapsed);
//	SKNode* bone = [stepTest findBoneNamed:@"bone"];
//	if (CGPointEqualToPoint(bone.position, ballPosition)) {
//		NSLog(@"1");
//	} else {
//		NSLog(@"0");
//		ballPosition = bone.position;
//	}
}





@end
