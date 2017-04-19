//#import "SGG_SKUtilities.h"
#import "SGG_Spine.h"
#import "SGG_SpineBone.h"
#import "SGG_SpineJSONTools.h"
#import "SGG_SkinSlot.h"
#import "SGG_SpineSkin.h"
#import "SGG_SkinSprite.h"


#define VISIBLE 0 //for node.hidden properties, this is more intuitive than YES/NO
#define HIDDEN 1 //for node.hidden properties, this is more intuitive than YES/NO

#define SPINE_DEGTORADFACTOR 0.017453292519943295 // pi/180
#define SPINE_RADTODEGFACTOR 57.29577951308232 // 180/pi

#define TIME_FRAME_DELTA_DEFAULT 1.0f/120.0f

#define TIME_VALUE_ZERO .0f

#define TRANSLATION_VALUE_DEFAULT 0.f
#define ROTATION_VALUE_DEFAULT 0.f
#define SCALE_VALUE_DEFAULT 1.0f
#define COLOR_VALUE_DEFAULT_RGBA @"FFFFFFFF"
#define COLOR_VALUE_DEFAULT_RGB @"FFFFFF"
#define ALPHA_VALUE_DEFAULT 1.0f

#define ATTACHMENT_NAME_EMPTY @""
