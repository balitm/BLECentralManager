//
//  BLECManager.h
//  Pods
//
//  Created by Balázs Kilvády on 5/19/16.
//  Copyright © 2016 kil-dev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BLECDeviceDelegate.h"

@class BLECConfig;

typedef NS_ENUM(int, BLECentralState) {
    BLECStateInit,

    BLECStateUnknown,
    BLECStateUnsupported,
    BLECStateUnauthorized,
    BLECStatePoweredOff,
    BLECStatePoweredOn,
    BLECStateResetting,

    BLECStateSearching,
};


@interface BLECManager : NSObject

@property (nonatomic, readonly, assign) BLECentralState state;
@property (nonatomic, nullable, weak) id<BLECDeviceDelegate> delegate;

- (nullable instancetype)initWithConfig:(nonnull BLECConfig *)config
                                  queue:(nullable dispatch_queue_t)queue;

@end
