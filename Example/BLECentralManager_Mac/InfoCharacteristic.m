//
//  InfoCharacteristic.m
//  BLECentralManager
//
//  Created by Balázs Kilvády on 6/21/16.
//  Copyright © 2016 Balázs Kilvády. All rights reserved.
//

#import "InfoCharacteristic.h"


@implementation InfoCharacteristic

- (instancetype)initWithName:(nonnull NSString *)name
{
    self = [super init];
    if (self) {
        _name = name;
    }
    return self;
}

- (void)device:(BLECDevice *)device
didFindCharacteristic:(CBCharacteristic *)characteristic
{
    DLog(@"device info characteristic <%@> found!", characteristic.UUID);
    [device.peripheral readValueForCharacteristic:characteristic];
}

- (void)device:(BLECDevice *)device
didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
         error:(NSError *)error
{
    if (error) {
        DLog(@"characteristic value read with error: %@", error);
        return;
    }

    NSData *data = characteristic.value;
    NSString *value = [[NSString alloc] initWithBytes:[data bytes]
                                               length:[data length]
                                             encoding:NSUTF8StringEncoding];
    [_delegate infoCharacteristicName:_name value:value];
}

- (BOOL)device:(BLECDevice *)device releaseReadonlyCharacteristic:(CBCharacteristic *)characteristic
{
    return YES;
}

@end
