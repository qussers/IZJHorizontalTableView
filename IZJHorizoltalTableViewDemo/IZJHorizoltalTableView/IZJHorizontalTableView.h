//
//  IZJHorizontalTableView.h
//
//  Created by LZY on 2017/12/29.
//  Copyright © 2017年 izijia. All rights reserved.
//

#import <UIKit/UIKit.h>

@class IZJHorizontalTableView;

@protocol IZJHorizontalTableViewDataSource <NSObject>

@required;

//水平子视图数量
- (NSInteger)numberOfItemsInHorizontalTablesView:(IZJHorizontalTableView *)horizontalTablesView;

//水平子视图
- (UIScrollView *)horizontalTablesView:(IZJHorizontalTableView *)horizontalTablesView contentScrollViewAtIndex:(NSInteger)index;


@end

@protocol IZJHorizontalTableViewDelegate <NSObject>

@optional;

//停驻视图
- (UIView *)segmentViewInHorizontalTablesView:(IZJHorizontalTableView *)horizontalTablesView;

//停驻视图高度
- (CGFloat)heightForSegmentViewInHorizontalTablesView:(IZJHorizontalTableView *)horizontalTablesView;

//水平切换偏移
- (CGFloat)horizontalscrollViewDidScroll:(UIScrollView *)scrollView;


@end

@interface IZJHorizontalTableView : UITableView


@property (nonatomic, weak) id<IZJHorizontalTableViewDataSource> dataSourceHorizontal;

@property (nonatomic, weak) id<IZJHorizontalTableViewDelegate> delegateHorizontal;

@property (nonatomic, assign, readonly) NSInteger currentHorizontalItemIndex;

//垂直视图总高度。如不设置，将自动计算高度
@property (nonatomic, assign) CGFloat verticalViewTotalHeight;

- (void)reloadHorizontalData;

- (void)reloadSegmentData;

//滑动到第几个水平视图
- (void)scrollToHorizontalItemAtIndex:(NSInteger)index animation:(BOOL)animation;


@end
