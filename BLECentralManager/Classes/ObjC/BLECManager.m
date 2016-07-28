//
//  BLECManager.m
//  Pods
//
//  Created by Balázs Kilvády on 5/19/16.
//  Copyright © 2016 kil-dev. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>
#import "BLECManager.h"
#import "BLECConfig.h"
#import "BLECDevice.h"
#import "Log.h"


@interface BLECManager () <CBCentralManagerDelegate, CBPeripheralDelegate>

- (void)search;
- (void)connect:(nonnull CBPeripheral *)aPeripheral;
- (void)disconnect:(nonnull BLECDevice *)device;

- (BLECDevice *)findDeviceByUUID:(NSUUID *)uuid;
- (BLECDevice *)findOrCreateDeviceByUUID:(NSUUID *)uuid;
- (BLECDevice *)findDeviceByPeripheral:(CBPeripheral *)peripheral;
- (BLECDevice *)findOrCreateDeviceByPeripheral:(CBPeripheral *)peripheral;

@end

@implementation BLECManager
{
    BLECConfig *_config;
    CBCentralManager *_manager;
    NSMutableArray *_devices;
}

- (instancetype)initWithConfig:(BLECConfig *)config queue:(dispatch_queue_t)queue
{
    self = [super init];
    if (!self) return nil;
    _config = config;
    _manager = [[CBCentralManager alloc] initWithDelegate:self queue:queue];
    _state = BLECStateInit;
    _devices = [[NSMutableArray alloc] init];
    return self;
}


#pragma mark - CBCentralManagerDelegate methods

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    DLog(@"centralManagerDidUpdateState");
    switch ([central state]) {
        case CBCentralManagerStateUnsupported:
            _state = BLECStateUnsupported;
            break;
        case CBCentralManagerStateUnauthorized:
            _state = BLECStateUnauthorized;
            break;
        case CBCentralManagerStatePoweredOff:
            _state = BLECStatePoweredOff;
            break;
        case CBCentralManagerStatePoweredOn:
            _state = BLECStatePoweredOn;
            [self search];
            break;
        case CBCentralManagerStateResetting:
            _state = BLECStateResetting;
            DLog(@"resetting called, pairing refused?");
            break;
        case CBCentralManagerStateUnknown:
        default:
            _state = BLECStateUnknown;
    }
    DLog(@"Central manager state: %d", _state);
    if ([_delegate respondsToSelector:@selector(centralDidUpdateState:)]) {
        [_delegate centralDidUpdateState:self];
    }
}

- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary *)advertisementData
                  RSSI:(NSNumber *)RSSI
{
    DLog(@"didDiscoverPeripheral with advertisementData items: %u",
         (unsigned)advertisementData.count);

#ifdef DEBUG
    NSArray *keys = advertisementData.allKeys;
    NSArray *values = advertisementData.allValues;

    for (NSUInteger i = 0; i < advertisementData.count; i++) {
        DLog(@"advertisementData %u: %@ %@",
             (unsigned)i, [keys objectAtIndex:i], [values objectAtIndex:i]);
    }
#endif  // DEBUG

    NSNumber *isConn = advertisementData[CBAdvertisementDataIsConnectable];
    if (![isConn boolValue]) {
        DLog(@"isConn: %@, not try to connect.", isConn);
        return;
    }

    //---- verify advertised services ----
    NSArray<CBUUID *> *advertUUIDs = [_config advertServiceUUIDs];
    if (advertUUIDs != nil) {
        NSArray *services = advertisementData[CBAdvertisementDataServiceUUIDsKey];
        if (services == nil) {
            DLog(@"no services advertised.");
            return;
        }
        for (CBUUID *uuid in advertUUIDs) {
            BOOL isInd = [services indexOfObject:uuid] != NSNotFound;
            if (!isInd) {
                DLog(@"No advert service found: %@", uuid);
                return;
            }
        }
    }

    if ([_delegate respondsToSelector:@selector(central:didDiscoverPeripheral:RSSI:)]) {
        [_delegate central:self didDiscoverPeripheral:peripheral RSSI:RSSI];
    }
    [self connect:peripheral];
}

- (void)centralManager:(CBCentralManager *)central
  didConnectPeripheral:(CBPeripheral *)peripheral
{
    DLog(@"didConnectPeripheral");

    if ([_delegate respondsToSelector:@selector(central:didConnectPeripheral:)]) {
        [_delegate central:self didConnectPeripheral:peripheral];
    }
    if ([peripheral.services count] == 0) {
        //---- Get the services ----
        NSArray<CBUUID *> *uuids = [_config serviceUUIDs];
        [peripheral discoverServices:uuids];
    } else {
        NSAssert(NO, @"Is it reached ever?");
    }
}

