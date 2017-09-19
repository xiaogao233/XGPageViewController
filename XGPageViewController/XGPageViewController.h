//
//  XGPageViewController.h
//  XGPageViewController-master
//
//  Created by 高昇 on 2017/9/13.
//  Copyright © 2017年 高昇. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol XGPageViewControllerDelegate,XGPageViewControllerDataSource;

@interface XGPageViewController : UIViewController

/* 起始页，从0开始，在dataSource设置前初始化可以用于首次跳转 */
@property(nonatomic, assign)NSInteger startPage;
/* 当前页码 */
@property(nonatomic, assign, readonly)NSInteger currentPage;
/* 总页码 */
@property(nonatomic, assign, readonly)NSInteger numberOfPages;
/* 当前子控制器 */
@property(nonatomic, strong, readonly, nonnull)UIViewController *curChildVC;

/* 代理 */
@property(nullable, nonatomic, weak)id<XGPageViewControllerDelegate> delegate;
/* 数据源 */
@property(nullable, nonatomic, weak)id<XGPageViewControllerDataSource> dataSource;

/**
 复用标识

 @param index 当前子控制器对应index
 @return 复用的子控制器
 */
- (nullable __kindof UIViewController *)dequeueReusableControllerWithIndex:(NSInteger)index;

/**
 跳转到指定页码

 @param page 页码
 */
- (void)pageViewControllerScrollToPage:(NSInteger)page;

/**
 移动到下页

 @param animation 是否动画
 @param completion 移动完成回调
 */
- (void)pageViewControllerMoveToNextPageWithAnimation:(BOOL)animation completion:(void (^ __nullable)(BOOL finished))completion;

/**
 移动到上页

 @param animation 是否动画
 @param completion 移动完成回调
 */
- (void)pageViewControllerMoveToPreviousPageWithAnimation:(BOOL)animation completion:(void (^ __nullable)(BOOL finished))completion;

/**
 删除某页

 @param page 待删除的页码
 @param completion 删除结束回调
 */
- (void)pageViewControllerRemovePage:(NSInteger)page completion:(void (^ __nullable)(BOOL finished))completion;

/**
 删除当前页
 */
- (void)pageViewControllerRemoveCurPage:(void (^ __nullable)(BOOL finished))completion;

@end

@protocol XGPageViewControllerDelegate <NSObject>

@optional
/**
 翻页结束

 @param pageViewController 当前父控制器
 @param finished 动画结束
 @param index 当前页码
 */
- (void)pageViewController:(XGPageViewController * _Nonnull)pageViewController didFinishAnimating:(BOOL)finished index:(NSInteger)index;

/**
 控制器删除了最后一页

 @param pageViewController 当前父控制器
 @param index 当前页码
 */
- (void)pageViewController:(XGPageViewController * _Nonnull)pageViewController didRemoveTheLastPage:(NSInteger)index;

@end


@protocol XGPageViewControllerDataSource <NSObject>

@required
/**
 子控制器数据源

 @param pageViewController 当前父控制器
 @return 子控制器个数
 */
- (NSInteger)numberOfControllersInPageViewController:(XGPageViewController * _Nonnull)pageViewController;

/**
 复用控制器并刷新事件

 @param pageViewController 当前父控制器
 @param index 当前页码
 @return 当前页码对应的子控制器
 */
- (nullable UIViewController *)pageViewController:(XGPageViewController * _Nonnull)pageViewController viewControllerForIndex:(NSInteger)index;

@end
