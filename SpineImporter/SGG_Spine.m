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
	[self createBonesFromArray:boneArray];
	
	NSDictionary* skinsDict = [NSDictionary dictionaryWithDictionary:[spineDict objectForKey:@"skins"]];
	[self attachSkinsToBonesFromDict:skinsDict];
	

	
}


-(void)createBonesFromArray:(NSArray*)boneArray{
	
	NSMutableArray* mutableBones = [[NSMutableArray alloc] init];
	for (int i = 0; i < boneArray.count; i++) {
		NSDictionary* boneDict = [NSDictionary dictionaryWithDictionary:[boneArray objectAtIndex:i]];
		SGG_SpineBone* bone = [SGG_SpineBone node];
		
		bone.position = CGPointMake([[boneDict objectForKey:@"x"] doubleValue], [[boneDict objectForKey:@"y"] doubleValue]);
		bone.length = [[boneDict objectForKey:@"length"] doubleValue];
		if ([boneDict objectForKey:@"scaleX"]) {
			bone.xScale = [[boneDict objectForKey:@"scaleX"] doubleValue];
		}
		
		if ([boneDict objectForKey:@"scaleY"]) {
			bone.yScale = [[boneDict objectForKey:@"scaleY"] doubleValue];

		}
		bone.zRotation = [[boneDict objectForKey:@"rotation"] doubleValue] * sharedUtilities.degreesToRadiansConversionFactor;
		bone.name = [boneDict objectForKey:@"name"];
		NSString* parent = [boneDict objectForKey:@"parent"];
		if (parent) {
			for (int h = 0; h < mutableBones.count; h++) {
				SGG_SpineBone* parentBone = (SGG_SpineBone*)[mutableBones objectAtIndex:h];
				if ([parentBone.name isEqualToString:parent]) {
					[parentBone addChild:bone];
				}
			}
		} else {
			[self addChild:bone];
		}
		if (_debugMode) {
			[bone debugWithLength];
		}
		
		[mutableBones addObject:bone];
//		NSLog(@"added bone: %@", bone);
	}
	
	_bones = [NSArray arrayWithArray:mutableBones];
	
	
}

-(void)attachSkinsToBonesFromDict:(NSDictionary*)skinsDict {



	
}

@end
