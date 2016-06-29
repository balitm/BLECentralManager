//
//  ViewController.m
//  BLECentralManager
//
//  Created by Balázs Kilvády on 05/18/2016.
//  Copyright (c) 2016 Balázs Kilvády. All rights reserved.
//

#import <BLECentralManager/BLECentralManager.h>
#import "ViewController.h"
#import "DataCharacteristic.h"
#import "InfoCharacteristic.h"


@interface ViewController (Device) <BLECDeviceDelegate>
@end

@interface ViewController (DataCharacteristic) <DataCharacteristicDelegate>
@end

@interface ViewController (InfoCharacteristic) <InfoCharacteristicDelegate>
@end

const float kMaxKbps = 1024.0 * 100.0;


//----------------------------------------------------------------------------
// ViewController
//----------------------------------------------------------------------------
@implementation ViewController
{
    BLECManager *_manager;
    NSTimer *_timer;
    NSUInteger _dataSize;
    BLECDevice * __weak _device;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    DataCharacteristic *dataChar = [[DataCharacteristic alloc] init];
    dataChar.delegate = self;

    NSArray<InfoCharacteristic *> *infoChars = @[
                                                 [[InfoCharacteristic alloc] initWithName:@"Company"],
                                                 [[InfoCharacteristic alloc] initWithName:@"Firmware"],
                                                 [[InfoCharacteristic alloc] initWithName:@"HwRev"],
                                                 [[InfoCharacteristic alloc] initWithName:@"SwRev"]
                                                 ];
    [infoChars makeObjectsPerformSelector:@selector(setDelegate:) withObject:self];

    BLECConfig *config = [BLECConfig
                          masterConfigWithType:BLECentralTypeOnePheriperal
                          services:@[
                                     [BLECServiceConfig
                                      serviceConfigWithType:BLECServiceTypeAdvertised | BLECServiceTypeRequired
                                      UUID:@"965F6F06-2198-4F4F-A333-4C5E0F238EB7"
                                      characteristics:@[
                                                        [BLECCharacteristicConfig
                                                         characteristicConfigWithType:BLECCharacteristicTypeRequired
                                                         UUID:@"89E63F02-9932-4DF1-91C7-A574C880EFBF"
                                                         delegate:dataChar]
                                                        ]],
                                     [BLECServiceConfig
                                      serviceConfigWithType:BLECServiceTypeOptional
                                      UUID:@"180a"
                                      characteristics:@[
                                                        // Manufacturer Name String characteristic.
                                                        [BLECCharacteristicConfig
                                                         characteristicConfigWithType:BLECCharacteristicTypeRequired
                                                         UUID:@"2a29"
                                                         delegate:infoChars[0]],

                                                        // board
                                                        [BLECCharacteristicConfig
                                                         characteristicConfigWithType:BLECCharacteristicTypeOptional
                                                         UUID:@"2a26"
                                                         delegate:infoChars[1]],

                                                        // HwRev
                                                        [BLECCharacteristicConfig
                                                         characteristicConfigWithType:BLECCharacteristicTypeOptional
                                                         UUID:@"2a27"
                                                         delegate:infoChars[2]],

                                                        // HwRev
                                                        [BLECCharacteristicConfig
                                                         characteristicConfigWithType:BLECCharacteristicTypeOptional
                                                         UUID:@"2a28"
                                                         delegate:infoChars[3]]
                                                        ]]
                                     ]];
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    _manager = [[BLECManager alloc] initWithConfig:config queue:queue];
    _manager.delegate = self;
    _timer = nil;
    _dataSize = 0;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)update
{
    //---- compute speed ----
    [_progressView setProgress:(float)_dataSize / (kMaxKbps / 8.0)
                      animated: YES];
    _dataSize = 0;

    //---- read RSSI ----
    [_device readRSSI];
}

@end


//............................................................................
// Device extension.
//............................................................................

