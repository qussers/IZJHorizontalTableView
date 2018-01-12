//
//  ViewController.m
//  IZJHorizoltalTableView
//
//  Created by LZY on 2018/1/5.
//  Copyright © 2018年 coodingOrg. All rights reserved.
//

#import "ViewController.h"
#import "IZJHorizontalTableView.h"
@interface ViewController ()<UITableViewDataSource,UITableViewDelegate,IZJHorizontalTableViewDelegate,IZJHorizontalTableViewDataSource>

@property (nonatomic, strong) IZJHorizontalTableView *tableView;

@property (nonatomic, strong) NSMutableArray *tableViews;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView = [[IZJHorizontalTableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.dataSourceHorizontal = self;
    self.tableView.delegateHorizontal = self;
    [self.view addSubview:self.tableView];
    
    self.tableViews = @[].mutableCopy;
    
    for (int i = 0; i < 10; i++) {
        UITableView *tableview = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
          [tableview registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell2"];
        tableview.dataSource = self;
        tableview.delegate = self;
        [self.tableViews addObject:tableview];
    }
    

}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.tableView) {
        return 50;
    }else{
        return 100;
    }
  
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.tableView) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
        cell.textLabel.text = [NSString stringWithFormat:@"我是垂直的cell%@ 还可以自定义header。footer。等plain。group效果哦",@(indexPath.row)];
        return cell;
    }else{
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell2" forIndexPath:indexPath];
        cell.textLabel.text = [NSString stringWithFormat:@"我是水平的cell%@    快【横向】滑动我",@(indexPath.row)];
        return cell;
    }

}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

- (NSInteger)numberOfItemsInHorizontalTablesView:(IZJHorizontalTableView *)horizontalTablesView
{
    return 10;
}

- (UIScrollView *)horizontalTablesView:(IZJHorizontalTableView *)horizontalTablesView contentScrollViewAtIndex:(NSInteger)index
{
    return self.tableViews[index];
}


- (UIView *)segmentViewInHorizontalTablesView:(IZJHorizontalTableView *)horizontalTablesView
{
    UILabel *l = [[UILabel alloc] init];
    l.text = @"  华丽丽的分隔线，我可以各种自定义哦";
    l.backgroundColor = [UIColor lightGrayColor];
    
    return l;
}


- (CGFloat)heightForSegmentViewInHorizontalTablesView:(IZJHorizontalTableView *)horizontalTablesView
{
    return 60;
}
@end
