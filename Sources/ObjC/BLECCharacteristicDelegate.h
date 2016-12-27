//
//  BLECCharacteristicDelegate.h
//  Pods
//
//  Created by Balázs Kilvády on 6/2/16.
//
//

#import <CoreBluetooth/CoreBluetooth.h>

NS_ASSUME_NONNULL_BEGIN

@class BLECDevice;

@protocol BLECCharacteristicDelegate <NSObject>
@required
- (void)device:(BLECDevice *)device didFindCharacteristic:(CBCharacteristic *)characteristic;

@optional
- (void)device:(BLECDevice *)device didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error;
- (void)device:(BLECDevice *)device didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error;
- (void)device:(BLECDevice *)device didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error;
- (BOOL)device:(BLECDevice *)device releaseReadonlyCharacteristic:(CBCharacteristic *)characteristic;

@end

NS_ASSUME_NONNULL_END
