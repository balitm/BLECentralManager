//
//  BLECConfig.h
//  Pods
//
//  Created by Balázs Kilvády on 5/18/16.
//
//

#import <Foundation/Foundation.h>
#import "BLECCharacteristicDelegate.h"

@class CBUUID;


typedef NS_OPTIONS(unsigned, BLECServiceType) {
    BLECServiceTypeAny = 0x1,
    BLECServiceTypeAdvertised = 0x2,
    BLECServiceTypeRequired = 0x5,
    BLECServiceTypeOptional = 0x8
};

typedef NS_OPTIONS(unsigned, BLECCharacteristicType) {
    BLECCharacteristicTypeAny = 0x1,
    BLECCharacteristicTypeRequired = 0x2,
    BLECCharacteristicTypeOptional = 0x4
};

typedef NS_ENUM(unsigned, BLECentralType) {
    BLECentralTypeOnePheriperal,
    BLECentralTypeMultiPheriperal
};


//----------------------------------------------------------------------------
// BLECCharacteristicConfig
//----------------------------------------------------------------------------
@interface BLECCharacteristicConfig: NSObject

@property (nonatomic, readonly, assign) BLECCharacteristicType type;
@property (nonatomic, readonly, nonnull, strong) CBUUID *UUID;
@property (nonatomic, readonly, nullable, strong) id<BLECCharacteristicDelegate> delegate;

+ (nonnull instancetype)characteristicConfigWithType:(BLECCharacteristicType)type
                                                UUID:(nonnull NSString *)uuid
                                            delegate:(nullable id<BLECCharacteristicDelegate>)delegate;

- (nonnull instancetype)initWithType:(BLECCharacteristicType)type
                                UUID:(nonnull NSString *)uuid
                            delegate:(nullable id<BLECCharacteristicDelegate>)delegate;

@end


//----------------------------------------------------------------------------
// BLECServiceConfig
//----------------------------------------------------------------------------
@interface BLECServiceConfig: NSObject

@property (nonatomic, readonly, assign) BLECServiceType type;
@property (nonatomic, readonly, nonnull, strong) CBUUID *UUID;
@property (nonatomic, readonly, assign) NSUInteger charecteristicCount;
@property (nonatomic, readonly, nonnull, strong) NSArray<BLECCharacteristicConfig *> *characteristics;


+ (nonnull instancetype)serviceConfigWithType:(BLECServiceType)type
                                         UUID:(nullable NSString *)uuid
                              characteristics:(nullable NSArray<BLECCharacteristicConfig *> *)chars;

- (nonnull instancetype)initWithType:(BLECServiceType)type
                                UUID:(nullable NSString *)uuid
                     characteristics:(nullable NSArray<BLECCharacteristicConfig *> *)chars;

- (nullable NSArray<CBUUID *> *)requiredCharcteristicUUIDs;
- (nullable NSArray<CBUUID *> *)charcteristicUUIDs;
- (nullable BLECCharacteristicConfig *)findCharacteristicConfigFor:(nonnull CBUUID *)UUID
                                                             index:(nullable NSUInteger *)index;

@end


//----------------------------------------------------------------------------
// BLECConfig
//----------------------------------------------------------------------------
@interface BLECConfig : NSObject

@property (nonatomic, readonly, assign) BLECentralType type;
@property (nonatomic, nullable, strong) NSDictionary<NSString *, id> *scanOptions;
@property (nonatomic, nullable, strong) NSDictionary<NSString *, id> *connectOptions;
@property (nonatomic, readonly, nullable, strong) NSArray<BLECServiceConfig *> *services;

+ (nonnull instancetype)centralConfigWithType:(BLECentralType)type
                                     services:(nullable NSArray<BLECServiceConfig *> *)services;

- (nonnull instancetype)initWithType:(BLECentralType)type
                            services:(nullable NSArray<BLECServiceConfig *> *)services;

- (nullable NSArray<CBUUID *> *)advertServiceUUIDs;
- (nullable NSArray<CBUUID *> *)requiredServiceUUIDs;
- (nullable NSArray<CBUUID *> *)serviceUUIDs;
- (nullable BLECServiceConfig *)findServiceConfigFor:(nonnull CBUUID *)UUID
                                               index:(nullable NSUInteger *)index;

@end
