//
//  SGG_SKUtilities.h
//
//  Created by Michael Redig on 1/1/14.
//  Copyright (c) 2014 Michael Redig. All rights reserved.
//
// v 1.2

//#import "TestFlight.h"



#import "SKUtilityConstants.h"

@interface SGG_SKUtilities : NSObject


@property (nonatomic, readonly) CGFloat radiansToDegreesConversionFactor;
@property (nonatomic, readonly) CGFloat degreesToRadiansConversionFactor;


@property (nonatomic, readonly) CFTimeInterval currentTime;
@property (nonatomic, readonly) CFTimeInterval deltaFrameTime;





+(SGG_SKUtilities*) sharedUtilities;


#pragma mark DISTANCE FUNCTIONS

-(CGFloat)distanceBetween:(CGPoint)pointA and: (CGPoint)pointB; //returns distance between two points
-(BOOL)distanceBetweenPointA:(CGPoint)pointA andPointB:(CGPoint)pointB isWithinXDistance:(CGFloat)distance; //returns boolean of whether two points are within a specified distance
-(BOOL)distanceBetweenPointA:(CGPoint)pointA andPointB:(CGPoint)pointB isWithinXDistancePreSquared:(CGFloat)distanceSquared; //returns boolean of whether two points are within a specified distance that is presquared for a bit more cpu efficiency

#pragma mark ORIENTATION
-(CGFloat) orientTo:(CGPoint)point1 from:(CGPoint)point2; //returns radians for angle between two points
-(CGFloat) angleBetween:(CGPoint)point1 from:(CGPoint)point2; //returns radians for angle between two points (newer formula with a 90 degree compensation)


#pragma mark CGVector HELPERS
-(CGVector)vectorFromCGPoint:(CGPoint)point; //just converts variable formats
-(CGVector)vectorInverse:(CGVector)vector;
-(CGVector)vectorNormalize:(CGVector)vector; //returns a vector with a unit length of 1.0
-(CGVector)vectorAddA:(CGVector)vectorA toVectorB:(CGVector)vectorB andNormalize:(BOOL)normalize; //adds two vectors together with option to normalize
-(CGVector)vectorSubtractA:(CGVector)vectorA fromVectorB:(CGVector)vectorB andNormalize:(BOOL)normalize; //subtracts two vectors with option to normalize
-(CGVector)vectorFacingPoint:(CGPoint)destination fromPoint:(CGPoint)origin andNormalize:(BOOL)normalize; //calculates a vector between two points with option to normalize
-(CGVector)vectorFromRadianAngle:(CGFloat)angle; //converts an angle in radians to a normal vector
-(CGVector)vectorFromDegreeAngle:(CGFloat)degrees; //converts an angle in degrees to a normal vector

	
#pragma mark CGPoint HELPERS
-(CGPoint)pointFromCGVector:(CGVector)vector; //just converts variable formats
-(CGPoint)pointInverse:(CGPoint)point;
-(CGPoint)pointAddA:(CGPoint)pointA toPointB:(CGPoint)pointB; //adds two points together (x+x, y+y)
-(CGPoint)pointStepFromPoint:(CGPoint)origin withVector:(CGVector)vector vectorIsNormal:(BOOL)vectorIsNormal withFrameInterval:(CFTimeInterval)interval andMaxInterval:(CGFloat)maxInterval withSpeed:(CGFloat)speed andSpeedModifiers:(CGFloat)speedModifiers; //calculates where a new position should be relative to current position based on environmental variables
-(CGPoint)pointStepFromPoint:(CGPoint)origin towardsPoint:(CGPoint)destination withFrameInterval:(CFTimeInterval)interval andMaxInterval:(CGFloat)maxInterval withSpeed:(CGFloat)speed andSpeedModifiers:(CGFloat)speedModifiers; //calculates where a new position should be to move towards destination based on environmental variables
-(BOOL)nodeAtPoint:(CGPoint)originPos isBehindNodeAtPoint:(CGPoint)victimPos facingVector:(CGVector)victimFacingVector isVectorNormal:(BOOL)victimFacingVectorNormal withLatitudeOf:(CGFloat)latitude andMaximumDistanceBetweenPoints:(CGFloat)maxDistance; //returns boolean whether or not a backstab would be valid given parameters. Latitude is range from 0 to 1.0. 0.5 would give a valid range of about 45 degrees to backstab
-(BOOL)nodeAtPoint:(CGPoint)originPos isBehindNodeAtPoint:(CGPoint)victimPos facingVector:(CGVector)victimFacingVector isVectorNormal:(BOOL)victimFacingVectorNormal withLatitudeOf:(CGFloat)latitude; //returns boolean whether or not a backstab would be valid given parameters (see above) this assumes that distance logic has already occurred and simply returns whether the angles are valid


#pragma mark COORDINATE CONVERSIONS
-(CGPoint)getCGPointFromString:(NSString*)string; //converts a properly formatted string to a CGPoint (typically for reading storage)
-(NSString*)getStringFromPoint:(CGPoint)location; //converts a CGPoing value to a properly formatted string (typically for storage)



#pragma mark TIME HANDLERS
-(void)updateCurrentTime:(CFTimeInterval)timeUpdate; //call this from the update method in the current scene
-(NSDictionary*)calculateDurationsFromSeconds:(CFTimeInterval)seconds; //returns a dictionary with CGFloat values converting seconds to minutes, hours, days, weeks, and years (5122435 seconds = 85373.917 minutes = 1422.8986 hours = 59.287442 days = 8.4696346 weeks = 0.16232017 years)
-(NSDictionary*)parseDurationsFromSeconds:(CFTimeInterval)seconds; //returns a dictionary with a total value of the same duration of its seconds input, parsing minutes, hours, days, weeks, and years (93673.26 seconds = 0 years, 0 weeks, 1 day, 2 hours, 1 minute, and 13.26 seconds) ALSO NOTE: THIS DOES NOT WORK YET

	
#pragma mark MISC
-(CGFloat)rampToValue:(CGFloat)idealValue fromCurrentValue:(CGFloat)currentValue withRampStep:(CGFloat)step; //ramps up or down to the ideal value from the current value. This is intended to be called from a repeating method and requires that currentValue remembers its previous value


@end
