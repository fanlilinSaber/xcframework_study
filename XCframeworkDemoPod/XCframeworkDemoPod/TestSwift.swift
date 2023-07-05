//
//  TestSwift.swift
//  XCframeworkDemoPod
//
//  Created by Fan Li Lin on 2023/7/4.
//

import Foundation

import StaticLibrary.Swift

class TestSwift {
    
    public func test() {
        PublicTest.test()

        PublicSwiftTest.test()
    }
}
