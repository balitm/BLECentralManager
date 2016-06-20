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


@interface BLECDevice ()

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
    for (BLECDeviceData *data in _characteristics) {
        if (data.serviceIndex == serviceIndex && data.characteristicIndex == characteristicIndex) {
            return data.characteristic;
        }
    }
    return nil;
}

@end
