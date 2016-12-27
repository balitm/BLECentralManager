//
//  ControlCharacteristicDelegate.h
//  BLECentralManager_iOS
//
//  Created by Balázs Kilvády on 7/29/16.
//  Copyright © 2016 Balázs Kilvády. All rights reserved.
//

@import Foundation;

typedef NS_ENUM(int, ButtonAction) {
    ButtonActionStart,
    ButtonActionStop
};

@protocol ControlCharacteristicDelegate

- (void)controlDidUpdate:(ButtonAction)state;

@end
