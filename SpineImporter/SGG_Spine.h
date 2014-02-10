//
//  SGG_Spine.h
//  SpineTesting
//
//  Created by Michael Redig on 2/10/14.
//  Copyright (c) 2014 Secret Game Group LLC. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import "Spine.h"

@interface SGG_Spine : SKNode

@property (nonatomic, strong) NSArray* bones;



-(void)skeletonFromFileNamed:(NSString*)name;



@end
