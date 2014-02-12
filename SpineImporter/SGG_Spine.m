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
			_currentSkin = @"default";
	}
	return self;
}

-(void)skeletonFromFileNamed:(NSString*)name andAtlasNamed:(NSString*)atlasName{
	SGG_SpineJSONTools* tools = [[SGG_SpineJSONTools alloc]init];
	NSDictionary* spineDict = [tools readJSONFileNamed:name];
	
	NSArray* boneArray = [NSArray arrayWithArray:[spineDict objectForKey:@"bones"]];
	[self createBonesFromArray:boneArray];
	
	NSDictionary* skinsDict = [NSDictionary dictionaryWithDictionary:[spineDict objectForKey:@"skins"]];
	[self createSkinsFromDict:skinsDict andAtlasNamed:atlasName];
	
	NSArray* slotsArray = [NSArray arrayWithArray:[spineDict objectForKey:@"slots"]];
	[self setUpAttachmentsWithSlotsArray:slotsArray];
	
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
		[bone setDefaults];
		
		if (_debugMode) {
			[bone debugWithLength];
		}
		
		[mutableBones addObject:bone];
//		NSLog(@"added bone: %@", bone);
	}
	
	_bones = [NSArray arrayWithArray:mutableBones];
	
	
}

-(void)createSkinsFromDict:(NSDictionary*)skinsDict andAtlasNamed:(NSString*)atlasName{
	SKTextureAtlas* atlas = [SKTextureAtlas atlasNamed:atlasName];

	_skins = [[NSMutableDictionary alloc] init];
//get all skins
	NSArray* skinKeys = [skinsDict allKeys];
	
//	NSLog(@"skinKeys: %@", skinKeys);
	for (int i = 0; i < skinKeys.count; i++) {
		SGG_SpineSkin* skin = [SGG_SpineSkin node];
		skin.name = [skinKeys objectAtIndex:i];

		skin.skinSlotsDictionary = [[NSMutableDictionary alloc] init];
		//pull in texture atlas
		
		//get all skin slots
		NSDictionary* skinSlots = [NSDictionary dictionaryWithDictionary:[skinsDict objectForKey:skin.name]];
		NSArray* skinSlotNames = [skinSlots allKeys];
//		NSLog(@"skinSlotNames: %@", skinSlotNames);

		for (int h = 0; h < skinSlotNames.count; h++) {
			SGG_SkinSlot* skinSlot = [SGG_SkinSlot node];
			skinSlot.name = [skinSlotNames objectAtIndex:h];
			// get all skin sprites

			NSDictionary* skinSprites = [NSDictionary dictionaryWithDictionary:[skinSlots objectForKey:skinSlot.name]];
			NSArray* skinSpriteNames = [skinSprites allKeys];
//			NSLog(@"skinSpriteNames: %@", skinSpriteNames);
			for (int j = 0; j < skinSpriteNames.count; j++) {
			
				NSString* spriteString = [skinSpriteNames objectAtIndex:j];
				NSDictionary* spriteDict = [NSDictionary dictionaryWithDictionary:[skinSprites objectForKey: spriteString]];
				SGG_SkinSprite* skinSprite = [SGG_SkinSprite spriteNodeWithTexture:[atlas textureNamed:spriteString]];
				skinSprite.name = spriteString;
				if ([spriteDict objectForKey:@"name"]) {
					skinSprite.actualAttachmentName = [spriteDict objectForKey:@"name"];
				} else {
					skinSprite.actualAttachmentName = skinSprite.name;
				}
				
				skinSprite.position = CGPointMake([[spriteDict objectForKey:@"x"] doubleValue], [[spriteDict objectForKey:@"y"] doubleValue]);
				if ([spriteDict objectForKey:@"scaleX"]) {
					skinSprite.xScale = [[spriteDict objectForKey:@"scaleX"] doubleValue];
				}
				
				if ([spriteDict objectForKey:@"scaleY"]) {
					skinSprite.yScale = [[spriteDict objectForKey:@"scaleY"] doubleValue];
				}
				skinSprite.zRotation = [[spriteDict objectForKey:@"rotation"] doubleValue] * sharedUtilities.degreesToRadiansConversionFactor;
				skinSprite.sizeFromJSON = CGSizeMake([[spriteDict objectForKey:@"width"] doubleValue], [[spriteDict objectForKey:@"height"] doubleValue]);
				
				[skinSprite setDefaults];
				skinSprite.hidden = HIDDEN;
				[skinSlot addChild:skinSprite];
			}
//			[skin addChild:skinSlot];
			[skin.skinSlotsDictionary setObject:skinSlot forKey:skinSlot.name];
		}
//		NSLog(@"skinSlotsDictionary: %@", skin.skinSlotsDictionary);
//		[self addChild:skin];
		[_skins setObject:skin.skinSlotsDictionary forKey:skin.name];
	}



	
}

-(void)setUpAttachmentsWithSlotsArray:(NSArray*)slotsArray {
	
	NSDictionary* skinDict = [_skins objectForKey:_currentSkin];
	
//	NSLog(@"skinDict: %@", skinDict);
		
	for (int i = 0; i < slotsArray.count; i++) {
		NSDictionary* slotDict = [NSDictionary dictionaryWithDictionary:[slotsArray objectAtIndex:i]];
		NSString* attachment = [slotDict objectForKey:@"attachment"]; //image name
		NSString* boneString = [slotDict objectForKey:@"bone"];
		NSString* name = [slotDict objectForKey:@"name"];
				
		SGG_SkinSlot* skinSlot = (SGG_SkinSlot*)[skinDict objectForKey:name];
		skinSlot.zPosition = i * 0.1;
		
		for (int b = 0; b < _bones.count; b++) {
			SGG_SpineBone* bone = (SGG_SpineBone*)[_bones objectAtIndex:b];
			if ([bone.name isEqualToString:boneString]) {
				[bone addChild:skinSlot];
			}
		}
		[skinSlot enumerateChildNodesWithName:attachment usingBlock:^(SKNode *node, BOOL *stop) {
			node.hidden = VISIBLE;
		}];
		
		
	}

	
}


@end
