//
//  SGG_SkinSlot.m
//  SpineTesting
//
//  Created by Michael Redig on 2/10/14.
//  Copyright (c) 2014 Secret Game Group LLC. All rights reserved.
//

#import "SGG_SkinSlot.h"
#import "SpineImport.h"

@implementation SGG_SkinSlot

-(id)init {
	if (self = [super init]) {
		_animations = [[NSMutableDictionary alloc] init];
		_skins = [[NSMutableDictionary alloc] init];
	}
	return self;
}

-(void)changeSkinTo:(NSString*)skin {
	
	
	
}

-(void)setAttachmentTo:(NSString*)attachmentName {
	
	if (!attachmentName) {
		attachmentName = _defaultAttachment;
	}
	
	[self enumerateChildNodesWithName:@"*" usingBlock:^(SKNode *node, BOOL *stop) {
		if ([node.name isEqualToString:attachmentName]) {
			node.hidden = VISIBLE;
		} else {
			node.hidden = HIDDEN;
		}
	}];
	_currentAttachment = attachmentName;
	
}

-(void)setToDefaultAttachment {
	
	[self setAttachmentTo:_defaultAttachment];

}

-(void)removeAllActions {
	[super removeAllActions];
	
	_currentAnimation = nil;
	
}

-(void)playAnimations:(NSArray *)animationNames {
	NSInteger maxFrameCount = 0;
	

	_currentAnimation = nil;
	NSMutableArray* sequentialAnimations = [[NSMutableArray alloc] init];
	for (int i = 0; i < animationNames.count; i++) {
		SGG_SpineBoneAction* action = _animations[animationNames[i]];
		maxFrameCount += (NSInteger)(action.totalLength / action.timeFrameDelta);
		

		NSMutableArray* tempAnimationArray = [NSMutableArray arrayWithArray:action.animation];
		
		while (sequentialAnimations.count + tempAnimationArray.count > maxFrameCount) {
			[tempAnimationArray removeObjectAtIndex:0];
		}
		
		
		[sequentialAnimations addObjectsFromArray:tempAnimationArray];
	}
	_currentAnimation = [NSArray arrayWithArray:sequentialAnimations];
	

}

-(void)updateAnimationAtFrame:(NSInteger)currentFrame {
	
	if (_currentAnimation && _currentAnimation.count ) {
		
		
		if (currentFrame >= _currentAnimation.count) {
			currentFrame = _currentAnimation.count - 1;
		}
		NSDictionary* thisFrameDict = _currentAnimation[currentFrame];

		NSString* attachment = thisFrameDict[@"attachmentName"];
		
		[self setAttachmentTo:attachment];
		
		if ([self.name isEqualToString:@"eyes"]) {
			NSLog(@"current attachment: %@", attachment);
		}
		
	}
	
}

@end
