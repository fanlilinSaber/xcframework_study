//
//  ViewController.m
//  StaticLibrary IOS Example
//
//  Created by Fan Li Lin on 2023/6/29.
//

#import "ViewController.h"
#import "StaticHeader.h"
//#import "StaticLibrary-Swift.h"

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