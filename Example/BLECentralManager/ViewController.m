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


@interface ViewController (Device) <BLECDeviceDelegate>

@end

@interface ViewController (Characteristic) <DataCharacteristicDelegate>

@end


//----------------------------------------------------------------------------
// ViewController
//----------------------------------------------------------------------------
@implementation ViewController
{
    BLECManager *_manager;
    NSTimer *_timer;
    NSUInteger _dataSize;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    DataCharacteristic *handler = [[DataCharacteristic alloc] init];
    handler.delegate = self;
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
                                                         delegate:handler]
                                                        ]]

                                     ]];
    _manager = [[BLECManager alloc] initWithConfig:config queue:nil];
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
    [_progressView setProgress:(float)_dataSize / (float)(640 * 20)
                      animated: YES];
    _dataSize = 0;
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

- (void)masterDidUpdateState:(BLECManager *)manager
{
    _appendLog(self, _stateName(manager.state));
}

- (void)deviceDiscovered:(BLECManager *)manager peripheral:(CBPeripheral *)peripheral
{
    char str[256];
    snprintf(str, sizeof(str), "Discovered: %s", [[peripheral.identifier UUIDString] UTF8String]);
    _appendLog(self, str);
}

- (void)deviceConnected:(BLECManager *)manager peripheral:(CBPeripheral *)peripheral
{
    _appendNSStringLog(self, [NSString stringWithFormat:@"Connected: %@", peripheral.identifier]);
    _timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                              target:self
                                            selector:@selector(update)
                                            userInfo:nil
                                             repeats:YES];
}

- (void)deviceDisconnected:(BLECManager *)manager device:(BLECDevice *)device
{
    DLog(@"Disconnected");
    _appendNSStringLog(self, [NSString stringWithFormat:@"Disconnected: %@", device.peripheral.identifier]);
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
}

@end

@implementation ViewController (Characteristic)

- (void)found
{
    _appendNSStringLog(self, [NSString stringWithFormat:@"Characteristic found!"]);
}

- (void)dataRead:(NSUInteger)dataSize
{
    _dataSize += dataSize;
}

@end
