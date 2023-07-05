//
//  ViewController.m
//  XCframeworkDemo
//
//  Created by Fan Li Lin on 2023/6/29.
//

#import "ViewController.h"
//#import "StaticHeader.h"
//#import "StaticLibrary-Swift.h"
//#import "XCframeworkDemo-Swift.h"
@import StaticLibrary;

@import StaticLibrary.Swift;

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [StaticLibrary test];

    [PublicSwiftTest test];
    
    [SwiftTest test];
    
}


@end
