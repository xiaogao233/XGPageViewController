//
//  ViewController.m
//  XGPageViewController-master
//
//  Created by 高昇 on 2017/9/13.
//  Copyright © 2017年 高昇. All rights reserved.
//

#import "ViewController.h"
#import "XGMainViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)btnAction:(id)sender {
    XGMainViewController *main = [[XGMainViewController alloc] init];
    [self.navigationController pushViewController:main animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
