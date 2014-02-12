//
//  SGG_SpineSkins.h
//  SpineTesting
//
//  Created by Michael Redig on 2/10/14.
//  Copyright (c) 2014 Secret Game Group LLC. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface SGG_SpineSkin : SKNode

@property (nonatomic, assign) NSString* defaultSkin;
@property (nonatomic, strong) NSMutableDictionary* skinSlotsDictionary;

@end
