//
//  ViewController.m
//  BLECentralManager_Mac
//
//  Created by Balázs Kilvády on 6/28/16.
//  Copyright © 2016 kil-dev. All rights reserved.
//

#import "ViewController.h"
#import "DataCharacteristic.h"
#import "InfoCharacteristic.h"
#import "ControlCharacteristic.h"


@interface ViewController ()

@property (weak) IBOutlet NSProgressIndicator *progressView;
@property (weak) IBOutlet NSTextField *rssiLabel;
@property (weak) IBOutlet NSTextField *speedLabel;
@property (unsafe_unretained) IBOutlet NSTextView *logView;

@end

@interface ViewController (Device) <BLECDeviceDelegate>
@end

@interface ViewController (DataCharacteristic) <DataCharacteristicDelegate>
@end

@interface ViewController (InfoCharacteristic) <InfoCharacteristicDelegate>
@end

@interface ViewController (ControlCharacteristic) <ControlCharacteristicDelegate>
@end

const double kMaxKbps = 1024.0 * 100.0;


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

- (void)viewDidLoad {
    [super viewDidLoad];

    DataCharacteristic *dataChar = [[DataCharacteristic alloc] init];
    dataChar.delegate = self;

    ControlCharacteristic *controlChar = [[ControlCharacteristic alloc] init];
    controlChar.delegate = self;

    NSArray<InfoCharacteristic *> *infoChars = @[
                                                 [[InfoCharacteristic alloc] initWithName:@"Company"],
                                                 [[InfoCharacteristic alloc] initWithName:@"Firmware"],
                                                 [[InfoCharacteristic alloc] initWithName:@"HwRev"],
                                                 [[InfoCharacteristic alloc] initWithName:@"SwRev"]
                                                 ];
    [infoChars makeObjectsPerformSelector:@selector(setDelegate:) withObject:self];

    BLECConfig *config = [BLECConfig
                          centralConfigWithType:BLECentralTypeOnePheriperal
                          services:@[
                                     [BLECServiceConfig
                                      serviceConfigWithType:BLECServiceTypeAdvertised | BLECServiceTypeRequired
                                      UUID:@"965F6F06-2198-4F4F-A333-4C5E0F238EB7"
                                      characteristics:@[
                                                        [BLECCharacteristicConfig
                                                         characteristicConfigWithType:BLECCharacteristicTypeRequired
                                                         UUID:@"89E63F02-9932-4DF1-91C7-A574C880EFBF"
                                                         delegate:dataChar],
                                                        [BLECCharacteristicConfig
                                                         characteristicConfigWithType:BLECCharacteristicTypeOptional
                                                         UUID:@"88359D38-DEA0-4FA4-9DD2-0A47E2B794BE"
                                                         delegate:controlChar]
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
    _manager = [[BLECManager alloc] initWithConfig:config queue:nil];
    _manager.delegate = self;
    _timer = nil;
    _dataSize = 0;
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


- (void)update
{
    //---- compute speed ----
    double bitSize = (double)_dataSize * 8.0;
    _progressView.doubleValue = bitSize / (double)kMaxKbps;
    NSNumberFormatter *fmt = [[NSNumberFormatter alloc] init];
    [fmt setFormat:@"0.##"];
    NSString *numString = [fmt stringFromNumber:@(bitSize / 1024.0)];
    _speedLabel.stringValue = numString;
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
    NSTextStorage *ts = self.logView.textStorage;
    if (ts) {
        NSString *string = [NSString stringWithFormat:@"%s\n", str];
        NSAttributedString *as = [[NSAttributedString alloc] initWithString:string];
        [ts appendAttributedString:as];
    }
}

static void _appendNSStringLog(ViewController *self, NSString *str)
{
    NSTextStorage *ts = self.logView.textStorage;
    if (ts) {
        NSString *string = [NSString stringWithFormat:@"%@\n", str];
        NSAttributedString *as = [[NSAttributedString alloc] initWithString:string];
        [ts appendAttributedString:as];
    }
}

static void _showRSSI(ViewController * __unsafe_unretained self, NSNumber *RSSI)
{
    self->_rssiLabel.stringValue = [RSSI stringValue];
}

static void _zeroViews(ViewController * __unsafe_unretained self)
{
    _showRSSI(self, @0);
    self.progressView.doubleValue = 0.0;
    self.speedLabel.intValue = 0;
}

- (void)centralDidUpdateState:(BLECManager *)manager
{
    _appendLog(self, _stateName(manager.state));
}

- (void)central:(BLECManager *)manager
didDiscoverPeripheral:(CBPeripheral *)peripheral
           RSSI:(NSNumber *)RSSI
{
    char str[256];
    snprintf(str, sizeof(str), "Discovered: %s",
             [[peripheral.identifier UUIDString] UTF8String]);
    _appendLog(self, str);
    _showRSSI(self, RSSI);
}

- (void)central:(BLECManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    _appendNSStringLog(self, [NSString stringWithFormat:@"Connected: %@",
                              peripheral.identifier.UUIDString]);
    _timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                              target:self
                                            selector:@selector(update)
                                            userInfo:nil
                                             repeats:YES];
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
    _appendNSStringLog(self, [NSString stringWithFormat:@"Disconnected: %@",
                              device.peripheral.identifier.UUIDString]);
    _zeroViews(self);
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
}

- (void)device:(BLECDevice *)device
   didReadRSSI:(NSNumber *)RSSI
         error:(NSError *)error
{
    if (error) {
        DLog(@"error at RSSI reading: %@", error);
        return;
    }

    _showRSSI(self, RSSI);
}

@end


//............................................................................
// Data characteristic extension.
//............................................................................

@implementation ViewController (DataCharacteristic)

- (void)found
{
    _appendNSStringLog(self, [NSString stringWithFormat:@"Characteristic found!"]);
}

- (void)dataRead:(NSUInteger)dataSize
{
    _dataSize += dataSize;
}

@end


//............................................................................
// Control characteristic extension.
//............................................................................

@implementation ViewController (ControlCharacteristic)

- (void)controlDidUpdate:(ButtonAction)state
{
    CBCharacteristic *characteristic = [_device characteristicAt:1 inServiceAt:0];
    if (characteristic == nil) {
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        _appendNSStringLog(self, [NSString stringWithFormat:@"Control characteristic updated!"]);
    });

    static uint8_t byte = 1;
    static dispatch_once_t onceToken;
    static NSData *data;
    dispatch_once(&onceToken, ^{
        data = [NSData dataWithBytesNoCopy:&byte length:1 freeWhenDone:NO];
    });
    [_device writeValue:data forCharacteristic:characteristic withResponse:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            _appendNSStringLog(self, @"Start data write responded.");
        });
    }];
}

@end


//............................................................................
// Info characteristic extension.
//............................................................................

@implementation ViewController (InfoCharacteristic)

- (void)infoCharacteristicName:(NSString *)name value:(NSString *)value
{
    _appendNSStringLog(self, [NSString stringWithFormat:@"%@: %@", name, value]);
}

@end