@implementation ViewController (Device)

static const char *_stateName(BLECentralState state)
{
    switch (state) {
        case BLECStateInit:
            return "BLECStateInit";

        case BLECStateUnknown:
            return "BLECStateUnknown";
        case BLECStateUnsupported:
            return "BLECStateUnsupported";
        case BLECStateUnauthorized:
            return "BLECStateUnauthorized";
        case BLECStatePoweredOff:
            return "BLECStatePoweredOff";
        case BLECStatePoweredOn:
            return "BLECStatePoweredOn";
        case BLECStateResetting:
            return "BLECStateResetting";

        case BLECStateSearching:
            return "BLECStateSearching";
    }
    assert(NO);
}

static void _appendLog(ViewController *self, const char *str)
{
    self.logView.text = [self.logView.text stringByAppendingFormat:@"%s\n", str];
}

static void _appendNSStringLog(ViewController *self, NSString *str)
{
    self.logView.text = [self.logView.text stringByAppendingFormat:@"%@\n", str];
}

static void _showRSSI(ViewController *self, NSNumber *RSSI)
{
    self->_rssiLabel.text = [RSSI stringValue];
}

- (void)centralDidUpdateState:(BLECManager *)manager
{
    dispatch_async(dispatch_get_main_queue(), ^{
        _appendLog(self, _stateName(manager.state));
    });
}

- (void)central:(BLECManager *)manager
didDiscoverPeripheral:(CBPeripheral *)peripheral
           RSSI:(NSNumber *)RSSI
{
    dispatch_async(dispatch_get_main_queue(), ^{
        char str[256];
        snprintf(str, sizeof(str), "Discovered: %s",
                 [[peripheral.identifier UUIDString] UTF8String]);
        _appendLog(self, str);
        _showRSSI(self, RSSI);
    });
}

- (void)central:(BLECManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    dispatch_async(dispatch_get_main_queue(), ^{
        _appendNSStringLog(self, [NSString stringWithFormat:@"Connected: %@",
                                  peripheral.identifier.UUIDString]);
        _timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                  target:self
                                                selector:@selector(update)
                                                userInfo:nil
                                                 repeats:YES];
    });
}

- (void)central:(BLECManager *)central didCheckCharacteristicsDevice:(nonnull BLECDevice *)device
{
    _device = device;
}

- (void)central:(BLECManager *)central
didDisconnectDevice:(BLECDevice *)device
          error:(NSError *)error
{
    DLog(@"Disconnected");
    NSString *message = [NSString stringWithFormat:@"Disconnected: %@",
                         device.peripheral.identifier.UUIDString];
    dispatch_async(dispatch_get_main_queue(), ^{
        _appendNSStringLog(self, message);
        _rssiLabel.text = @"0";
        if (_timer) {
            [_timer invalidate];
            _timer = nil;
        }
    });
}

- (void)device:(BLECDevice *)device
   didReadRSSI:(NSNumber *)RSSI
         error:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (error) {
            DLog(@"error at RSSI reading: %@", error);
            return;
        }

        _showRSSI(self, RSSI);
    });
}

@end


//............................................................................
// Data characteristic extension.
//............................................................................

@implementation ViewController (DataCharacteristic)

- (void)found
{
    dispatch_async(dispatch_get_main_queue(), ^{
        _appendNSStringLog(self, [NSString stringWithFormat:@"Characteristic found!"]);
    });
}

- (void)dataRead:(NSUInteger)dataSize
{
    _dataSize += dataSize;
}

@end


//............................................................................
// Info characteristic extension.
//............................................................................

@implementation ViewController (InfoCharacteristic)

- (void)infoCharacteristicName:(NSString *)name value:(NSString *)value
{
    dispatch_async(dispatch_get_main_queue(), ^{
        _appendNSStringLog(self, [NSString stringWithFormat:@"%@: %@", name, value]);
    });
}

@end
