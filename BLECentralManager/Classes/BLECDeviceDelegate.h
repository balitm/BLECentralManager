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

- (void)masterDidUpdateState:(nonnull BLECManager *)manager;
- (void)deviceDiscovered:(nonnull BLECManager *)manager peripheral:(nonnull CBPeripheral *)pheripheral;
- (void)connectionFailed:(nonnull BLECManager *)manager peripheral:(nonnull CBPeripheral *)pheripheral;
- (void)deviceConnected:(nonnull BLECManager *)manager peripheral:(nonnull CBPeripheral *)pheripheral;
- (void)deviceDisconnected:(nonnull BLECManager *)manager device:(nonnull BLECDevice *)device;

@end
