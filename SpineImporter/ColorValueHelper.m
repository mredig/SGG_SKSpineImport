//
//  ColorValueHelper.m
//  WorksheetCrafter
//
//  Created by Sebastian Homscheidt on 14.03.17.
//  Copyright © 2017 RockAByte GmbH. All rights reserved.
//

#import "ColorValueHelper.h"

#import "SpineImport.h"

@implementation ColorValueHelper

+(NSString*)getRGBStringFromRGBAString:(NSString*)rgbaString {
    if (!rgbaString) {
        //case color is omitted
        return COLOR_VALUE_DEFAULT_RGB;
    }
    if (rgbaString.length == 6) {
        //case alpha is omitted
        return rgbaString;
    }else {
        return [self getRGBStringFromString:rgbaString];
    }
}

+(NSString*)getRGBStringFromString:(NSString*)rgbaString {
    return [rgbaString substringToIndex:6];
}

@end
