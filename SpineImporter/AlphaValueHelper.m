//
//  AlphaValueHelper.m
//  SpineTesting
//
//  Created by Sebastian Homscheidt on 09.03.17.
//  Copyright © 2017 RockAByte GmbH. All rights reserved.
//

#import "AlphaValueHelper.h"

#import "SpineImport.h"

@implementation AlphaValueHelper

+(CGFloat)getAlphaValueFromColorString:(NSString*)colorString {
    if (colorString.length == 6) {
        //case alpha is omitted
        return ALPHA_VALUE_DEFAULT;
    }else {
        NSString *alphaString = [self getAlphaStringFromColorString:colorString];
        return [self getMappedAlphaValueFromAlphaString:alphaString];
    }
}

+(NSString*)getAlphaStringFromColorString:(NSString*)colorString {
    NSString *alphaString = [colorString substringFromIndex:6];
    return alphaString;
}

+(CGFloat)getMappedAlphaValueFromAlphaString:(NSString*)alphaValueString{
    unsigned alphaValue = 0;
    
    NSScanner *scanner = [NSScanner scannerWithString:alphaValueString];
    [scanner scanHexInt:&alphaValue];
    
    return ((CGFloat)alphaValue) / 255.0f;
}


@end
