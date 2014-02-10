//
//  SGG_SpineJSONReader.m
//  SpineTesting
//
//  Created by Michael Redig on 2/10/14.
//  Copyright (c) 2014 Secret Game Group LLC. All rights reserved.
//

#import "SGG_SpineJSONTools.h"

@implementation SGG_SpineJSONTools

-(id)init {
	if (self = [super init]) {
		
	}
	return self;
}

-(NSDictionary*)readJSONFileNamed:(NSString *)name {
	
	NSURL* fileURL = [[NSBundle mainBundle] URLForResource:name withExtension:@"json"];
	NSData* jsonData = [NSData dataWithContentsOfURL:fileURL];
	NSDictionary* jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
		
	return jsonDict;
}

@end
