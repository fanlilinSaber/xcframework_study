//
//  PublicSwiftTest.swift
//  StaticLibrary
//
//  Created by Fan Li Lin on 2023/6/30.
//

import UIKit

public class PublicSwiftTest: NSObject {

    @objc static let sharedLabel = UILabel()
    
    @objc public static func test() {
        print("PublicSwiftTest")
//        PublicTest.test()
    }
    
}
