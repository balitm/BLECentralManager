#import <TargetConditionals.h>

#if TARGET_OS_IOS
#import <UIKit/UIKit.h>
#elif TARGET_OS_MAC
#import <Cocoa/Cocoa.h>
#endif


//! Project version number for BLECentralManager.
FOUNDATION_EXPORT double BLECentralManagerVersionNumber;

//! Project version string for BLECentralManager.
FOUNDATION_EXPORT const unsigned char BLECentralManagerVersionString[];
