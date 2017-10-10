//
//  XGPageViewController.m
//  XGPageViewController-master
//
//  Created by 高昇 on 2017/9/13.
//  Copyright © 2017年 高昇. All rights reserved.
//

#import "XGPageViewController.h"
#import <objc/runtime.h>

/* 属性标识 */
static char kIdentifier;

@interface UIViewController (Identifier)
/* 控制器标识 */
@property(nonatomic, assign)NSInteger identifier;
@end

@implementation UIViewController (Identifier)

- (void)setIdentifier:(NSInteger)identifier
{
    objc_setAssociatedObject(self, &kIdentifier, [NSNumber numberWithInteger:identifier], OBJC_ASSOCIATION_ASSIGN);
}
- (NSInteger)identifier
{
    return [objc_getAssociatedObject(self, &kIdentifier) integerValue];
}

@end

#define kXGWS(weakSelf) __weak __typeof(&*self) weakSelf = self
#define kXGScreenW [[UIScreen mainScreen] bounds].size.width

/* 最大控制器 */
static NSInteger const kMaxCount = 3;
/* 侧边栏占比 */
static CGFloat const kLeftViewScale = 0.95;
static CGFloat const kAnimationTime = 0.25;

@interface XGPageViewController ()<UIGestureRecognizerDelegate>

/* 总页码 */
@property(nonatomic, assign)NSInteger pageCount;
/* 当前页码 */
@property(nonatomic, assign)NSInteger curPage;
/* 子控制器最大数目 */
@property(nonatomic, assign)NSInteger maxCount;
/* 复用控制器差值 */
@property(nonatomic, assign)NSInteger differIndex;
/* 滑动手势 */
@property(nonatomic, strong)UIPanGestureRecognizer *panGesture;
/* 是否初次加载 */
@property(nonatomic, assign)BOOL isFirstLoad;

@end

@implementation XGPageViewController

