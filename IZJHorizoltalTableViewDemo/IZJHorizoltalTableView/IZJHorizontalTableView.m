//
//  IZJHorizontalTableView.m
//
//  Created by LZY on 2017/12/29.
//  Copyright © 2017年 izijia. All rights reserved.
//

#import "IZJHorizontalTableView.h"

@interface IZJHorizontalTableView()<UICollectionViewDelegateFlowLayout,UICollectionViewDataSource>

@property (nonatomic, strong) UICollectionView *contentView;

@property (nonatomic, strong) NSMutableArray *scrollViews;

@end

static char currentScrollViewKey;
static CGFloat const TableViewPlainHeaderAndFooterHeight = 28.0;
static CGFloat const TableViewGroupHeaderAndFooterHeight = 17.5;

@implementation IZJHorizontalTableView
{
    CGFloat        _itemCount;
    CGFloat        _currentContentOffsetY;
    UIScrollView  *_currentScrollView;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self setUp];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if(self = [super initWithCoder:aDecoder]){
        [self setUp];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame style:(UITableViewStyle)style
{
    if (self = [super initWithFrame:frame style:style]) {
        [self setUp];
    }
    return self;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    
    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]] && [otherGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        UIPanGestureRecognizer *pan1 = (UIPanGestureRecognizer *)gestureRecognizer;
        UIPanGestureRecognizer *pan2 = (UIPanGestureRecognizer *)otherGestureRecognizer;
        CGPoint p1 =  [pan1 velocityInView:self];
        CGPoint p2 = [pan2 velocityInView:self];
        if (ABS(p1.x)== 0.f || ABS(p2.x)== 0.f) {
            return YES;
        }
        if (ABS(p1.y)== 0.f || ABS(p2.y)== 0.f) {
            return NO;
        }
        if ((ABS(p1.x) / ABS(p1.y) > 1.5) || (ABS(p2.x) / ABS(p2.y) > 1.5)) {
            return NO;
        }
        return YES;
    }else{
        return NO;
    }
    
}

- (void)setUp
{
    [self setUpInitData];
}

- (void)setUpInitData
{
    _itemCount = 0;
    _currentContentOffsetY = 0;
    _verticalViewTotalHeight = CGFLOAT_MAX;
    _currentScrollView = nil;
}

- (void)reloadData
{
    if (self.verticalViewTotalHeight == CGFLOAT_MAX) {
        self.verticalViewTotalHeight = 0;
        UIView *tableViewHeader = self.tableHeaderView;
        if (tableViewHeader) {
            self.verticalViewTotalHeight += tableViewHeader.bounds.size.height;
        }else if (self.style == UITableViewStyleGrouped){
            self.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, CGFLOAT_MIN)];
        }
        
        NSInteger section = 1;
        if ([self.dataSource respondsToSelector:@selector(numberOfSectionsInTableView:)]) {
           section = [self.dataSource numberOfSectionsInTableView:self];
        }
        if ([self.delegate respondsToSelector:@selector(tableView:viewForHeaderInSection:)]) {
            for (int i = 0; i < section; i++) {
                CGFloat sectionHeight = self.style == UITableViewStylePlain ? TableViewPlainHeaderAndFooterHeight : TableViewGroupHeaderAndFooterHeight;
                if ([self.delegate respondsToSelector:@selector(tableView:heightForHeaderInSection:)]) {
                    sectionHeight =  [self.delegate tableView:self heightForHeaderInSection:i];
                }
                self.verticalViewTotalHeight += sectionHeight;
            }
        }else if (self.style == UITableViewStyleGrouped){
            if (section > 1) {
                self.verticalViewTotalHeight += TableViewGroupHeaderAndFooterHeight * (section - 1);
            }
        }
        if ([self.delegate respondsToSelector:@selector(tableView:viewForFooterInSection:)]) {
            for (int i = 0; i < section; i++) {
                 CGFloat sectionHeight = self.style == UITableViewStylePlain ? TableViewPlainHeaderAndFooterHeight : TableViewGroupHeaderAndFooterHeight;
                if ([self.delegate respondsToSelector:@selector(tableView:heightForFooterInSection:)]) {
                    sectionHeight =  [self.delegate tableView:self heightForFooterInSection:i];
                }
                self.verticalViewTotalHeight += sectionHeight;
            }
        }else if (self.style == UITableViewStyleGrouped){
                self.verticalViewTotalHeight += TableViewGroupHeaderAndFooterHeight * section;
        }
        if ([self.delegate respondsToSelector:@selector(tableView:heightForRowAtIndexPath:)]) {
            for (int i = 0; i < section; i++) {
                NSInteger row = [self.dataSource tableView:self numberOfRowsInSection:i];
                for (int i = 0; i < row; i++) {
                    CGFloat rowHeight = [self.delegate tableView:self heightForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section]];
                    self.verticalViewTotalHeight += rowHeight;
                }
            }
        }
    }
    _itemCount = [self.dataSourceHorizontal numberOfItemsInHorizontalTablesView:self];
    if (_itemCount < 1) {
        return;
    }
    [self.scrollViews removeAllObjects];
    for (int i = 0; i < _itemCount; i++) {
        UIScrollView *sv = [self.dataSourceHorizontal horizontalTablesView:self contentScrollViewAtIndex:i];
        [self.scrollViews addObject:sv];
    }
    [self reloadSegmentData];
    [self reloadHorizontalData];
    [self addobserverForCurrentScrollViewWithIndex:0];
}


