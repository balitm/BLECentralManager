//
//  BLECDevice.h
//  Pods
//
//  Created by Balázs Kilvády on 6/1/16.
//
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "BLECCharacteristicDelegate.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(uint32_t, BLECPeripheralState) {
    BLECPeripheralStateNone       = 0,
    BLECPeripheralStateDiscovered = 0x0001,
    BLECPeripheralStateConnected  = 0x0002,
};

@interface BLECDeviceData : NSObject

@property (nonatomic, strong) CBCharacteristic *characteristic;
@property (nonatomic, strong) id<BLECCharacteristicDelegate> delegate;
@property (nonatomic, assign) NSUInteger serviceIndex;
@property (nonatomic, assign) NSUInteger characteristicIndex;

@end

@interface BLECDevice : NSObject

@property (nonatomic, nullable, strong) CBPeripheral *peripheral;
@property (nonatomic, assign) BLECPeripheralState state;
@property (nonatomic, strong) NSUUID *UUID;
@property (nonatomic, strong) NSMutableDictionary<CBUUID *, BLECDeviceData *> *characteristics;

- (nonnull instancetype)initWithUUID:(NSUUID *)uuid;
- (nonnull instancetype)initWithPeripheral:(CBPeripheral *)peripheral;
- (nullable CBCharacteristic *)characteristicAt:(NSUInteger)charIndex
                                    inServiceAt:(NSUInteger)serviceIndex;
- (void)readRSSI;

@end

NS_ASSUME_NONNULL_END
