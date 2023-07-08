//
//  ViewController.m
//  XCframeworkDemoPodXC
//
//  Created by 范李林 on 2023/7/7.
//

#import "ViewController.h"
@import StaticLibrary;

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [StaticLibrary test];

    [PublicTest test];
    
    [PublicSwiftTest test];

}


@end
