//
//  BLECDeviceDelegate.h
//  Pods
//
//  Created by Balázs Kilvády on 6/7/16.
//
//

#import <CoreBluetooth/CoreBluetooth.h>
#import "BLECCharacteristicDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@class BLECManager;

@protocol BLECDeviceDelegate <NSObject>

@optional
- (nonnull id<BLECCharacteristicDelegate>)deviceForCharacteristic:(CBCharacteristic *)charasteristic
                                   ofPeripheral:(CBPeripheral *)peripheral;

- (void)centralDidUpdateState:(BLECManager *)manager;
- (void)central:(BLECManager *)manager didDiscoverPeripheral:(CBPeripheral *)peripheral RSSI:(NSNumber *)RSSI;
- (void)central:(BLECManager *)manager didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error;
- (void)central:(BLECManager *)central didConnectPeripheral:(CBPeripheral *)peripheral;
- (void)central:(BLECManager *)central didDisconnectDevice:(BLECDevice *)device error:(nullable NSError *)error;
- (void)central:(BLECManager *)central didCheckCharacteristicsDevice:(BLECDevice *)device;

- (void)device:(BLECDevice *)device didReadRSSI:(nonnull NSNumber *)RSSI error:(nullable NSError *)error;
- (void)deviceDidUpdateName:(BLECDevice *)device;
@end

NS_ASSUME_NONNULL_END