- (void)reloadSegmentData
{
    [self layoutIfNeeded];
    UIView *v = [[UIView alloc] init];
    v.frame = self.bounds;
    [v addSubview:self.contentView];
    if ([self.delegateHorizontal respondsToSelector:@selector(segmentViewInHorizontalTablesView:)]) {
        UIView *segment = [self.delegateHorizontal segmentViewInHorizontalTablesView:self];
        [v addSubview:segment];
        CGFloat segmentHeight = segment.frame.size.height;
        if ([self.delegateHorizontal respondsToSelector:@selector(heightForSegmentViewInHorizontalTablesView:)]) {
            segmentHeight = [self.delegateHorizontal heightForSegmentViewInHorizontalTablesView:self];
        }
        
        segment.translatesAutoresizingMaskIntoConstraints = NO;
        NSLayoutConstraint *leftSegmentConstraint = [NSLayoutConstraint constraintWithItem:segment attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:v attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0];
        NSLayoutConstraint *rightSegmentConstraint = [NSLayoutConstraint constraintWithItem:segment attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:v attribute:NSLayoutAttributeRight multiplier:1.0 constant:0];
        NSLayoutConstraint *topSegmentConstraint = [NSLayoutConstraint constraintWithItem:segment attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:v attribute:NSLayoutAttributeTop multiplier:1.0 constant:0];
        NSLayoutConstraint *heightSegmentConstraint = [NSLayoutConstraint constraintWithItem:segment attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:0.0 constant:segmentHeight];
        [v addConstraint:leftSegmentConstraint];
        [v addConstraint:rightSegmentConstraint];
        [v addConstraint:topSegmentConstraint];
        [segment addConstraint:heightSegmentConstraint];
        
        
        self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
        NSLayoutConstraint *leftContentViewConstraint = [NSLayoutConstraint constraintWithItem:self.contentView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:v attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0];
        NSLayoutConstraint *rightContentViewConstraint = [NSLayoutConstraint constraintWithItem:self.contentView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:v attribute:NSLayoutAttributeRight multiplier:1.0 constant:0];
        NSLayoutConstraint *bottomContentViewConstraint = [NSLayoutConstraint constraintWithItem:self.contentView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:v attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0];

        NSLayoutConstraint *topContentViewConstraint = [NSLayoutConstraint constraintWithItem:self.contentView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:segment attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0];
        [v addConstraint:leftContentViewConstraint];
        [v addConstraint:rightContentViewConstraint];
        [v addConstraint:topContentViewConstraint];
        [v addConstraint:bottomContentViewConstraint];
        
    }else{
        self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
        NSLayoutConstraint *leftContentViewConstraint = [NSLayoutConstraint constraintWithItem:self.contentView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:v attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0];
        NSLayoutConstraint *rightContentViewConstraint = [NSLayoutConstraint constraintWithItem:self.contentView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:v attribute:NSLayoutAttributeRight multiplier:1.0 constant:0];
        NSLayoutConstraint *bottomContentViewConstraint = [NSLayoutConstraint constraintWithItem:self.contentView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:v attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0];
        
        NSLayoutConstraint *topContentViewConstraint = [NSLayoutConstraint constraintWithItem:self.contentView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:v attribute:NSLayoutAttributeTop multiplier:1.0 constant:0];
        
        [v addConstraint:leftContentViewConstraint];
        [v addConstraint:rightContentViewConstraint];
        [v addConstraint:topContentViewConstraint];
        [v addConstraint:bottomContentViewConstraint];
        

    }
    self.tableFooterView = v;
    [super   reloadData];
}

