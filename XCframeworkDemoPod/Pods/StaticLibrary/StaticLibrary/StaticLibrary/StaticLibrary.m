//
//  StaticLibrary.m
//  StaticLibrary
//
//  Created by Fan Li Lin on 2023/6/29.
//

#import "StaticLibrary.h"
#import "PrivateTest.h"
//#import "StaticLibrary-Swift.h"

@implementation StaticLibrary

+ (void)test {
    NSLog(@"StaticLibrary");
    
    [PrivateTest test];
    
//    [PublicSwiftTest new];
//    
//    [PublicSwiftTest test];
}

@end
