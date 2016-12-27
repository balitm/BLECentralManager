//
//  DataCharacteristic.h
//  BLECentralManager
//
//  Created by Balázs Kilvády on 6/9/16.
//  Copyright © 2016 kil-dev. All rights reserved.
//

#import <BLECentralManager/BLECentralManager.h>
#import "DataCharacteristicDelegate.h"

@interface DataCharacteristic : NSObject <BLECCharacteristicDelegate>

@property (nonatomic, nullable, weak) id<DataCharacteristicDelegate> delegate;

@end
