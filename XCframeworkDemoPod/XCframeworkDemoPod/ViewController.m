//
//  ViewController.m
//  XCframeworkDemoPod
//
//  Created by Fan Li Lin on 2023/7/4.
//

#import "ViewController.h"
#import <StaticLibrary/StaticHeader.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [StaticLibrary test];

    [PublicTest test];
    
}


@end
