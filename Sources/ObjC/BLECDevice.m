//
//  BLECDevice.m
//  Pods
//
//  Created by Balázs Kilvády on 6/1/16.
//
//

#import "BLECDevice.h"


@implementation BLECDeviceData

@end


@implementation BLECDevice

- (instancetype)initWithUUID:(NSUUID *)uuid
{
    self = [super init];
    if (self) {
        _UUID = uuid;
        _peripheral = nil;
        _characteristics = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral
{
    self = [super init];
    if (self) {
        _UUID = peripheral.identifier;
        _peripheral = peripheral;
        _characteristics = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (CBCharacteristic *)characteristicAt:(NSUInteger)characteristicIndex
                           inServiceAt:(NSUInteger)serviceIndex
{
    __block CBCharacteristic *found = nil;
    [_characteristics enumerateKeysAndObjectsUsingBlock:^(CBUUID *key, BLECDeviceData *data, BOOL *stop) {
        if (data.serviceIndex == serviceIndex && data.characteristicIndex == characteristicIndex) {
            found = data.characteristic;
            *stop = YES;
        }
    }];
    return found;
}

- (void)readRSSI
{
    if (_peripheral) {
        [_peripheral readRSSI];
    }
}

- (void)writeValue:(NSData *)value
 forCharacteristic:(CBCharacteristic *)characteristic
      WithResponse:(void (^)(NSError *error))response
{
    if (!_peripheral) return;

    if (response == nil) {
        [_peripheral writeValue:value
              forCharacteristic:characteristic
                           type:CBCharacteristicWriteWithoutResponse];
    } else {
        BLECDeviceData *charData = _characteristics[characteristic.UUID];
        if (charData == nil) {
            return;
        }
        if (charData.writeResponse != nil) {
            NSAssert(NO, @"UNREACHABLE");
            return;
        }
        charData.writeResponse = response;
        _characteristics[characteristic.UUID] = charData;
        [_peripheral writeValue:value
              forCharacteristic:characteristic
                           type:CBCharacteristicWriteWithResponse];
    }
}

@end
