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
        _animations = [[NSMutableDictionary alloc] init];
    }
    return self;
}

-(void)debugWithLength{
    
    SKSpriteNode* sprite = [SKSpriteNode spriteNodeWithColor:[SKColor redColor] size:CGSizeMake(5, _length)];
    sprite.anchorPoint = CGPointMake(0.5, 0);
    sprite.zRotation = -M_PI_2;
    sprite.zPosition = 1000;
    [self addChild:sprite];
    
}


-(void)setDefaultsAndBase {
    
    _defaultPosition = self.position;
    _defaultRotation = self.zRotation;
    _defaultScaleX = self.xScale;
    _defaultScaleY = self.yScale;
    _basePosition = self.position;
    _baseRotation = self.zRotation;
    _baseScaleX = self.xScale;
    _baseScaleY = self.yScale;
    
}

-(void)setToDefaults {
    
    self.position = _defaultPosition;
    self.zRotation = _defaultRotation;
    self.xScale = _defaultScaleX;
    self.yScale = _defaultScaleY;
    _basePosition = self.position;
    _baseRotation = self.zRotation;
    _baseScaleX = self.xScale;
    _baseScaleY = self.yScale;
}

-(NSInteger)playAnimations:(NSArray*)animationNames {
    
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
    
    //	NSLog(@"setting current animation: %@", _currentAnimation);
    
    return maxFrameCount;
    
}

-(void)removeAllActions {
    [super removeAllActions];
    
    self.currentAnimation = nil;
    
}

-(void)stopAnimation {
    
    [self playAnimations:nil];
    
}

-(void)updateAnimationAtFrame:(NSInteger)currentFrame {
    
    if (self.currentAnimation && self.currentAnimation.count ) {
        
        //		CGFloat prev = self.zRotation;
        
        if (currentFrame >= self.currentAnimation.count) {
            currentFrame = self.currentAnimation.count - 1;
        }
        NSDictionary* thisFrameDict = self.currentAnimation[currentFrame];
        CGPoint offsetPos = [self pointFromValueObject:thisFrameDict[@"position"]];
        self.position = CGPointMake(self.basePosition.x + offsetPos.x, self.basePosition.y + offsetPos.y) ;
        self.zRotation = self.baseRotation + [thisFrameDict[@"rotation"] doubleValue];
        
        CGPoint newScale;
        if (thisFrameDict[@"scale"]) {
            newScale = [self pointFromValueObject:thisFrameDict[@"scale"]];
            
            self.xScale = self.baseScaleX * newScale.x;
            self.yScale = self.baseScaleY * newScale.y;
        } else {
            self.xScale = self.baseScaleX;
            self.yScale = self.baseScaleY;
        }
        
        //		if ([self.name isEqualToString:@"right shoulder"]) {
        //			NSLog(@"%@: rot: %f prev: %f dev: %f", self.name, self.zRotation, prev, self.zRotation - prev);
        //		}
        
    }
}

-(NSValue*)valueObjectFromPoint:(CGPoint)point {
#if TARGET_OS_IPHONE
    return [NSValue valueWithCGPoint:point];
#else
    return [NSValue valueWithPoint:point];
#endif
    
}

-(CGPoint)pointFromValueObject:(NSValue*)valueObject {
#if TARGET_OS_IPHONE
    return [valueObject CGPointValue];
#else
    return [valueObject pointValue];
#endif
    
}

-(BOOL)distanceBetweenPointA:(CGPoint)pointA andPointB:(CGPoint)pointB isWithinXDistance:(CGFloat)distance {
    
    CGFloat deltaX = pointA.x - pointB.x;
    CGFloat deltaY = pointA.y - pointB.y;
    
    return (deltaX * deltaX) + (deltaY * deltaY) <= distance * distance;
}

@end
