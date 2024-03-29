//
//  BusStopViewController.m
//  SearchV3Demo
//
//  Created by songjian on 13-8-14.
//  Copyright (c) 2013年 songjian. All rights reserved.
//

#import "BusStopViewController.h"
#import "BusStopAnnotation.h"
#import "BusStopDetailViewController.h"
#import "CommonUtility.h"
#import "ErrorInfoUtility.h"

#define BusStopPlaceHolder @"北京公交站点名称"

@interface BusStopViewController ()<MAMapViewDelegate,AMapSearchDelegate,UISearchBarDelegate>

@property (nonatomic, strong) MAMapView *mapView;
@property (nonatomic, strong) AMapSearchAPI *search;
@property (nonatomic, strong) UISearchBar *searchBar;

@end

@implementation BusStopViewController
@synthesize searchBar = _searchBar;

#pragma mark - Utility

- (void)searchBusStopWithKey:(NSString *)key
{
    if (key.length == 0)
    {
        return;
    }
    
    AMapBusStopSearchRequest *stop = [[AMapBusStopSearchRequest alloc] init];
    stop.keywords = key;
    stop.city     = @"beijing";
    
    [self.search AMapBusStopSearch:stop];
}

- (void)gotoDetailForBusStop:(AMapBusStop *)busStop
{
    if (busStop != nil)
    {
        BusStopDetailViewController *busStopDetailViewController = [[BusStopDetailViewController alloc] init];
        
        busStopDetailViewController.busStop = busStop;
        
        [self.navigationController pushViewController:busStopDetailViewController animated:YES];
    }
}

/* 清空annotation. */
- (void)clear
{
    [self.mapView removeAnnotations:self.mapView.annotations];
}

#pragma mark - AMapSearchDelegate
- (void)AMapSearchRequest:(id)request didFailWithError:(NSError *)error
{
    NSLog(@"Error: %@ - %@", error, [ErrorInfoUtility errorDescriptionWithCode:error.code]);
}

/* 公交站点回调*/
- (void)onBusStopSearchDone:(AMapBusStopSearchRequest *)request response:(AMapBusStopSearchResponse *)response
{
    if (response.busstops.count == 0)
    {
        return;
    }
    
    NSMutableArray *busStopAnnotations = [NSMutableArray array];
    
    [response.busstops enumerateObjectsUsingBlock:^(AMapBusStop *busStop, NSUInteger idx, BOOL *stop) {
        BusStopAnnotation *annotation = [[BusStopAnnotation alloc] initWithBusStop:busStop];
        
        [busStopAnnotations addObject:annotation];
    }];
    
    [self.mapView addAnnotations:busStopAnnotations];
    
    /* 如果只有一个结果，设置其为中心点. */
    if (busStopAnnotations.count == 1)
    {
        self.mapView.centerCoordinate = [busStopAnnotations[0] coordinate];
    }
    /* 如果有多个结果, 设置地图使所有的annotation都可见. */
    else
    {
        self.mapView.visibleMapRect = [CommonUtility minMapRectForAnnotations:busStopAnnotations];
    }
}

#pragma mark - MAMapViewDelegate

- (void)mapView:(MAMapView *)mapView annotationView:(MAAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    if ([view.annotation isKindOfClass:[BusStopAnnotation class]])
    {
        [self gotoDetailForBusStop:[(BusStopAnnotation*)view.annotation busStop]];
    }
}

- (MAAnnotationView *)mapView:(MAMapView *)mapView viewForAnnotation:(id<MAAnnotation>)annotation
{
    if ([annotation isKindOfClass:[BusStopAnnotation class]])
    {
        static NSString *busStopIdentifier = @"busStopIdentifier";
        
        MAPinAnnotationView *poiAnnotationView = (MAPinAnnotationView*)[self.mapView dequeueReusableAnnotationViewWithIdentifier:busStopIdentifier];
        if (poiAnnotationView == nil)
        {
            poiAnnotationView = [[MAPinAnnotationView alloc] initWithAnnotation:annotation
                                                                reuseIdentifier:busStopIdentifier];
        }
        
        poiAnnotationView.canShowCallout = YES;
        poiAnnotationView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        
        return poiAnnotationView;
    }
    
    return nil;
}

#pragma mark UISearchBarDelegate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    [self.searchBar setShowsCancelButton:YES];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    [self.searchBar setShowsCancelButton:NO];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
	[self.searchBar resignFirstResponder];
    
    [self clear];
    
    [self searchBusStopWithKey:searchBar.text];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
	[self.searchBar resignFirstResponder];
}

#pragma mark - action handle
- (void)returnAction
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Initialization

- (void)initSearchBar
{
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectZero];
    self.searchBar.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.searchBar.barStyle     = UIBarStyleBlack;
	self.searchBar.delegate     = self;
    self.searchBar.placeholder  = BusStopPlaceHolder;
    self.searchBar.keyboardType = UIKeyboardTypeDefault;
    
    self.navigationItem.titleView = self.searchBar;
    
    [self.searchBar sizeToFit];
}

#pragma mark - Life Cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back"
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:self
                                                                            action:@selector(returnAction)];
    
    self.mapView = [[MAMapView alloc] initWithFrame:self.view.bounds];
    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.mapView.delegate = self;
    [self.view addSubview:self.mapView];
    
    self.search = [[AMapSearchAPI alloc] init];
    self.search.delegate = self;

    
    [self initSearchBar];
}

@end
