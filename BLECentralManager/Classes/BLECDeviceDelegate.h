//
//  BLECDeviceDelegate.h
//  Pods
//
//  Created by Balázs Kilvády on 6/7/16.
//
//

#import <CoreBluetooth/CoreBluetooth.h>
#import "BLECCharacteristicDelegate.h"


@class BLECManager;

@protocol BLECDeviceDelegate <NSObject>

@optional
- (nonnull id<BLECCharacteristicDelegate>)deviceForCharacteristic:(nonnull CBCharacteristic *)charasteristic
                                   ofPeripheral:(nonnull CBPeripheral *)peripheral;

- (void)centralDidUpdateState:(nonnull BLECManager *)manager;
- (void)central:(nonnull BLECManager *)manager didDiscoverPeripheral:(nonnull CBPeripheral *)peripheral RSSI:(nonnull NSNumber *)RSSI;
- (void)central:(nonnull BLECManager *)manager didFailToConnectPeripheral:(nonnull CBPeripheral *)peripheral error:(nullable NSError *)error;
- (void)central:(nonnull BLECManager *)central didConnectPeripheral:(nonnull CBPeripheral *)peripheral;
- (void)central:(nonnull BLECManager *)central didDisconnectDevice:(nonnull BLECDevice *)device error:(nullable NSError *)error;
- (void)central:(nonnull BLECManager *)central didCheckCharacteristicsDevice:(nonnull BLECDevice *)device;
- (void)device:(nonnull BLECDevice *)device didReadRSSI:(nonnull NSNumber *)RSSI error:(nullable NSError *)error;

@end
