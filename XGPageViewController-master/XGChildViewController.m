//
//  XGChildViewController.m
//  XGPageViewController-master
//
//  Created by 高昇 on 2017/9/14.
//  Copyright © 2017年 高昇. All rights reserved.
//

#import "XGChildViewController.h"

@interface XGChildViewController ()

@property(nonatomic, strong)UILabel *label;

@end

@implementation XGChildViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initLayout];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSLog(@"%@", [NSString stringWithFormat:@"第%ld页将要出现",(long)_index]);
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    NSLog(@"%@", [NSString stringWithFormat:@"第%ld页已经出现",(long)_index]);
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    NSLog(@"%@", [NSString stringWithFormat:@"第%ld页将要消失",(long)_index]);
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    NSLog(@"%@", [NSString stringWithFormat:@"第%ld页已经消失",(long)_index]);
}

- (void)initLayout
{
    self.view.backgroundColor = [UIColor whiteColor];
    _label = [[UILabel alloc] initWithFrame:CGRectMake(0, (CGRectGetHeight(self.view.frame)-50)/2, CGRectGetWidth(self.view.frame), 50)];
    _label.textColor = [UIColor whiteColor];
    _label.font = [UIFont systemFontOfSize:18];
    _label.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:_label];
}

- (void)setIndex:(NSInteger)index
{
    _index = index;
    _label.text = [NSString stringWithFormat:@"%ld",(long)_index];
}

@end
