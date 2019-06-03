//
//  RoutePOIDetailViewController.m
//  MAMapKit_2D_Demo
//
//  Created by xiaoming han on 16/9/5.
//  Copyright © 2016年 Autonavi. All rights reserved.
//

#import "RoutePOIDetailViewController.h"

@interface RoutePOIDetailViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *titleArray;
@property (nonatomic, strong) NSArray *subTitleArray;

@end

@implementation RoutePOIDetailViewController

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.titleArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *busLineDetailCellIdentifier = @"routePOIDetailCellIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:busLineDetailCellIdentifier];
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:busLineDetailCellIdentifier];
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType  = UITableViewCellAccessoryNone;
    
    cell.textLabel.text         = self.titleArray[indexPath.row];
    cell.detailTextLabel.text   = self.subTitleArray[indexPath.row];
    
    return cell;
}

#pragma mark - Initialization

- (void)initTableData
{
    self.subTitleArray = @[[NSString stringWithFormat:@"%@", self.routePOI.uid],
                           [NSString stringWithFormat:@"%@", self.routePOI.name],
                           [NSString stringWithFormat:@"%@", self.routePOI.location.description],
                           [NSString stringWithFormat:@"%ld 米", (long)self.routePOI.distance],
                           [NSString stringWithFormat:@"%ld 秒", (long)self.routePOI.duration],
                           ];
    self.titleArray = @[@"唯一id(uid)", @"名称(name)", @"经纬度(location)", @"距离(distance)", @"时间(duration)"];
}

- (void)initTableView
{
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.tableView.delegate   = self;
    self.tableView.dataSource = self;
    
    [self.view addSubview:self.tableView];
}

- (void)initTitle:(NSString *)title
{
    UILabel *titleLabel = [[UILabel alloc] init];
    
    titleLabel.backgroundColor  = [UIColor clearColor];
    titleLabel.textColor        = [UIColor whiteColor];
    titleLabel.text             = title;
    [titleLabel sizeToFit];
    
    self.navigationItem.titleView = titleLabel;
}

#pragma mark - Life Cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self initTitle:@"沿途兴趣点 (AMapRoutePOI)"];
    
    [self initTableData];
    
    [self initTableView];
}

@end