- (void)centralManager:(CBCentralManager *)central
didDisconnectPeripheral:(CBPeripheral *)peripheral
                 error:(NSError *)error
{
    //---- set device's state ----
    BLECDevice * __weak dev = [self findDeviceByPeripheral:peripheral];

#ifdef DEBUG
    NSUUID *UUID = peripheral.identifier;
    NSAssert([dev.UUID isEqual:UUID], @"should be equal.");
#endif
    [dev.characteristics removeAllObjects];
    if ([_delegate respondsToSelector:@selector(central:didDisconnectDevice:error:)]) {
        [_delegate central:self didDisconnectDevice:dev error:error];
    }
    dev.peripheral = nil;
    dev.state = BLECPeripheralStateNone;

    //---- workaround attempt for code 6, 10, ... errors ----
    if (error != nil) {
        [_manager stopScan];
        [self search];
    }
}

- (void)centralManager:(CBCentralManager *)central
didFailToConnectPeripheral:(CBPeripheral *)peripheral
                 error:(NSError *)error
{
    DLog(@"Fail to connect to peripheral: %@ with error = %@",
         peripheral, [error localizedDescription]);
    if ([_delegate respondsToSelector:@selector(central:didFailToConnectPeripheral:error:)]) {
        [_delegate central:self didFailToConnectPeripheral:peripheral error:error];
    }
}


#pragma mark - CBPeripheral delegate methods

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error) {
        DLog(@"service discover error: %@", error.description);
        return;
    }

    NSUInteger req = 0;

    for (CBService *service in peripheral.services) {
        DLog(@"Found Service with UUID: %@", service.UUID);

        //---- find service in cofig ----
        BLECServiceConfig *sc = [_config findServiceConfigFor:service.UUID
                                                        index:nil];
        if (sc != nil) {
            if (sc.type & BLECServiceTypeRequired) {
                req++;
            } else if (!(sc.type & BLECServiceTypeOptional)) {
                DLog(@"Unexpected service found: %@", service.UUID);
                [_manager cancelPeripheralConnection:peripheral];
                return;
            }
            NSArray<CBUUID *> *chars = [sc charcteristicUUIDs];
            [peripheral discoverCharacteristics:chars forService:service];
        } else {
            [peripheral discoverCharacteristics:nil forService:service];
        }
    }

    //---- check number of required services ----
    NSArray<CBUUID *> *requiredServices = [_config requiredServiceUUIDs];
    if (req != [requiredServices count]) {
        DLog(@"Not all the required services found.");
        [_manager cancelPeripheralConnection:peripheral];
    }
}


#pragma mark Peripheral methods

- (void)peripheral:(CBPeripheral *)peripheral
didDiscoverCharacteristicsForService:(CBService *)service
             error:(NSError *)error
{
    DLog(@"didDiscoverCharacteristicForService: %@", service.UUID);
    NSUInteger serviceIndex;
    BLECServiceConfig *sc = [_config findServiceConfigFor:service.UUID
                                                    index:&serviceIndex];
    NSUInteger charCount = service.characteristics.count;
    NSMutableArray *characteristics = [[NSMutableArray alloc] initWithCapacity:charCount];
    NSMutableArray *delegates = [[NSMutableArray alloc] initWithCapacity:charCount];
    NSUInteger index = 0;
    NSUInteger req = 0;
    id<BLECCharacteristicDelegate> charDelegate;

    if (sc) {
        if (charCount < sc.requiredCharcteristicUUIDs.count) {
            DLog(@"Too few characteristic in service: %@", service);
            [_manager cancelPeripheralConnection:peripheral];
            return;
        }

        //---- fill the characteristic array ----
        for (NSUInteger i = 0; i < charCount; ++i) {
            [delegates addObject:[NSNull null]];
            [characteristics addObject:[NSNull null]];
        }
    }

    for (CBCharacteristic *aChar in service.characteristics) {
        if (!sc || charCount == 0) {
            [characteristics addObject:aChar];
            charDelegate = [_delegate deviceForCharacteristic:aChar ofPeripheral:peripheral];
            [delegates addObject:charDelegate ? (id)charDelegate : (id)[NSNull null]];
        } else {
            BLECCharacteristicConfig *cc = [sc findCharacteristicConfigFor:aChar.UUID
                                                                     index:&index];
            DLog(@"####### Char found: %@, config: %@", aChar, cc);
            if (cc) {
                if (cc.type & BLECCharacteristicTypeRequired) {
                    req++;
                } else if (!(cc.type & BLECCharacteristicTypeOptional)) {
                    DLog(@"Unexpected characteristic found: %@", aChar.UUID);
                    [_manager cancelPeripheralConnection:peripheral];
                    return;
                }
                [characteristics replaceObjectAtIndex:index withObject:aChar];
                if (cc.delegate) {
                    charDelegate = cc.delegate;
                } else {
                    charDelegate = [_delegate deviceForCharacteristic:aChar ofPeripheral:peripheral];
                }
                if (charDelegate) {
                    [delegates replaceObjectAtIndex:index withObject:charDelegate];
                }
            } else {
                DLog(@"Unexpected characteristic found: %@", aChar.UUID);
                [_manager cancelPeripheralConnection:peripheral];
                return;
            }
        }
    }

    //---- successfuly read characteristics ----
    BLECDevice *device = [self findOrCreateDeviceByPeripheral:peripheral];

    NSEnumerator *en = [delegates objectEnumerator];
    NSUInteger idx = 0;
    for (CBCharacteristic *aChar in characteristics) {
        charDelegate = [en nextObject];
        NSAssert(charDelegate != nil,
                 @"No delegate object for characteristic %@", aChar);

        BLECDeviceData *data = [[BLECDeviceData alloc] init];
        data.characteristic = aChar;
        data.delegate = charDelegate;
        data.characteristicIndex = idx++;
        data.serviceIndex = serviceIndex;
        device.characteristics[aChar.UUID] = data;

        if (![charDelegate isMemberOfClass:[NSNull class]]) {
            [charDelegate device:device didFindCharacteristic:aChar];
        }
    }
    if ([_delegate respondsToSelector:@selector(central:didCheckCharacteristicsDevice:)]) {
        [_delegate central:self didCheckCharacteristicsDevice:device];
    }
}


