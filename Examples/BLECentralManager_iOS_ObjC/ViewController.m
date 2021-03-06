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
#import "ControlCharacteristic.h"


@interface ViewController ()

@property (nonatomic, assign) ButtonAction buttonState;

@end

@interface ViewController (Device) <BLECDeviceDelegate>
@end

@interface ViewController (DataCharacteristic) <DataCharacteristicDelegate>
@end

@interface ViewController (InfoCharacteristic) <InfoCharacteristicDelegate>
@end

@interface ViewController (ControlCharacteristic) <ControlCharacteristicDelegate>
@end

const float kMaxKbps = 1024.0f * 100.0f;

static void _appendLog(ViewController *self, const char *str)
{
    self.logView.text = [self.logView.text stringByAppendingFormat:@"%s\n", str];
}

static void _appendNSStringLog(ViewController *self, NSString *str)
{
    self.logView.text = [self.logView.text stringByAppendingFormat:@"%@\n", str];
}



//----------------------------------------------------------------------------
// ViewController
//----------------------------------------------------------------------------
@implementation ViewController
{
    BLECManager *_manager;
    NSTimer *_timer;
    NSUInteger _dataSize;
    BLECDevice * __weak _device;
    ButtonAction _buttonState;
}

@dynamic buttonState;

- (ButtonAction)buttonState
{
    return _buttonState;
}

- (void)setButtonState:(ButtonAction)buttonState
{
    _buttonState = buttonState;
    switch (buttonState) {
        case ButtonActionStop:
            [_startButton setTitle:@"Stop" forState:UIControlStateNormal];
            _progressView.progress = (float)0.0;
            break;
        case ButtonActionStart:
            [_startButton setTitle:@"Start" forState:UIControlStateNormal];
            break;
    }
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        _buttonState = ButtonActionStart;
    }
    return self;
}


- (void)viewDidLoad
{
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

- (IBAction)actionStart:(UIButton *)sender
{
    CBCharacteristic *characteristic = [_device characteristicAt:1 inServiceAt:0];
    if (characteristic == nil) {
        return;
    }

    static uint8_t array[1];

    switch (_buttonState) {
        case ButtonActionStart:
            array[0] = (uint8_t)1;
            self.buttonState = ButtonActionStop;
            break;
        case ButtonActionStop:
            array[0] = (uint8_t)0;
            self.buttonState = ButtonActionStart;
            break;
    }
    NSData *data = [NSData dataWithBytesNoCopy:array length:1 freeWhenDone:NO];
    [_device writeValue:data forCharacteristic:characteristic withResponse:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            _appendNSStringLog(self, [NSString stringWithFormat:@"%s data write responded.",
                                      array[0] == 1 ? "Start" : "Stop"]);
        });
    }];
}

- (void)update
{
    //---- compute speed & progress ----
    float bitSize = (float)_dataSize * 8.0;
    [self.progressView setProgress:bitSize / kMaxKbps animated: YES];
    NSString *numString = [NSString stringWithFormat:@"%0.2f", bitSize / 1024.0f];
    self.speedLabel.text = numString;
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

static void _showRSSI(ViewController * __unsafe_unretained self, NSNumber *RSSI)
{
    self.rssiLabel.text = [RSSI stringValue];
}

static void _zeroViews(ViewController * __unsafe_unretained self)
{
    _showRSSI(self, @0);
    self.progressView.progress = 0.0f;
    self.speedLabel.text = @"0";
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
        _zeroViews(self);
        _device = nil;
        self.startButton.enabled = NO;
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
// Control characteristic extension.
//............................................................................

@implementation ViewController (ControlCharacteristic)

- (void)controlDidUpdate:(ButtonAction)state
{
    dispatch_async(dispatch_get_main_queue(), ^{
        _appendNSStringLog(self, [NSString stringWithFormat:@"Control characteristic updated!"]);
        self.startButton.enabled = YES;
        self.buttonState = state;
    });
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
