//
//  ControlCharacteristicDelegate.swift
//  BLECentralManager_iOS_Swift
//
//  Created by Balázs Kilvády on 7/27/16.
//  Copyright © 2016 kil-dev. All rights reserved.
//

enum ButtonAction {
    case start
    case stop
}


protocol ControlCharacteristicDelegate: class {

    func controlDidUpdate(_ state: ButtonAction)

}