static void _didReadRSSI(BLECManager * __unsafe_unretained self,
                         CBPeripheral * __unsafe_unretained peripheral,
                         NSNumber * __unsafe_unretained RSSI,
                         NSError * __unsafe_unretained error)
{
    BLECDevice * __weak dev = [self findDeviceByPeripheral:peripheral];
    if ([self->_delegate respondsToSelector:@selector(device:didReadRSSI:error:)]) {
        [self->_delegate device:dev didReadRSSI:RSSI error:error];
    }
}

#if TARGET_OS_IOS
- (void)peripheral:(CBPeripheral *)peripheral
       didReadRSSI:(NSNumber *)RSSI
             error:(NSError *)error
{
    _didReadRSSI(self, peripheral, RSSI, error);
}
#elif TARGET_OS_MAC
- (void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral
                          error:(NSError *)error
{
    //---- implement the depriciated method for OSX compatibility ----
    _didReadRSSI(self, peripheral, peripheral.RSSI, error);
}
#endif

- (void)peripheralDidUpdateName:(CBPeripheral *)peripheral
{
    DLog(@"peripheral: %@ changed it's name to: %@",
         peripheral, peripheral.name);
    BLECDevice * __weak dev = [self findDeviceByPeripheral:peripheral];
    if ([_delegate respondsToSelector:@selector(deviceDidUpdateName:)]) {
        [_delegate deviceDidUpdateName:dev];
    }
}


#pragma mark Characteristic methods

- (void)peripheral:(CBPeripheral *)peripheral
didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error
{
    BLECDevice * __weak device = [self findDeviceByPeripheral:peripheral];
    BLECDeviceData *data = device.characteristics[characteristic.UUID];
    id<BLECCharacteristicDelegate> delegate = data.delegate;
    NSAssert(delegate, @"No delegate for characteristic: %@", characteristic);
    if ([delegate respondsToSelector:@selector(device:didUpdateValueForCharacteristic:error:)]) {
        [delegate device:device didUpdateValueForCharacteristic:characteristic error:error];
    }

    //---- check if readonly ----
    if (characteristic.properties == CBCharacteristicPropertyRead) {
        BOOL release = YES;
        if ([delegate respondsToSelector:@selector(device:releaseReadonlyCharacteristic:)]) {
            release = [delegate device:device releaseReadonlyCharacteristic:characteristic];
        }
        if (release) {
            // Release <BLECDeviceData *data>.
            device.characteristics[characteristic.UUID] = nil;
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral
didWriteValueForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error
{
    DLog(@"Characteristic: %@ is written with error: %@.", characteristic, error);
    BLECDevice * __weak device = [self findDeviceByPeripheral:peripheral];

    NSAssert([device.UUID isEqual:peripheral.identifier], @"should be equal.");

    BLECDeviceData *data = device.characteristics[characteristic.UUID];
    id<BLECCharacteristicDelegate> delegate = data.delegate;
    NSAssert(delegate, @"No delegate for characteristic: %@", characteristic);

    if (data.writeResponse != nil) {
        data.writeResponse(error);
        data.writeResponse = nil;
    } else if ([delegate respondsToSelector:@selector(device:didWriteValueForCharacteristic:error:)]) {
        [delegate device:device didWriteValueForCharacteristic:characteristic error:error];
    }
}


- (void)peripheral:(CBPeripheral *)peripheral
didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error
{
    DLog(@"updated notification's state: %@", characteristic);
    BLECDevice * __weak device = [self findDeviceByPeripheral:peripheral];
    BLECDeviceData *data = device.characteristics[characteristic.UUID];
    id<BLECCharacteristicDelegate> delegate = data.delegate;
    NSAssert(delegate, @"No delegate for characteristic: %@", characteristic);
    if ([delegate respondsToSelector:@selector(device:didUpdateNotificationStateForCharacteristic:error:)]) {
        [delegate device:device didUpdateNotificationStateForCharacteristic:characteristic error:error];
    }
}


#pragma mark - Private methods

- (void)search
{
    static NSArray *services = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        services = [_config advertServiceUUIDs];
    });

    _state = BLECStateSearching;
    DLog(@">>>> scan started.");
    [_manager scanForPeripheralsWithServices:services options:_config.scanOptions];
    NSArray *reqServices = [_config requiredServiceUUIDs];
    if (reqServices == nil) {
        reqServices = [NSArray array];
    }
    NSArray *peers = [_manager retrieveConnectedPeripheralsWithServices:reqServices];

    DLog(@"already connetcted peripherals: %@", peers);
    if ([peers count] == 0) return;

    for (CBPeripheral *peripheral in peers) {
        [self connect:peripheral];
    }
}

- (void)connect:(CBPeripheral *)peripheral
{
    NSAssert(peripheral != nil, @"Peripheral nil.");
    BLECDevice * __weak dev = nil;

    if (peripheral.state == CBPeripheralStateConnected) {
        DLog(@"peripheral is connected already.");
        NSAssert(peripheral.delegate == self,
                 @"delegate is: %@", peripheral.delegate);
        if ((dev = [self findDeviceByPeripheral:peripheral]) != nil) {
            DLog(@"### we are connected to this peripheral already, state: 0x%04x",
                 dev.state);
            return;
        }
    }

    //---- create device object for peripheral ----
    dev = [self findOrCreateDeviceByUUID:peripheral.identifier];
    NSAssert(dev != nil, @"device should be referenced.");
    NSAssert(dev.peripheral == nil || dev.peripheral == peripheral,
             @"check peripheral");
    dev.peripheral = peripheral;

    DLog(@"connecting...");
    peripheral.delegate = self;
    [_manager connectPeripheral:peripheral options:_config.connectOptions];
}

- (void)disconnect:(BLECDevice *)device
{
    NSAssert(device.peripheral.state == CBPeripheralStateConnected,
             @"Peripheral %@ should be connected.", device.peripheral);
    NSAssert(device.peripheral != nil, @"Uninited device.");
    if (device.peripheral) {
        CBPeripheral *peripheral = device.peripheral;
        [_manager cancelPeripheralConnection:peripheral];
    }
}

- (BLECDevice *)findDeviceByUUID:(NSUUID *)uuid
{
    if (uuid == nil) return nil;

    BLECDevice * __block dtmp = nil;
    [_devices
     indexOfObjectPassingTest:^BOOL(BLECDevice *obj, NSUInteger idx, BOOL *stop) {
         if ([uuid isEqual:obj.UUID]) {
             dtmp = obj;
             *stop = YES;
             return YES;
         }
         return NO;
     }];
    return dtmp;
}

- (BLECDevice *)findOrCreateDeviceByUUID:(NSUUID *)uuid
{
    BLECDevice *dev = [self findDeviceByUUID:uuid];
    if (dev == nil) {
        dev = [[BLECDevice alloc] initWithUUID:uuid];
        [_devices addObject:dev];
    }
    return dev;
}

- (BLECDevice *)findDeviceByPeripheral:(CBPeripheral *)peripheral
{
    NSAssert(peripheral != nil, @"peripheral is nil!");
    BLECDevice * __block dtmp = nil;
    [_devices
     indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
         BLECDevice * __weak d = (BLECDevice *)obj;
         if (peripheral == d.peripheral) {
             dtmp = d;
             *stop = YES;
             return YES;
         }
         return NO;
     }];
    return dtmp;
}

- (BLECDevice *)findOrCreateDeviceByPeripheral:(CBPeripheral *)peripheral
{
    BLECDevice *dev = [self findDeviceByPeripheral:peripheral];
    if (dev == nil) {
        dev = [[BLECDevice alloc] initWithPeripheral:peripheral];
        [_devices addObject:dev];
    }
    return dev;
}

@end
