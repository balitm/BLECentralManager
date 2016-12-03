#import <TargetConditionals.h>

#if TARGET_OS_IOS
#import <UIKit/UIKit.h>
#elif TARGET_OS_MAC
#import <Cocoa/Cocoa.h>
#endif

FOUNDATION_EXPORT double BLECentralManagerVersionNumber;
FOUNDATION_EXPORT const unsigned char BLECentralManagerVersionString[];