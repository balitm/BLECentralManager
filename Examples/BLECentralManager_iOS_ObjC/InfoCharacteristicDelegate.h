//
//  InfoCharacteristicDelegate.h
//  BLECentralManager
//
//  Created by Balázs Kilvády on 6/21/16.
//  Copyright © 2016 Balázs Kilvády. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol InfoCharacteristicDelegate <NSObject>

- (void)infoCharacteristicName:(nonnull NSString*)name value:(nonnull NSString *)value;

@end