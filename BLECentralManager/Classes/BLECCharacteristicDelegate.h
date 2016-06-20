//
//  BLECCharacteristicDelegate.h
//  Pods
//
//  Created by Balázs Kilvády on 6/2/16.
//
//

#import <CoreBluetooth/CoreBluetooth.h>

@class BLECDevice;

@protocol BLECCharacteristicDelegate <NSObject>
@required
- (void)device:(nonnull BLECDevice*)device
didFindCharacteristic:(nonnull CBCharacteristic *)characteristic;

@optional
- (void)device:(nonnull BLECDevice*)device
didUpdateValueForCharacteristic:(nonnull CBCharacteristic *)characteristic
         error:(nullable NSError *)error;

@end
