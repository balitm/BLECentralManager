//
//  DataCharacteristicDelegate.h
//  BLECentralManager
//
//  Created by Balázs Kilvády on 6/10/16.
//  Copyright © 2016 kil-dev. All rights reserved.
//

@protocol DataCharacteristicDelegate <NSObject>

- (void)found;

- (void)dataRead:(NSUInteger)dataSize;

@end