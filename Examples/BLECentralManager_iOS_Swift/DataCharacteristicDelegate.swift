//
//  DataCharacteristicDelegate.swift
//  BLECentralManager_Mac_Swift
//
//  Created by Balázs Kilvády on 7/8/16.
//  Copyright © 2016 kil-dev. All rights reserved.
//

protocol DataCharacteristicDelegate: class {

  func dataFound()
  func dataRead(_ dataSize: Int)

}
