//
//  BLECConfigTest.m
//  BLECManager
//
//  Created by Balázs Kilvády on 5/18/16.
//  Copyright © 2016 kil-dev. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <BLECentralManager/BLECConfig.h>
#import <BLECentralManager/BLECManager.h>


@interface BLECConfigTest : XCTestCase

@end

@implementation BLECConfigTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testConfig {

    BLECConfig *config = [BLECConfig
                          masterConfigWithType:BLECentralTypeOnePheriperal
                          services:@[
                                     [BLECServiceConfig
                                      serviceConfigWithType:BLECServiceTypeAdvertised
                                      UUID:@"965F6F06-2198-4F4F-A333-4C5E0F238EB7"
                                      characteristics:@[
                                                        [BLECCharacteristicConfig
                                                         characteristicConfigWithType:BLECCharacteristicTypeRequired
                                                         UUID:@"89E63F02-9932-4DF1-91C7-A574C880EFBF"
                                                         delegate:nil]
                                                        ]]

                                     ]];
    BLECManager *manager = [[BLECManager alloc] initWithConfig:config queue:nil];
    XCTAssertNotNil(manager);
}

@end
