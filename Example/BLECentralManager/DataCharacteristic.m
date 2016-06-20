//
//  BLECDataCharacteristic.m
//  BLECentralManager
//
//  Created by Balázs Kilvády on 6/9/16.
//  Copyright © 2016 kil-dev. All rights reserved.
//

#import "DataCharacteristic.h"


@implementation DataCharacteristic

- (void)device:(BLECDevice *)device
didFindCharacteristic:(CBCharacteristic *)characteristic
{
    DLog(@"device characteristic <%@> found!", characteristic.UUID);
    [device.peripheral setNotifyValue:YES forCharacteristic:characteristic];
    [_delegate found];
}

- (void)device:(BLECDevice *)device
didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
         error:(NSError *)error
{
    [_delegate dataRead:characteristic.value.length];
}

@end
