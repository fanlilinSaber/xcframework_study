//
//  TestSwift.swift
//  XCframeworkDemoPodXC
//
//  Created by 范李林 on 2023/7/7.
//

import Foundation
import StaticLibrary

class TestSwift {

    public func test() {
        PublicTest.test()

        StaticLibrary.test()
        
        PublicSwiftTest.test()

    }
}
