//
//  ViewController.m
//  XCframeworkDemoPod
//
//  Created by Fan Li Lin on 2023/7/4.
//

#import "ViewController.h"
#import <StaticLibrary/StaticHeader.h>
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
