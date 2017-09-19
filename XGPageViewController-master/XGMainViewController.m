//
//  XGMainViewController.m
//  XGPageViewController-master
//
//  Created by 高昇 on 2017/9/14.
//  Copyright © 2017年 高昇. All rights reserved.
//

#import "XGMainViewController.h"
#import "XGChildViewController.h"

@interface XGMainViewController ()<XGPageViewControllerDelegate, XGPageViewControllerDataSource>

/* colorArray */
@property(nonatomic, strong)NSArray *colorArray;
/* 总页码 */
@property(nonatomic, assign)NSInteger totalCount;

@end

@implementation XGMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initLayout];
}

- (void)initLayout
{
    _totalCount = 10;
    self.view.backgroundColor = [UIColor whiteColor];
    self.startPage = 2;
    self.dataSource = self;
    self.delegate = self;
    
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.view.frame)-50, CGRectGetWidth(self.view.frame), 50)];
    footerView.backgroundColor = [UIColor blackColor];
    
    UIButton *leftBtn = [[UIButton alloc] initWithFrame:CGRectMake(5, 5, 80, 40)];
    leftBtn.backgroundColor = [UIColor yellowColor];
    [leftBtn addTarget:self action:@selector(leftBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [footerView addSubview:leftBtn];
    
    UIButton *rightBtn = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.view.frame)-85, 5, 80, 40)];
    rightBtn.backgroundColor = [UIColor yellowColor];
    [rightBtn addTarget:self action:@selector(rightBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [footerView addSubview:rightBtn];
    
    [self.view addSubview:footerView];
}

#pragma mark - action
- (void)leftBtnAction:(UIButton *)sender
{
//    _totalCount--;
//    [self pageViewControllerRemoveCurPage:^(BOOL finished) {
//        if (finished) {
//            NSLog(@"删除成功");
//        }
//    }];
//    [self pageViewControllerScrollToPage:0];
    [self pageViewControllerMoveToPreviousPageWithAnimation:YES completion:^(BOOL finished) {

    }];
}

- (void)rightBtnAction:(UIButton *)sender
{
//    _totalCount--;
//    [self pageViewControllerRemovePage:4 completion:^(BOOL finished) {
//        if (finished) {
//            NSLog(@"删除成功");
//        }
//    }];
//    [self pageViewControllerScrollToPage:17];
    [self pageViewControllerMoveToNextPageWithAnimation:YES completion:^(BOOL finished) {

    }];
}

- (NSInteger)numberOfControllersInPageViewController:(XGPageViewController *)pageViewController
{
    return _totalCount;
}

- (UIViewController *)pageViewController:(XGPageViewController *)pageViewController viewControllerForIndex:(NSInteger)index
{
    XGChildViewController *vc = [pageViewController dequeueReusableControllerWithIndex:index];
    if (!vc)
    {
        vc = [[XGChildViewController alloc] init];
    }
    vc.view.backgroundColor = self.colorArray[index%3];
    vc.index = index;
//    NSLog(@"%@",[NSString stringWithFormat:@"刷新了第%ld页",(long)index]);
    return vc;
}

- (void)pageViewController:(XGPageViewController *)pageViewController didFinishAnimating:(BOOL)finished index:(NSInteger)index
{
//    NSLog(@"第%ld页动画结束",(long)index);
}

- (void)pageViewController:(XGPageViewController *)pageViewController didRemoveTheLastPage:(NSInteger)index
{
    NSLog(@"将要删除最后一页");
}

#pragma mark - lazy
- (NSArray *)colorArray
{
    if (!_colorArray) {
        _colorArray = @[[UIColor redColor],[UIColor greenColor],[UIColor blueColor]];
    }
    return _colorArray;
}

@end
