//
//  Log.swift
//  Peripheral_Example
//
//  Created by Balázs Kilvády on 6/24/16.
//  Copyright © 2016 kil-dev. All rights reserved.
//

import Foundation

#if DEBUG
func DLog(_ s: String, file: String = #file, line: Int = #line) {
    print("<\((file as NSString).lastPathComponent):\(line)> \(s)")
}

func DLog(_ format: String, file: String = #file, line: Int = #line, _ args: CVarArg...) {
    print("<\((#file as NSString).lastPathComponent):\(#line)> \(String(format: format, arguments: args))")
}
#else
func DLog(_ s: String) {}
func DLog(_ format: String, _ args: CVarArg...) {}
#endif
