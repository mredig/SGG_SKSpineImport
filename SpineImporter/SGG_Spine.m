//
//  SGG_Spine.m
//  SpineTesting
//
//  Created by Michael Redig on 2/10/14.
//  Copyright (c) 2014 Secret Game Group LLC. All rights reserved.
//

#import "SGG_Spine.h"
#import "SGG_SpineJSONTools.h"

@interface SGG_Spine () {
	
	SGG_SKUtilities* sharedUtilities;
}

@end

@implementation SGG_Spine

-(id)init {
	
	if (self = [super init]) {
		sharedUtilities = [SGG_SKUtilities sharedUtilities];
			
	}
	return self;
}

-(void)skeletonFromFileNamed:(NSString*)name {
	SGG_SpineJSONTools* tools = [[SGG_SpineJSONTools alloc]init];
	NSDictionary* spineDict = [tools readJSONFileNamed:name];
	
	NSArray* boneArray = [NSArray arrayWithArray:[spineDict objectForKey:@"bones"]];
	[self createSkeletonFromDict:boneArray];
	
}


-(void)createSkeletonFromDict:(NSArray*)boneArray{
	
	NSMutableArray* mutableBones = [[NSMutableArray alloc] init];
	for (int i = 0; i < boneArray.count; i++) {
		NSDictionary* boneDict = [NSDictionary dictionaryWithDictionary:[boneArray objectAtIndex:i]];
		SGG_SpineBone* bone = [SGG_SpineBone node];
		
		bone.position = CGPointMake([[boneDict objectForKey:@"x"] doubleValue], [[boneDict objectForKey:@"y"] doubleValue]);
		bone.length = [[boneDict objectForKey:@"length"] doubleValue];
		bone.xScale = [[boneDict objectForKey:@"scaleX"] doubleValue];
		bone.yScale = [[boneDict objectForKey:@"scaleY"] doubleValue];
		bone.zRotation = [[boneDict objectForKey:@"rotation"] doubleValue] * sharedUtilities.degreesToRadiansConversionFactor;
		bone.name = [boneDict objectForKey:@"name"];
		[self addChild:bone];
		[mutableBones addObject:bone];
		NSLog(@"added bone named %@: %@", bone.name, bone);
	}
	
	_bones = [NSArray arrayWithArray:mutableBones];
	
	
	
}

@end