- (void)reloadHorizontalData
{
    [self.contentView reloadData];
}

- (void)scrollToHorizontalItemAtIndex:(NSInteger)index animation:(BOOL)animation
{
    if (index < 0 || index > self.scrollViews.count - 1) {
        return;
    }
    [self.contentView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] atScrollPosition:UICollectionViewScrollPositionLeft animated:animation];
    [self addobserverForCurrentScrollViewWithIndex:index];
}

#pragma mark - UICollectionViewDataSource && UICollectionViewDelegate
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _itemCount;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    UIScrollView *scrollView = self.scrollViews[indexPath.row];
    NSArray *subs = cell.contentView.subviews;
    if (subs && subs.count > 0) {
        UIView *v = subs.firstObject;
        if (v != scrollView) {
            [v removeFromSuperview];
            goto end;
        }
    }else{
        end:{
            [cell.contentView addSubview:scrollView];
            scrollView.translatesAutoresizingMaskIntoConstraints = NO;
            NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:scrollView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:cell.contentView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0];
            NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem:scrollView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:cell.contentView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0];
            NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:scrollView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:cell.contentView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0];
            NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint constraintWithItem:scrollView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:cell.contentView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0];
            [cell.contentView addConstraint:leftConstraint];
            [cell.contentView addConstraint:rightConstraint];
            [cell.contentView addConstraint:topConstraint];
            [cell.contentView addConstraint:bottomConstraint];
        }
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        scrollView.contentOffset = CGPointZero;
    });
    
    [cell layoutIfNeeded];
    return cell;
}


- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return collectionView.bounds.size;
}


#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if (scrollView == self.contentView) {
        NSInteger index = scrollView.contentOffset.x / scrollView.bounds.size.width;
        if (index < 0 || index > self.scrollViews.count - 1) {
            return;
        }
        [self addobserverForCurrentScrollViewWithIndex:index];
    }
}


- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView == self.contentView) {
        if (self.delegateHorizontal && [self.delegateHorizontal respondsToSelector:@selector(horizontalscrollViewDidScroll:)]) {
            [self.delegateHorizontal horizontalscrollViewDidScroll:self.contentView];
        }
    }
}


#pragma mark - private
- (void)addobserverForCurrentScrollViewWithIndex:(NSInteger)index
{
    if (_currentScrollView) {
        [_currentScrollView removeObserver:self forKeyPath:@"contentOffset"];
    }
    _currentScrollView  = self.scrollViews[index];
    [_currentScrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:&currentScrollViewKey];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    CGPoint tableOffset = [[change objectForKey:@"new"] CGPointValue];
    if (context == &currentScrollViewKey) {
        _currentContentOffsetY = tableOffset.y;
        if (self.contentOffset.y < self.verticalViewTotalHeight) {
            if (_currentContentOffsetY != 0) {
                _currentScrollView.contentOffset = CGPointZero;
            }
        }
    }else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}


#pragma mark - setter
- (void)setContentOffset:(CGPoint)contentOffset
{
    [super setContentOffset:contentOffset];
    if (_currentScrollView && _currentScrollView.contentOffset.y > 0) {
        if (contentOffset.y != self.verticalViewTotalHeight) {
            self.contentOffset = CGPointMake(0, self.verticalViewTotalHeight);
        }
    }
}

#pragma mark - getter
- (NSInteger)currentHorizontalItemIndex
{
    if (_currentScrollView) {
        return [self.scrollViews indexOfObject:_currentScrollView];
    }else{
        return -1;
    }
}


#pragma mark - lazy
- (UICollectionView *)contentView
{
    if (!_contentView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.minimumInteritemSpacing = 0;
        layout.minimumLineSpacing      = 0;
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        _contentView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        [_contentView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"cell"];
        _contentView.dataSource = self;
        _contentView.delegate   = self;
        _contentView.pagingEnabled = YES;
         _contentView.alwaysBounceVertical = NO;
        _contentView.alwaysBounceHorizontal = NO;
        _contentView.showsVerticalScrollIndicator = NO;
        _contentView.showsHorizontalScrollIndicator = NO;
        if (@available(iOS 10.0, *)) {
            _contentView.prefetchingEnabled = NO;
        }
    }
    return _contentView;
}

- (NSMutableArray *)scrollViews
{
    if (!_scrollViews) {
        _scrollViews = @[].mutableCopy;
    }
    return _scrollViews;
}

- (void)dealloc
{
    if (_currentScrollView) {
        [_currentScrollView removeObserver:self forKeyPath:@"contentOffset"];
    }
}

@end
