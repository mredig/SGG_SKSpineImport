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
	
	BOOL enabled;
	
}

@end

@implementation SGG_MyScene {

}

static const BOOL tryAlternativeQueuingMethods = YES;

-(id)initWithSize:(CGSize)size {
	if (self = [super initWithSize:size]) {
		/* Setup your scene here */

        boy = [SGG_Spine node];
        [boy skeletonFromFileNamed:@"spineboy" andAtlasNamed:@"spineboy" andUseSkinNamed:Nil];
        boy.position = CGPointMake(self.size.width/4, self.size.height/4);
        if (tryAlternativeQueuingMethods) {
            [boy enqueueIndefiniteAnimation:@"walk"];   // walk indefinitely
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [boy enqueueAnimation:@"jump"];         // jump once, and then continue walking
            });
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [boy enqueueAnimations:@[@"jump", @"walk", @"jump", @"jump"]];         // try a sequence of animations, and then continue walking
            });
        } else {
//            boy.debugMode = YES;
//            boy.timeResolution = 1.0 / 1200.0; // this is typically overkill, 1/120 will normally be MORE than enough, but this demo can go to some VERY slow motion. 1/120 is also the default.
//            [boy runAnimationSequence:@[@"walk", @"jump", @"walk", @"walk", @"jump"] andUseQueue:NO]; //uncomment to see how a sequence works (commment the other animation calls)
            boy.queuedAnimation = @"walk";
            boy.name = @"boy";
            boy.queueIntro = 0.1;
            [boy runAnimation:@"walk" andCount:0 withIntroPeriodOf:0.1 andUseQueue:YES];
        }
		boy.zPosition = 0;
		[self addChild:boy];

		
		
		elf = [SGG_Spine node];
		[elf skeletonFromFileNamed:@"elf" andAtlasNamed:@"elf" andUseSkinNamed:Nil];
		elf.position = CGPointMake(self.size.width/2, self.size.height/4);
		[elf runAnimation:@"standing" andCount:-1];
		elf.queuedAnimation = @"standing";
		elf.queueIntro = 0.1;
		elf.zPosition = 20;
		elf.xScale = 0.6;
		elf.yScale = 0.6;
		[self addChild:elf];

		
		goblin = [SGG_Spine node];
//		goblin.debugMode = YES;
		[goblin skeletonFromFileNamed:@"goblins" andAtlasNamed:@"goblin" andUseSkinNamed:@"goblin"];
		goblin.position = CGPointMake((self.size.width/4)*3, self.size.height/4);
		[goblin runAnimation:@"walk" andCount:-1];
		goblin.zPosition = 10;
		[self addChild:goblin];
		

		



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
		
		SKLabelNode* label4 = [SKLabelNode labelNodeWithFontNamed:@"Helvetica Neue Light"];
		label4.text = @"\"j\", \"k\", and \"l\" to change playback speed for boy";
		label4.color = [SKColor whiteColor];
		label4.position = CGPointMake(self.size.width/2, label3.position.y - 30);
		[self addChild:label4];
		
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
                    if (tryAlternativeQueuingMethods) {
                        [boy enqueueAnimation:@"jump"];         // jump once, and then continue walking
                    } else {
                        if (![boy.currentAnimation isEqualToString:@"jump"]) {
                            [boy runAnimation:@"jump" andCount:0 withIntroPeriodOf:0.1 andUseQueue:YES];
                        }
                    }
					
				}
					break;
				case 'a': boy.xScale = -1;
					break;
				case 'd':boy.xScale = 1;
					break;
				case 's':[boy stopAnimation];
					break;
				case 'w':[boy runAnimation:@"walk" andCount:0 withIntroPeriodOf:0.1 andUseQueue:YES];
					break;
				case 'l':boy.playbackSpeed += 0.05;
					break;
				case 'j':boy.playbackSpeed -= 0.05;
					break;
				case 'k':boy.playbackSpeed = 1;
					break;
			}
		}
	}
	
	
	
}

#endif


-(void)inputBegan:(CGPoint)location {

	startLocation = location;
	
	[elf runAnimation:@"trip" andCount:0 withIntroPeriodOf:0.1 andUseQueue:YES];
	

	
	NSArray* partsToColorize = @[@"head", @"left shoulder", @"torso"];
	SKColor* color = [SKColor redColor];

	[goblin changeSkinTo:@"goblingirl"];
	[boy colorizeSlots:partsToColorize withColor:color andIntensity:1];
	
	[goblin colorizeAllSlotsWithColor:[SKColor blueColor] andIntensity:0.8];
/*
//this section is a correct example of partial texture replacement
	NSDictionary* partReplacement = @{@"torso": @"goblin-torso", @"head": @"goblin-head"};

	[goblin changeTexturePartial:partReplacement];
*/
	
/*
 //this section is a correct example of partial skin replacement

	NSDictionary* skinReplacement = @{@"torso": @"goblingirl", @"head": @"goblingirl", @"eyes": @"goblingirl"};
	[goblin changeSkinPartial:skinReplacement];
	
*/



	
}

-(void)inputMoved:(CGPoint)location {

	if (location.y > startLocation.y + 20) {
		if (![boy.currentAnimationSequence[0] isEqualToString:@"jump"]) {
			[boy runAnimation:@"jump" andCount:0 withIntroPeriodOf:0.1 andUseQueue:YES];
		}
	}
	
	if (location.x > startLocation.x + 20) {
		boy.xScale = 1;
	} else if (location.x < startLocation.x -20) {
		boy.xScale = -1;
	}

	
}

-(void)inputEnded:(CGPoint)location {

	[goblin changeSkinTo:@"goblin"];
	
//	[goblin resetSkinPartial];
	[goblin resetTexturePartial];
	
	//reset the colors
	[boy resetColorizedSlots];
	[goblin resetColorizedSlots];
	
	//[goblin resetSkeleton];
	
}



-(void)update:(CFTimeInterval)currentTime {
	/* Called before each frame is rendered */
	
	//each spine object must be "activated" here to playback their animation
	[goblin activateAnimations];
	[boy activateAnimations];
	[elf activateAnimations];

	
}


@end
