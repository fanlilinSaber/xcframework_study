//
//  ViewController.m
//  StaticLibrary IOS Example
//
//  Created by Fan Li Lin on 2023/6/29.
//

#import "ViewController.h"
//#import "StaticLibrary-Swift.h"
//#import "StaticLibrary-umbrella.h"
@import StaticLibrary;

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [StaticLibrary test];

    [PublicTest test];

//    [PublicSwiftTest test];

}


@end
