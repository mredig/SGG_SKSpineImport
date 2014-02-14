//
//  SGG_Spine.h
//  SpineTesting
//
//  Created by Michael Redig on 2/10/14.
//  Copyright (c) 2014 Secret Game Group LLC. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import "SpineImport.h"

typedef enum {
	kSGG_SpineAnimationTypeBone,
	kSGG_SpineAnimationTypeDrawOrder,
	kSGG_SpineAnimationTypeSlots
} kSGG_SpineAnimationType;

@interface SGG_Spine : SKNode

@property (nonatomic, assign) BOOL debugMode;

@property (nonatomic, strong) NSArray* bones;
@property (nonatomic, strong) NSMutableDictionary* skins;
@property (nonatomic, strong) NSDictionary* animations;

@property (nonatomic, assign) NSString* currentSkin;

-(void)skeletonFromFileNamed:(NSString*)name andAtlasNamed:(NSString*)atlasName;
-(void)runAnimation:(NSString*)animationName andCount:(NSInteger)count;



@end
