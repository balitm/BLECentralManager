# BLECentralManager

[![CI Status](http://img.shields.io/travis/Balázs Kilvády/BLECentralManager.svg?style=flat)](https://travis-ci.org/Balázs Kilvády/BLECentralManager)
[![Version](https://img.shields.io/cocoapods/v/BLECentralManager.svg?style=flat)](http://cocoapods.org/pods/BLECentralManager)
[![License](https://img.shields.io/cocoapods/l/BLECentralManager.svg?style=flat)](http://cocoapods.org/pods/BLECentralManager)
[![Platform](https://img.shields.io/cocoapods/p/BLECentralManager.svg?style=flat)](http://cocoapods.org/pods/BLECentralManager)

## Examples

To run the example projects, clone the repo, and run `pod install` from the Example directory first. A Peripheral_Example project also added so if you have an iOS device and a Mac then you can test the Swift and ObjC iOS examples. They behave as a central and Peripheral_Example will be the peripheral on the Mac.

Also four examples was added: Mac[ObjC | Swift], iOS[ObjC | Swift]

## Requirements

Bluetooth 4 capable iOS device and/or Mac. So all the current (and future) Apple products wit iOS 9 or MacOS 10.11.

## Usage

To initialize a `BLECManager` instance you have to define the configuration data with expected or optional services and characteristics:

Swift:
```swift
        let config = BLECConfig(type: .OnePheriperal, services: [
            BLECServiceConfig(
                type: [.Advertised, .Required],
                UUID: "965F6F06-2198-4F4F-A333-4C5E0F238EB7",
                characteristics: [
                    BLECCharacteristicConfig(
                        type: .Required,
                        UUID: "89E63F02-9932-4DF1-91C7-A574C880EFBF",
                        delegate: dataChar)
                ]),
            BLECServiceConfig(type: .Optional,
                UUID: "180a",
                characteristics: [
                    // Manufacturer Name String characteristic.
                    BLECCharacteristicConfig(
                        type: .Required,
                        UUID: "2a29",
                        delegate: infoChars[0]),

                    // board
                    BLECCharacteristicConfig(
                        type: .Optional,
                        UUID: "2a26",
                        delegate: infoChars[1]),

                    // HwRev
                    BLECCharacteristicConfig(
                        type: .Optional,
                        UUID: "2a27",
                        delegate: infoChars[2]),

                    // SwRev
                    BLECCharacteristicConfig(
                        type: .Optional,
                        UUID: "2a28",
                        delegate: infoChars[3])
                ])
            ])

        let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)
        _manager = BLECManager(config: config, queue: queue)
        _manager.delegate = self;
```

ObjC:
```objc
    BLECConfig *config = [BLECConfig
                          centralConfigWithType:BLECentralTypeOnePheriperal
                          services:@[
                                     [BLECServiceConfig
                                      serviceConfigWithType:BLECServiceTypeAdvertised | BLECServiceTypeRequired
                                      UUID:@"965F6F06-2198-4F4F-A333-4C5E0F238EB7"
                                      characteristics:@[
                                                        [BLECCharacteristicConfig
                                                         characteristicConfigWithType:BLECCharacteristicTypeRequired
                                                         UUID:@"89E63F02-9932-4DF1-91C7-A574C880EFBF"
                                                         delegate:dataChar]
                                                        ]],
                                     [BLECServiceConfig
                                      serviceConfigWithType:BLECServiceTypeOptional
                                      UUID:@"180a"
                                      characteristics:@[
                                                        // Manufacturer Name String characteristic.
                                                        [BLECCharacteristicConfig
                                                         characteristicConfigWithType:BLECCharacteristicTypeRequired
                                                         UUID:@"2a29"
                                                         delegate:infoChars[0]],

                                                        // board
                                                        [BLECCharacteristicConfig
                                                         characteristicConfigWithType:BLECCharacteristicTypeOptional
                                                         UUID:@"2a26"
                                                         delegate:infoChars[1]],

                                                        // HwRev
                                                        [BLECCharacteristicConfig
                                                         characteristicConfigWithType:BLECCharacteristicTypeOptional
                                                         UUID:@"2a27"
                                                         delegate:infoChars[2]],

                                                        // HwRev
                                                        [BLECCharacteristicConfig
                                                         characteristicConfigWithType:BLECCharacteristicTypeOptional
                                                         UUID:@"2a28"
                                                         delegate:infoChars[3]]
                                                        ]]
                                     ]];
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    _manager = [[BLECManager alloc] initWithConfig:config queue:queue];
    _manager.delegate = self;
    _timer = nil;
```

A characteristic handler class must conform to the `BLECDeviceDelegate` protocol.

To access other characteristics from an implementation of characteristic handler the

Swift:
```swift
func characteristicAt(characteristicIndex: Int, inServiceAt serviceIndex: Int) -> CBCharacteristic?
```
ObjC:
```objc
- (nullable CBCharacteristic *)characteristicAt:(NSUInteger)charIndex
                                    inServiceAt:(NSUInteger)serviceIndex;
```
method of `BLECDevice` class can be used. Characteristic and service indices are the indexes of the config structure describes/defines the characteristic.

## Installation

BLECentralManager is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

For ObjC:
```ruby
pod "BLECentralManager/ObjC"
```

For Swift:
```ruby
pod "BLECentralManager/Swift“
```

## Author

Balázs Kilvády, bkilvady@gmail.com

## License

BLECentralManager is available under the BSD license. See the LICENSE.md file for more info.