#pragma mark 生命周期
- (void)viewDidLoad {
    [super viewDidLoad];
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.isFirstLoad = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    for (UIViewController *vc in self.childViewControllers) {
        [vc beginAppearanceTransition:YES animated:animated];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    for (UIViewController *vc in self.childViewControllers) {
        [vc endAppearanceTransition];
    }
    if (self.isFirstLoad)
    {
        [self childViewControllerForIndex:self.curPage+1 isLastPage:NO];
        if (self.curPage>0)
        {
            [self childViewControllerForIndex:self.curPage-1 isLastPage:YES];
        }
        else
        {
            [self childViewControllerForIndex:self.curPage+2 isLastPage:NO];
        }
        [self handlerSubviewsLayout:NO];
        self.isFirstLoad = NO;
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    for (UIViewController *vc in self.childViewControllers) {
        [vc beginAppearanceTransition:NO animated:animated];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    for (UIViewController *vc in self.childViewControllers) {
        [vc endAppearanceTransition];
    }
}

/* 禁用子控制器自动管理生命周期 */
- (BOOL)shouldAutomaticallyForwardAppearanceMethods
{
    return NO;
}

#pragma mark - 私有方法
/* 刷新数据源 */
- (void)reloadDataSource
{
    if (self.dataSource)
    {
        if ([self.dataSource respondsToSelector:@selector(numberOfControllersInPageViewController:)]) {
            self.pageCount = [self.dataSource numberOfControllersInPageViewController:self];
        }
    }
    else
    {
        NSAssert((self.dataSource != nil), @"必须先设置数据源");
    }
}

/* 初始化界面 */
- (void)reloadLayout
{
    /* 获取数据源 */
    [self reloadDataSource];
    /* 添加第一个子控制器 */
    if (self.pageCount>0)
    {
        /* 获取子控制器最大数目，用于判断子控制器是否已满 */
        self.maxCount = self.pageCount>kMaxCount?kMaxCount:self.pageCount;
        /* 获取首次刷新页面 */
        if ([self.dataSource respondsToSelector:@selector(pageViewController:viewControllerForIndex:)])
        {
            self.curPage = self.startPage<self.pageCount?self.startPage:self.pageCount-1;
            /* 默认初始复用0子控制器，计算控制器复用差值，例如第一次加载第三页，原本因复用第3个子控制器，初始复用第一个，差值为2 */
            self.differIndex = self.curPage%kMaxCount;
            UIViewController *vc = [self.dataSource pageViewController:self viewControllerForIndex:self.curPage];
            vc.identifier = self.curPage;
            vc.view.frame = CGRectMake(0, 0, CGRectGetWidth(vc.view.frame), CGRectGetHeight(vc.view.frame));
            [vc.view addGestureRecognizer:self.panGesture];
            [self addChildViewController:vc];
            [self.view addSubview:vc.view];
            [self.view sendSubviewToBack:vc.view];
            if ([self.delegate respondsToSelector:@selector(pageViewController:didFinishAnimating:index:)]) {
                [self.delegate pageViewController:self didFinishAnimating:YES index:_curPage];
            }
        }
    }
}

/**
 控制器复用标识

 @param index 当前index
 @return 复用Controller
 */
- (nullable __kindof UIViewController *)dequeueReusableControllerWithIndex:(NSInteger)index
{
    /* 判断复用控制器是否存在 */
    NSInteger reuseIndex = labs(index-self.differIndex+kMaxCount)%kMaxCount;
    if (reuseIndex<self.childViewControllers.count) return self.childViewControllers[reuseIndex];
    return nil;
}

/**
 获取index对应的子控制器

 @param index index
 */
- (UIViewController *)childViewControllerForIndex:(NSInteger)index isLastPage:(BOOL)isLastPage
{
    /* 越界处理 */
    if (index<0 || index>self.pageCount) return nil;
    /* 获取子控制器 */
    /* 判断复用控制器是否存在 */
    NSInteger reuseIndex = labs(index-self.differIndex+kMaxCount)%kMaxCount;
    if (reuseIndex<self.childViewControllers.count)
    {
        /* 存在复用，取复用池 */
        UIViewController *vc = self.childViewControllers[reuseIndex];
        if (vc.identifier != index && index<self.pageCount)
        {
            /* 刷新界面 */
            if ([self.dataSource respondsToSelector:@selector(pageViewController:viewControllerForIndex:)])
            {
                UIViewController *controller = [self.dataSource pageViewController:self viewControllerForIndex:index];
                controller.identifier = index;
                return controller;
            }
        }
        return self.childViewControllers[reuseIndex];
    }
    else
    {
        /* 不存在复用，加入复用池 */
        if ([self.dataSource respondsToSelector:@selector(pageViewController:viewControllerForIndex:)])
        {
            UIViewController *vc = [self.dataSource pageViewController:self viewControllerForIndex:index];
            vc.identifier = index;
            CGFloat offset_x = 0;
            if (isLastPage) offset_x = -kXGScreenW;
            vc.view.frame = CGRectMake(offset_x, 0, CGRectGetWidth(vc.view.frame), CGRectGetHeight(vc.view.frame));
            [self addChildViewController:vc];
            [self.view addSubview:vc.view];
            [self.view sendSubviewToBack:vc.view];
            return [self childViewControllerForIndex:index isLastPage:isLastPage];
        }
    }
    return nil;
}

/* 处理控制器视图隐藏 */
- (void)handlerSubviewsLayout:(BOOL)isAllShow
{
    for (UIViewController *vc in self.childViewControllers) {
        vc.view.hidden = NO;
        if (vc.identifier != _curPage && !isAllShow)
        {
            vc.view.hidden = YES;
        }
    }
    /* 动画结束，开启手势 */
    if (!isAllShow) self.view.userInteractionEnabled = YES;
}

#pragma mark - 共有方法
- (void)pageViewControllerMoveToNextPageWithAnimation:(BOOL)animation completion:(void (^)(BOOL))completion
{
    if (self.view.userInteractionEnabled)
    {
        if (_curPage<_pageCount-1)
        {
            /* 动画开始，禁用手势 */
            self.view.userInteractionEnabled = NO;
            /* 显示所有视图 */
            [self handlerSubviewsLayout:YES];
            /* 当前页 */
            UIViewController *curVC = [self childViewControllerForIndex:_curPage isLastPage:NO];
            UIView *curView = curVC.view;
            /* 下一页 */
            UIViewController *nextVC = [self childViewControllerForIndex:_curPage+1 isLastPage:NO];
            UIView *nextView = nextVC.view;
            /* 设置下一页的位置，在当前页面下 */
            nextView.center = CGPointMake(kXGScreenW/2, curView.center.y);
            [self.view insertSubview:nextView belowSubview:curView];
            /* 动画时间 */
            CGFloat animationTime = kAnimationTime;
            if (!animation) animationTime = 0;
            /* 当前页将要消失 */
            [curVC beginAppearanceTransition:NO animated:NO];
            /* 下页将要出现 */
            [nextVC beginAppearanceTransition:YES animated:NO];
            /* 将当前页移动到最左边 */
            [UIView animateWithDuration:animationTime animations:^{
                curView.center = CGPointMake(-kXGScreenW/2, curView.center.y);
            } completion:^(BOOL finished) {
                /* 如果存在上一页，则将上一页放置最底层 */
                if (_curPage>0)
                {
                    /* 存在上一页 */
                    UIViewController *lastVC = [self childViewControllerForIndex:_curPage-1 isLastPage:YES];
                    UIView *lastView = lastVC.view;
                    /* 设置上一页的位置，在左侧 */
                    lastView.center = CGPointMake(kXGScreenW/2, curView.center.y);
                    /* 设置上一页的层级，最底层 */
                    [self.view sendSubviewToBack:lastView];
                    /* 刷新上一页，该页为_curPage+2 */
                    [self childViewControllerForIndex:_curPage+2 isLastPage:NO];
                }
                /* 处理下一页 */
                UIViewController *nextVC = [self childViewControllerForIndex:_curPage+1 isLastPage:NO];
                UIView *nextView = nextVC.view;
                [nextView addGestureRecognizer:self.panGesture];
                _curPage++;
                /* 当前页已经消失 */
                [curVC endAppearanceTransition];
                /* 下页已经出现 */
                [nextVC endAppearanceTransition];
                /* 处理视图 */
                [self handlerSubviewsLayout:NO];
                /* 移动完成 */
                if (completion) completion(YES);
                /* 动画结束，开启手势 */
                self.view.userInteractionEnabled = YES;
                /* 成功移动到下一页 */
                if ([self.delegate respondsToSelector:@selector(pageViewController:didFinishAnimating:index:)]) {
                    [self.delegate pageViewController:self didFinishAnimating:YES index:_curPage];
                }
            }];
        }
        else
        {
            /* 最后一页，不能移动 */
            if (completion) completion(NO);
        }
    }
}

- (void)pageViewControllerMoveToPreviousPageWithAnimation:(BOOL)animation completion:(void (^)(BOOL))completion
{
    if (self.view.userInteractionEnabled)
    {
        if (_curPage>0)
        {
            /* 存在上页 */
            /* 动画开始，禁用手势 */
            self.view.userInteractionEnabled = NO;
            /* 显示所有视图 */
            [self handlerSubviewsLayout:YES];
            /* 当前控制器 */
            UIViewController *curVC = [self childViewControllerForIndex:_curPage isLastPage:NO];
            UIView *curView = curVC.view;
            /* 上页控制器 */
            UIViewController *lastVC = [self childViewControllerForIndex:_curPage-1 isLastPage:YES];
            UIView *lastView = lastVC.view;
            [self.view insertSubview:lastView atIndex:self.childViewControllers.count-1];
            /* 动画时间 */
            CGFloat animationTime = kAnimationTime;
            if (!animation) animationTime = 0;
            /* 当前页将要消失 */
            [curVC beginAppearanceTransition:NO animated:NO];
            /* 下页将要出现 */
            [lastVC beginAppearanceTransition:YES animated:NO];
            /* 上一页覆盖当前页 */
            [UIView animateWithDuration:animationTime animations:^{
                lastView.center = CGPointMake(kXGScreenW/2, curView.center.y);
            } completion:^(BOOL finished) {
                /* 下一页放置最左边 */
                /* 最后一页容错处理，若当前为最大页面，则最后一页复用且移动到最左边 */
                if (_curPage<_pageCount-1 || (_curPage==_pageCount-1 && _maxCount == kMaxCount))
                {
                    /* 存在下一页 */
                    UIViewController *nextVC = [self childViewControllerForIndex:_curPage+1 isLastPage:NO];
                    UIView *nextView = nextVC.view;
                    nextView.center = CGPointMake(-kXGScreenW/2, curView.center.y);
                    [self.view insertSubview:nextView atIndex:self.childViewControllers.count-1];
                    /* 刷新下一页，该页为_curPage-2 */
                    [self childViewControllerForIndex:_curPage-2 isLastPage:YES];
                }
                [lastView addGestureRecognizer:self.panGesture];
                _curPage--;
                /* 当前页已经消失 */
                [curVC endAppearanceTransition];
                /* 上页已经出现 */
                [lastVC endAppearanceTransition];
                /* 处理视图 */
                [self handlerSubviewsLayout:NO];
                /* 移动完成 */
                if (completion) completion(YES);
                /* 动画结束，开启手势 */
                self.view.userInteractionEnabled = YES;
                /* 成功移动到上页 */
                if ([self.delegate respondsToSelector:@selector(pageViewController:didFinishAnimating:index:)]) {
                    [self.delegate pageViewController:self didFinishAnimating:YES index:_curPage];
                }
            }];
        }
        else
        {
            /* 第一页，不能移动 */
            if (completion) completion(NO);
        }
    }
}

- (void)pageViewControllerScrollToPage:(NSInteger)page
{
    /* 处理之前的页面生命周期 */
    UIViewController *oldCurVC = [self childViewControllerForIndex:_curPage isLastPage:NO];
    /* 老的当前页面将要消失 */
    [oldCurVC beginAppearanceTransition:NO animated:YES];
    /* 老的当前页面已经消失 */
    [oldCurVC endAppearanceTransition];
    /* 新的当前页面 */
    _curPage = page;
    if (_curPage<0) _curPage = 0;
    if (_curPage>_pageCount-1) _curPage = _pageCount-1;
    /* 取消隐藏子控制器视图 */
    [self handlerSubviewsLayout:YES];
    /* 当前页 */
    UIViewController *curVC = [self childViewControllerForIndex:_curPage isLastPage:NO];
    UIView *curView = curVC.view;
    [curView addGestureRecognizer:self.panGesture];
    curView.center = CGPointMake(kXGScreenW/2, curView.center.y);
    [self.view insertSubview:curView atIndex:self.childViewControllers.count-1];
    /* 新的当前页的生命周期 */
    /* 新的当前页面将要出现 */
    [curVC beginAppearanceTransition:YES animated:NO];
    /* 新的当前页面已经出现 */
    [curVC endAppearanceTransition];
    /* 1、判断是否存在前页 */
    if (_curPage>0)
    {
        /* 存在上页 */
        UIViewController *lastVC = [self childViewControllerForIndex:_curPage-1 isLastPage:YES];
        UIView *lastView = lastVC.view;
        /* 设置上一页的位置，在左侧 */
        lastView.center = CGPointMake(-kXGScreenW/2, curView.center.y);
        /* 设置上一页的层级，最上层 */
        [self.view insertSubview:curView atIndex:self.childViewControllers.count-1];
    }
    /* 2、判断是否存在后页 */
    if (_curPage<_pageCount-1)
    {
        /* 存在后页 */
        UIViewController *nextVC = [self childViewControllerForIndex:_curPage+1 isLastPage:NO];
        UIView *nextView = nextVC.view;
        /* 设置后页位置 */
        nextView.center = CGPointMake(kXGScreenW/2, curView.center.y);
        /* 移动到当前页的下一层 */
        [self.view insertSubview:nextView belowSubview:curView];
    }
    /* 处理视图隐藏 */
    [self handlerSubviewsLayout:NO];
    /* 页面切换结束 */
    if ([self.delegate respondsToSelector:@selector(pageViewController:didFinishAnimating:index:)])
    {
        [self.delegate pageViewController:self didFinishAnimating:YES index:_curPage];
    }
}

- (void)pageViewControllerRemovePage:(NSInteger)page completion:(void (^)(BOOL))completion
{
    if (page<0 || page>_pageCount-1)
    {
        if (completion) completion(NO);
    }
    else if (_pageCount == 1)
    {
        /* 删除最后一页 */
        if ([self.delegate respondsToSelector:@selector(pageViewController:didRemoveTheLastPage:)]) {
            [self.delegate pageViewController:self didRemoveTheLastPage:_curPage];
        }
    }
    else
    {
        if ((page-_curPage)>1)
        {
            /* 删除当前页后面的，无影响，直接更新数据源 */
            [self reloadDataSource];
            /* 不需要刷新控制器 */
            if (completion) completion(YES);
        }
        else if ((page-_curPage)>=0)
        {
            /* 删除当前页/下一页 */
            /* 判断当前页是否越界 */
            NSInteger waitPage = _curPage;
            if (waitPage >= _pageCount-1) waitPage--;
            [self pageViewControllerScrollToPage:waitPage];
            _curPage = waitPage;
            /* 刷新数据源 */
            [self reloadDataSource];
            if (completion) completion(YES);
        }
        else
        {
            /* 删除当前页前面的页码，当前页码-1，刷新控制器 */
            [self pageViewControllerScrollToPage:_curPage-1];
//            _curPage--;
            /* 刷新数据源 */
            [self reloadDataSource];
            if (completion) completion(YES);
        }
    }
}

- (void)pageViewControllerRemoveCurPage:(void (^)(BOOL))completion
{
    [self pageViewControllerRemovePage:_curPage completion:completion];
}

#pragma mark - 滑动手势处理
- (void)handlePan:(UIPanGestureRecognizer *)recognizer
{
    /* 获取手势移动 */
    CGPoint translation = [recognizer translationInView:self.view];
    /* 显示所有视图 */
    [self handlerSubviewsLayout:YES];
    /* 当前控制器 */
    UIViewController *curVC = [self childViewControllerForIndex:_curPage isLastPage:YES];
    /* 当前页面待移动位置 */
    CGFloat curView_x = recognizer.view.center.x+translation.x;
    if (curView_x>kXGScreenW/2)
    {
        /* 当前页面准备右移 */
        CGFloat oldCurViewCenter_x = recognizer.view.center.x;
        /* 判断上一次是否从下页移动过来 */
        if (oldCurViewCenter_x<kXGScreenW/2)
        {
            UIViewController *nextVC = [self childViewControllerForIndex:_curPage+1 isLastPage:NO];
            /* 下页将要消失 */
            [nextVC beginAppearanceTransition:NO animated:NO];
            /* 当前页将要出现 */
            [curVC beginAppearanceTransition:YES animated:NO];
            /* 下页已经消失 */
            [nextVC endAppearanceTransition];
            /* 当前页已经出现 */
            [curVC endAppearanceTransition];
        }
        /* 固定当前页面不动 */
        recognizer.view.center = CGPointMake(kXGScreenW/2, recognizer.view.center.y);
        /* 判断是否存在上一页，存在则移动上一页 */
        if (_curPage>0)
        {
            /* 存在上一页 */
            UIViewController *lastVC = [self childViewControllerForIndex:_curPage-1 isLastPage:YES];
            UIView *lastView = lastVC.view;
            /* 旧的上页frame */
            CGFloat oldLastViewCenter_x = lastView.center.x;
            /* 新的上页frame */
            CGFloat newLastViewCenter_x = lastView.center.x+translation.x;
            /* 判断位置，控制视图生命周期 */
            if (oldLastViewCenter_x<=-kXGScreenW/2 && newLastViewCenter_x>-kXGScreenW/2)
            {
                /* 当前页将要消失 */
                [curVC beginAppearanceTransition:NO animated:NO];
                /* 上页将要出现 */
                [lastVC beginAppearanceTransition:YES animated:NO];
            }
            /* 设置上一页的位置，在左侧 */
            lastView.center = CGPointMake(newLastViewCenter_x, recognizer.view.center.y);
            /* 设置上一页的层级，最上层 */
            [self.view insertSubview:lastView atIndex:self.childViewControllers.count-1];
        }
    }
    else
    {
        /* 当前页面准备左移 */
        /* 是否存在上一页面，且上一页面不在最左边，则移动上一页面，否则移动当前页面 */
        if (_curPage>0)
        {
            /* 存在上一页面 */
            UIViewController *lastVC = [self childViewControllerForIndex:_curPage-1 isLastPage:YES];
            UIView *lastView = lastVC.view;
            CGFloat oldLastViewCenter_x = lastView.center.x;
            if (oldLastViewCenter_x>-kXGScreenW/2)
            {
                if (_curPage<_pageCount-1)
                {
                    /* 存在下一页 */
                    UIViewController *nextVC = [self childViewControllerForIndex:_curPage+1 isLastPage:NO];
                    UIView *nextView = nextVC.view;
                    /* 设置下一页的位置，在当前页面下 */
                    nextView.center = CGPointMake(kXGScreenW/2, recognizer.view.center.y);
                    [self.view insertSubview:nextView belowSubview:recognizer.view];
                }
                /* 上一页面不在最左边，移动上一页面 */
                CGFloat newLastViewCenter_x = oldLastViewCenter_x+translation.x;
                if (newLastViewCenter_x<=-kXGScreenW/2)
                {
                    /* 上页将要消失 */
                    [lastVC beginAppearanceTransition:NO animated:NO];
                    /* 当前页面将要出现 */
                    [curVC beginAppearanceTransition:YES animated:NO];
                    /* 上页已经消失 */
                    [lastVC endAppearanceTransition];
                    /* 当前页已经出现 */
                    [curVC endAppearanceTransition];
                }
                /* 设置上一页的位置，在左侧 */
                lastView.center = CGPointMake(newLastViewCenter_x, recognizer.view.center.y);
                /* 设置上一页的层级，最上层 */
                [self.view insertSubview:lastView atIndex:self.childViewControllers.count-1];
            }
            else
            {
                /* 判断是否存在下一页面，存在则固定下一页面，移动当前页，不存在则不移动当前页面 */
                if (_curPage<_pageCount-1)
                {
                    /* 存在下一页 */
                    UIViewController *nextVC = [self childViewControllerForIndex:_curPage+1 isLastPage:NO];
                    UIView *nextView = nextVC.view;
                    /* 设置下一页的位置，在当前页面下 */
                    nextView.center = CGPointMake(kXGScreenW/2, recognizer.view.center.y);
                    [self.view insertSubview:nextView belowSubview:recognizer.view];
                    /* 旧的当前视图frame */
                    CGFloat oldCurViewCenter_x = curVC.view.center.x;
                    if (oldCurViewCenter_x>=kXGScreenW/2 && curView_x<kXGScreenW/2)
                    {
                        /* 当前页面将要消失 */
                        [curVC beginAppearanceTransition:NO animated:NO];
                        /* 下一页面将要出现 */
                        [nextVC beginAppearanceTransition:YES animated:NO];
                    }
                    /* 移动当前页面 */
                    recognizer.view.center = CGPointMake(curView_x, recognizer.view.center.y);
                }
                else
                {
                    /* 不存在下一页面，固定当前页 */
                    recognizer.view.center = CGPointMake(kXGScreenW/2, recognizer.view.center.y);
                }
            }
        }
        else
        {
            /* 判断是否存在下一页面，存在则固定下一页面，移动当前页，不存在则不移动当前页面 */
            if (_curPage<_pageCount-1)
            {
                /* 存在下一页 */
                UIViewController *nextVC = [self childViewControllerForIndex:_curPage+1 isLastPage:NO];
                UIView *nextView = nextVC.view;
                /* 设置下一页的位置，在当前页面下 */
                nextView.center = CGPointMake(kXGScreenW/2, recognizer.view.center.y);
                [self.view insertSubview:nextView belowSubview:recognizer.view];
                /* 旧的当前视图frame */
                CGFloat oldCurViewCenter_x = curVC.view.center.x;
                if (oldCurViewCenter_x>=kXGScreenW/2 && curView_x<kXGScreenW/2)
                {
                    /* 当前页面首次消失 */
                    /* 当前页面即将消失 */
                    [curVC beginAppearanceTransition:NO animated:NO];
                    /* 下一页面即将出现 */
                    [nextVC beginAppearanceTransition:YES animated:NO];
                }
                /* 移动当前页面 */
                recognizer.view.center = CGPointMake(curView_x, recognizer.view.center.y);
            }
            else
            {
                /* 不存在下一页面，固定当前页 */
                recognizer.view.center = CGPointMake(kXGScreenW/2, recognizer.view.center.y);
            }
        }
    }
    /* 滑动结束 */
    if ([recognizer state] == UIGestureRecognizerStateEnded || [recognizer state] == UIGestureRecognizerStateFailed || [recognizer state] == UIGestureRecognizerStateCancelled)
    {
        /* 动画开始，禁用手势 */
        self.view.userInteractionEnabled = NO;
        /* 判断当前页的位置 */
        if (recognizer.view.center.x<(kXGScreenW/2-(1-kLeftViewScale)*kXGScreenW))
        {
            /* 将当前页移动到最左边 */
            [UIView animateWithDuration:kAnimationTime animations:^{
                recognizer.view.center = CGPointMake(-kXGScreenW/2, recognizer.view.center.y);
            } completion:^(BOOL finished) {
                /* 如果存在上一页，则将上一页放置最底层 */
                if (_curPage>0)
                {
                    /* 存在上一页 */
                    UIViewController *lastVC = [self childViewControllerForIndex:_curPage-1 isLastPage:YES];
                    UIView *lastView = lastVC.view;
                    /* 设置上一页的位置，在左侧 */
                    lastView.center = CGPointMake(kXGScreenW/2, recognizer.view.center.y);
                    /* 设置上一页的层级，最底层 */
                    [self.view sendSubviewToBack:lastView];
                    /* 刷新上一页，该页为_curPage+2 */
                    [self childViewControllerForIndex:_curPage+2 isLastPage:NO];
                }
                if (_curPage<_pageCount-1)
                {
                    /* 存在下一页 */
                    UIViewController *nextVC = [self childViewControllerForIndex:_curPage+1 isLastPage:NO];
                    UIView *nextView = nextVC.view;
                    [nextView addGestureRecognizer:self.panGesture];
                    _curPage++;
                    /* 当前页已经消失 */
                    [curVC endAppearanceTransition];
                    /* 下页已经出现 */
                    [nextVC endAppearanceTransition];
                }
                /* 处理视图 */
                [self handlerSubviewsLayout:NO];
                /* 成功移动到下一页 */
                if ([self.delegate respondsToSelector:@selector(pageViewController:didFinishAnimating:index:)]) {
                    [self.delegate pageViewController:self didFinishAnimating:YES index:_curPage];
                }
            }];
        }
        else
        {
            /* 当前页未移动，或者移动距离较短 */
            /* 判断当前页是否移动 */
            if (recognizer.view.center.x>=kXGScreenW/2)
            {
                /* 当前页未移动 */
                /* 判断上一页是否移动 */
                if (_curPage>0)
                {
                    UIViewController *lastVC = [self childViewControllerForIndex:_curPage-1 isLastPage:YES];
                    UIView *lastView = lastVC.view;
                    [self.view insertSubview:lastView atIndex:self.childViewControllers.count-1];
                    if (lastView.center.x>-kXGScreenW/2)
                    {
                        /* 上一页移动了，判断移动距离 */
                        if (lastView.center.x>(-kXGScreenW/2+(1-kLeftViewScale)*kXGScreenW))
                        {
                            /* 上一页覆盖当前页 */
                            [UIView animateWithDuration:kAnimationTime animations:^{
                                lastView.center = CGPointMake(kXGScreenW/2, recognizer.view.center.y);
                            } completion:^(BOOL finished) {
                                /* 下一页放置最左边 */
                                /* 最后一页容错处理，若当前为最大页面，则最后一页复用且移动到最左边 */
                                if (_curPage<_pageCount-1 || (_curPage==_pageCount-1 && _maxCount == kMaxCount))
                                {
                                    /* 存在下一页 */
                                    UIViewController *nextVC = [self childViewControllerForIndex:_curPage+1 isLastPage:NO];
                                    UIView *nextView = nextVC.view;
                                    nextView.center = CGPointMake(-kXGScreenW/2, recognizer.view.center.y);
                                    [self.view insertSubview:nextView atIndex:self.childViewControllers.count-1];
                                    /* 刷新下一页，该页为_curPage-2 */
                                    [self childViewControllerForIndex:_curPage-2 isLastPage:YES];
                                }
                                [lastView addGestureRecognizer:self.panGesture];
                                _curPage--;
                                /* 当前页已经消失 */
                                [curVC endAppearanceTransition];
                                /* 上页已经出现 */
                                [lastVC endAppearanceTransition];
                                /* 处理视图 */
                                [self handlerSubviewsLayout:NO];
                                /* 成功移动到上页 */
                                if ([self.delegate respondsToSelector:@selector(pageViewController:didFinishAnimating:index:)]) {
                                    [self.delegate pageViewController:self didFinishAnimating:YES index:_curPage];
                                }
                            }];
                        }
                        else
                        {
                            /* 上一页还原 */
                            [UIView animateWithDuration:kAnimationTime animations:^{
                                lastView.center = CGPointMake(-kXGScreenW/2, recognizer.view.center.y);
                            } completion:^(BOOL finished) {
                                /* 上页将要消失 */
                                [lastVC beginAppearanceTransition:NO animated:NO];
                                /* 当前页将要出现 */
                                [curVC beginAppearanceTransition:YES animated:NO];
                                /* 上页已经消失 */
                                [lastVC endAppearanceTransition];
                                /* 当前页已经出现 */
                                [curVC endAppearanceTransition];
                                /* 处理视图 */
                                [self handlerSubviewsLayout:NO];
                            }];
                        }
                    }
                    else
                    {
                        /* 上一页未移动 */
                        /* 处理视图 */
                        [self handlerSubviewsLayout:NO];
                    }
                }
                else
                {
                    /* 不存在上一页 */
                    recognizer.view.center = CGPointMake(kXGScreenW/2, recognizer.view.center.y);
                    /* 处理视图 */
                    [self handlerSubviewsLayout:NO];
                }
            }
            else
            {
                /* 当前页移动了，还原当前页，判断是否存在上一页，存在则固定上一页 */
                if (_curPage>0)
                {
                    UIViewController *lastVC = [self childViewControllerForIndex:_curPage-1 isLastPage:YES];
                    UIView *lastView = lastVC.view;
                    lastView.center = CGPointMake(-kXGScreenW/2, recognizer.view.center.y);
                    [self.view insertSubview:lastView atIndex:self.childViewControllers.count-1];
                }
                [UIView animateWithDuration:kAnimationTime animations:^{
                    recognizer.view.center = CGPointMake(kXGScreenW/2, recognizer.view.center.y);
                } completion:^(BOOL finished) {
                    UIViewController *nextVC = [self childViewControllerForIndex:_curPage+1 isLastPage:NO];
                    /* 下页将要消失 */
                    [nextVC beginAppearanceTransition:NO animated:NO];
                    /* 当前页将要出现 */
                    [curVC beginAppearanceTransition:YES animated:NO];
                    /* 下页已经消失 */
                    [nextVC endAppearanceTransition];
                    /* 当前页已经出现 */
                    [curVC endAppearanceTransition];
                    /* 处理视图 */
                    [self handlerSubviewsLayout:NO];
                }];
            }
        }
    }
    [recognizer setTranslation:CGPointZero inView:self.view];
}

#pragma mark - setting方法
- (void)setDataSource:(id<XGPageViewControllerDataSource>)dataSource
{
    _dataSource = dataSource;
    [self reloadLayout];
}

- (void)setDelegate:(id<XGPageViewControllerDelegate>)delegate
{
    _delegate = delegate;
    if (_pageCount>0 && [self.delegate respondsToSelector:@selector(pageViewController:didFinishAnimating:index:)])
    {
        [self.delegate pageViewController:self didFinishAnimating:YES index:_curPage];
    }
}

#pragma mark - lazy
- (UIPanGestureRecognizer *)panGesture
{
    if (!_panGesture) {
        _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        _panGesture.delegate = self;
    }
    return _panGesture;
}

- (NSInteger)currentPage
{
    return _curPage;
}

- (NSInteger)numberOfPages
{
    return _pageCount;
}

- (UIViewController *)curChildVC
{
    return [self childViewControllerForIndex:_curPage isLastPage:NO];
}

@end

