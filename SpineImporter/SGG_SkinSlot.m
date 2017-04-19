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
        self.animations = [[NSMutableDictionary alloc] init];
        self.skins = [[NSMutableDictionary alloc] init];
    }
    return self;
}

-(void)changeSkinTo:(NSString*)skin {
    
    [self enumerateChildNodesWithName:@"*" usingBlock:^(SKNode *node, BOOL *stop) {
        [node removeFromParent];
    }];
    
    NSDictionary* currentSkin = self.skins[skin];
    if (!currentSkin) {
        currentSkin = self.skins[@"default"];
    }
    NSArray* attachments = [currentSkin allKeys];
    for (NSString* attachment in attachments) {
        SGG_SkinSprite* sprite = currentSkin[attachment];
        [self addChild:sprite];
        sprite.hidden = HIDDEN;
    }
    
    [self setAttachmentTo:self.currentAttachment];
}

-(void)setAttachmentTo:(NSString*)attachmentName {
    
    if (!attachmentName) {
        attachmentName = self.defaultAttachment;
    }
    
    [self enumerateChildNodesWithName:@"*" usingBlock:^(SKNode *node, BOOL *stop) {
        if ([node.name isEqualToString:attachmentName]) {
            node.hidden = VISIBLE;
        } else {
            node.hidden = HIDDEN;
        }
    }];
    self.currentAttachment = attachmentName;
    
}

-(void)setVisibleState:(CGFloat)alphaValue {
    [self enumerateChildNodesWithName:@"*" usingBlock:^(SKNode * _Nonnull node, BOOL * _Nonnull stop) {
        node.alpha = alphaValue;
    }];
}

-(void)setDrawOrder:(CGFloat)drawOrder {
    [self enumerateChildNodesWithName:@"*" usingBlock:^(SKNode * _Nonnull node, BOOL * _Nonnull stop) {
        node.zPosition = self.defaultDrawOrder + drawOrder;
    }];
}

-(void)setToDefaultAttachment {
    
    [self setAttachmentTo:self.defaultAttachment];
    
}

-(void)removeAllActions {
    [super removeAllActions];
    
    self.currentAnimation = nil;
    
}

-(void)stopAnimation {
    
    [self playAnimations:nil];
    
}

-(NSInteger)playAnimations:(NSArray *)animationNames {
    NSInteger maxFrameCount = 0;
    
    
    self.currentAnimation = nil;
    if (!animationNames) {
        return maxFrameCount;
    }
    
    NSMutableArray* sequentialAnimations = [[NSMutableArray alloc] init];
    for (int i = 0; i < animationNames.count; i++) {
        SGG_SpineBoneAction* action = self.animations[animationNames[i]];
        
        maxFrameCount += (NSInteger)(action.totalLength / action.timeFrameDelta);
        
        
        NSMutableArray* tempAnimationArray = [NSMutableArray arrayWithArray:action.animation];
        
        while (sequentialAnimations.count + tempAnimationArray.count > maxFrameCount) {
            [tempAnimationArray removeObjectAtIndex:0];
        }
        
        
        [sequentialAnimations addObjectsFromArray:tempAnimationArray];
    }
    self.currentAnimation = [NSArray arrayWithArray:sequentialAnimations];
    
    return maxFrameCount;
}

-(BOOL)updateAnimationAtFrame:(NSInteger)currentFrame {
    if (self.currentAnimation && self.currentAnimation.count ) {
        
        if (currentFrame >= self.currentAnimation.count) {
            currentFrame = self.currentAnimation.count - 1;
        }
        NSDictionary* thisFrameDict = self.currentAnimation[currentFrame];
        
        NSString *attachment = thisFrameDict[@"attachmentName"];
        NSNumber *alphaValue = thisFrameDict[@"alpha"];
        NSNumber *offset = thisFrameDict[@"offset"];
        [self setAttachmentTo:attachment];
        [self setVisibleState:[alphaValue floatValue]];
        if (offset) {
            [self setDrawOrder:[offset floatValue]];
        }
        
    }
    
    return NO;
}

@end
