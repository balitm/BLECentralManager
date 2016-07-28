//
//  ControlCharacteristic.m
//  BLECentralManager_iOS
//
//  Created by Balázs Kilvády on 8/1/16.
//  Copyright © 2016 Balázs Kilvády. All rights reserved.
//

#import "ControlCharacteristic.h"

@implementation ControlCharacteristic

- (void)device:(BLECDevice *)device didFindCharacteristic:(CBCharacteristic *)characteristic
{
    DLog(@"device control characteristic %@ found!", characteristic.UUID);
    if (device.peripheral) {
        [device.peripheral readValueForCharacteristic:characteristic];
    }
}

- (void)device:(BLECDevice *)device
didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
         error:(NSError *)error
{
    if (characteristic.value == nil) {
        DLog(@"No value!?");
        return;
    }

    const uint8_t *bytes = (const uint8_t *)[characteristic.value bytes];
    [_delegate controlDidUpdate:bytes[0] == 0 ? ButtonActionStart : ButtonActionStop];
}

@end
