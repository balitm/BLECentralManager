//
//  BLECentralManagerFramework iOS.h
//  BLECentralManagerFramework iOS
//
//  Created by Balázs Kilvády on 12/3/16.
//
//

#import <TargetConditionals.h>

#if TARGET_OS_IOS
#import <UIKit/UIKit.h>
#elif TARGET_OS_MAC
#import <Cocoa/Cocoa.h>
#endif

//! Project version number for BLECentralManagerFramework iOS.
FOUNDATION_EXPORT double BLECentralManagerFrameworkVersionNumber;

//! Project version string for BLECentralManagerFramework iOS.
FOUNDATION_EXPORT const unsigned char BLECentralManagerFrameworkVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <BLECentralManagerFramework_iOS/PublicHeader.h>


