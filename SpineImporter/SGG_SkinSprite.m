//
//  SGG_SkinSprite.m
//  SpineTesting
//
//  Created by Michael Redig on 2/10/14.
//  Copyright (c) 2014 Secret Game Group LLC. All rights reserved.
//

#import "SGG_SkinSprite.h"

@implementation SGG_SkinSprite
- (id)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}




-(void)setDefaults {
	
	_defaultPosition = self.position;
	_defaultRotation = self.zRotation;
	_defaultScaleX = self.xScale;
	_defaultScaleY = self.yScale;
	_defaultSize = _sizeFromJSON;
}

-(void)setToDefaults {
	
	self.position = _defaultPosition;
	self.zRotation = _defaultRotation;
	self.xScale = _defaultScaleX;
	self.yScale = _defaultScaleY;
	_sizeFromJSON = _defaultSize;
	
}



@end
