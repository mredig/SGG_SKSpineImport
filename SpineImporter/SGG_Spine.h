//
//  SGG_Spine.h
//  SpineTesting
//
//  Created by Michael Redig on 2/10/14.
//  Copyright (c) 2014 Secret Game Group LLC. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import "SpineImport.h"

@interface SGG_Spine : SKNode

@property (nonatomic, assign) BOOL debugMode;

@property (nonatomic, strong) NSArray* bones;
@property (nonatomic, strong) NSDictionary* skins;



-(void)skeletonFromFileNamed:(NSString*)name andAtlasNamed:(NSString*)atlasName;



@end
