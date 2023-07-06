//
//  SwiftTest.swift
//  XCframeworkDemo
//
//  Created by Fan Li Lin on 2023/6/30.
//

import UIKit
import StaticLibrary

public class SwiftTest: NSObject {

    
    @objc public static func test() {
        print("XCframeworkDemo - SwiftTest")
        
        PublicSwiftTest.test()
    
        StaticLibrary.test()
        
    }
}
