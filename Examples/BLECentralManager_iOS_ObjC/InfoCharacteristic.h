//
//  InfoCharacteristic.h
//  BLECentralManager
//
//  Created by Balázs Kilvády on 6/21/16.
//  Copyright © 2016 Balázs Kilvády. All rights reserved.
//

#import <BLECentralManager/BLECentralManager.h>
#import "InfoCharacteristicDelegate.h"


@interface InfoCharacteristic : NSObject <BLECCharacteristicDelegate>

@property (nonatomic, nullable, weak) id<InfoCharacteristicDelegate> delegate;
@property (nonatomic, nonnull, strong) NSString *name;

- (nonnull instancetype)initWithName:(nonnull NSString *)name;

@end
