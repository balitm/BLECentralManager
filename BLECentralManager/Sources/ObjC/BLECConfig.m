//
//  BLECConfig.m
//  Pods
//
//  Created by Balázs Kilvády on 5/19/16.
//  Copyright © 2016 kil-dev. All rights reserved.
//

#import "BLECConfig.h"


//----------------------------------------------------------------------------
// BLECCharacteristicConfig
//----------------------------------------------------------------------------
@implementation BLECCharacteristicConfig

+ (instancetype)characteristicConfigWithType:(BLECCharacteristicType)type
                                        UUID:(NSString *)uuid
                                    delegate:(nullable id<BLECCharacteristicDelegate>)delegate
{
    return [[BLECCharacteristicConfig alloc] initWithType:type
                                                     UUID:uuid
                                                 delegate:delegate];
}

- (instancetype)initWithType:(BLECCharacteristicType)type
                        UUID:(NSString *)uuid
                    delegate:(nullable id<BLECCharacteristicDelegate>)delegate
{
    self = [super init];
    if (self) {
        _type = type;
        _UUID = [CBUUID UUIDWithString:uuid];
        _delegate = delegate;
    }
    return self;
}

@end


//----------------------------------------------------------------------------
// BLECServiceConfig
//----------------------------------------------------------------------------
@implementation BLECServiceConfig

@dynamic charecteristicCount;


+ (instancetype)serviceConfigWithType:(BLECServiceType)type
                                 UUID:(NSString *)uuid
                      characteristics:(NSArray<BLECCharacteristicConfig *> *)chars
{
    return [[BLECServiceConfig alloc] initWithType:type UUID:uuid characteristics:chars];
}

- (instancetype)initWithType:(BLECServiceType)type
                        UUID:(NSString *)uuid
             characteristics:(NSArray<BLECCharacteristicConfig *> *)chars
{
    self = [super init];
    if (self) {
        _type = type;
        _UUID = [CBUUID UUIDWithString:uuid];
        _characteristics = chars;
    }
    return self;
}

- (NSUInteger)charecteristicCount
{
    return [_characteristics count];
}

static NSArray<CBUUID *> * __nonnull _selectCharUUIDs(BLECServiceConfig *self, BLECCharacteristicType type)
{
    NSMutableArray<CBUUID *> *uuids = [[NSMutableArray alloc] initWithCapacity:self->_characteristics.count];
    for (BLECCharacteristicConfig *characteristic in self->_characteristics) {
        if (type == BLECCharacteristicTypeAny || characteristic.type & type) {
            [uuids addObject:characteristic.UUID];
        }
    }
    return uuids.count == 0 ? nil : uuids;
}

- (nullable NSArray<CBUUID *> *)requiredCharcteristicUUIDs
{
    return _selectCharUUIDs(self, BLECCharacteristicTypeRequired);
}

- (nullable NSArray<CBUUID *> *)charcteristicUUIDs
{
    return _selectCharUUIDs(self, BLECCharacteristicTypeAny);
}

- (nullable BLECCharacteristicConfig *)findCharacteristicConfigFor:(nonnull CBUUID *)UUID
                                                             index:(nullable NSUInteger *)index
{
    NSUInteger idx = 0;

    for (BLECCharacteristicConfig *aChar in _characteristics) {
        if ([UUID isEqual:aChar.UUID]) {
            if (index) {
                *index = idx;
            }
            return aChar;
        }
        ++idx;
    }
    return nil;
}

@end


//----------------------------------------------------------------------------
// BLECConfig
//----------------------------------------------------------------------------
@implementation BLECConfig

+ (instancetype)centralConfigWithType:(BLECentralType)type
                             services:(nullable NSArray<BLECServiceConfig *> *)services
{
    return [[BLECConfig alloc] initWithType:type services:services];
}


- (instancetype)initWithType:(BLECentralType)type
                    services:(NSArray<BLECServiceConfig *> *)services
{
    self = [super init];
    if (self) {
        _type = type;
        _services = services;
    }
    return self;
}

static NSArray<CBUUID *> * __nonnull _selectUUIDs(BLECConfig *self, BLECServiceType type)
{
    NSMutableArray<CBUUID *> *uuids = [[NSMutableArray alloc] initWithCapacity:self->_services.count];
    for (BLECServiceConfig *servie in self->_services) {
        if (type == BLECServiceTypeAny || servie.type & type) {
            [uuids addObject:servie.UUID];
        }
    }
    return uuids.count == 0 ? nil : uuids;
}

- (nullable NSArray<CBUUID *> *)advertServiceUUIDs
{
    return _selectUUIDs(self, BLECServiceTypeAdvertised);
}

- (nullable NSArray<CBUUID *> *)requiredServiceUUIDs
{
    return _selectUUIDs(self, BLECServiceTypeRequired);
}

- (nullable NSArray<CBUUID *> *)serviceUUIDs
{
    return _selectUUIDs(self, BLECServiceTypeAny);
}

- (nullable BLECServiceConfig *)findServiceConfigFor:(nonnull CBUUID *)UUID
                                               index:(NSUInteger *)index
{
    NSUInteger idx = 0;

    for (BLECServiceConfig *servie in _services) {
        if ([UUID isEqual:servie.UUID]) {
            if (index) {
                *index = idx;
            }
            return servie;
        }
        ++idx;
    }
    return nil;
}

@end
