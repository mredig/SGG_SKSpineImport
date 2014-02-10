//
//  SGG_SpineJSONReader.h
//  SpineTesting
//
//  Created by Michael Redig on 2/10/14.
//  Copyright (c) 2014 Secret Game Group LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Spine.h"

@interface SGG_SpineJSONTools : NSObject

-(NSDictionary*)readJSONFileNamed:(NSString*)name;

@end
