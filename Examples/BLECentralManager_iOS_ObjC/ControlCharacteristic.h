//
//  ControlCharacteristic.h
//  BLECentralManager_iOS
//
//  Created by Balázs Kilvády on 8/1/16.
//  Copyright © 2016 Balázs Kilvády. All rights reserved.
//

#import <BLECentralManager/BLECentralManager.h>
#import "ControlCharacteristicDelegate.h"


@interface ControlCharacteristic : NSObject <BLECCharacteristicDelegate>

@property (nonatomic, nullable, weak) id<ControlCharacteristicDelegate> delegate;

@end
