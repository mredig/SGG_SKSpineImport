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
		
	}
	return self;
}

-(void)setAttachmentTo:(NSString*)attachmentName {
	
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

-(void)playAnimations:(NSArray *)animationNames {
	
}

-(void)updateAnimationAtFrame:(NSInteger)currentFrame {
	
}

@end
