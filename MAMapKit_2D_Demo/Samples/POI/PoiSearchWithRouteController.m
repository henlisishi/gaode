//
//  PoiSearchWithRouteController.m
//  MAMapKit_2D_Demo
//
//  Created by xiaoming han on 16/9/5.
//  Copyright © 2016年 Autonavi. All rights reserved.
//

#import "PoiSearchWithRouteController.h"
#import "CommonUtility.h"
#import "MANaviRoute.h"
#import "RoutePOIAnnotation.h"
#import "RoutePOIDetailViewController.h"
#import "ErrorInfoUtility.h"

@interface PoiSearchWithRouteController ()<MAMapViewDelegate, AMapSearchDelegate>

@property (nonatomic, strong) AMapSearchAPI *search;
@property (nonatomic, strong) MAMapView *mapView;
@property (nonatomic, strong) AMapRoute *route;
@property (nonatomic, strong) MANaviRoute *naviRoute;
@property (nonatomic, assign) NSInteger strategy;
@property (nonatomic, strong) UISegmentedControl *segmentControl;

@property (nonatomic) CLLocationCoordinate2D startCoordinate;
@property (nonatomic) CLLocationCoordinate2D destinationCoordinate;

@end

@implementation PoiSearchWithRouteController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.strategy = 0;
    self.startCoordinate        = CLLocationCoordinate2DMake(39.920267, 116.370888);
    self.destinationCoordinate  = CLLocationCoordinate2DMake(39.989872, 116.481956);
    
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
    
    
    [self initToolBar];
    
    //
    [self initDefaultAnnotations];
    [self searchRoutePlanningDrive];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationController.toolbar.barStyle      = UIBarStyleBlack;
    self.navigationController.toolbar.translucent   = YES;
    [self.navigationController setToolbarHidden:NO animated:animated];
}

#pragma mark - MAMapViewDelegate

- (void)mapView:(MAMapView *)mapView annotationView:(MAAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    id<MAAnnotation> annotation = view.annotation;
    
    if ([annotation isKindOfClass:[RoutePOIAnnotation class]])
    {
        RoutePOIAnnotation *poiAnnotation = (RoutePOIAnnotation *)annotation;
        
        RoutePOIDetailViewController *detail = [[RoutePOIDetailViewController alloc] init];
        detail.routePOI = poiAnnotation.poi;
        
        /* 进入POI详情页面. */
        [self.navigationController pushViewController:detail animated:YES];
    }
}

- (MAOverlayRenderer *)mapView:(MAMapView *)mapView rendererForOverlay:(id<MAOverlay>)overlay
{
    if ([overlay isKindOfClass:[LineDashPolyline class]])
    {
        MAPolylineRenderer *polylineRenderer = [[MAPolylineRenderer alloc] initWithPolyline:((LineDashPolyline *)overlay).polyline];
        polylineRenderer.lineWidth   = 8;
        polylineRenderer.lineDashPattern = @[@10, @15];
        polylineRenderer.strokeColor = [UIColor redColor];
        
        return polylineRenderer;
    }
    if ([overlay isKindOfClass:[MANaviPolyline class]])
    {
        MANaviPolyline *naviPolyline = (MANaviPolyline *)overlay;
        MAPolylineRenderer *polylineRenderer = [[MAPolylineRenderer alloc] initWithPolyline:naviPolyline.polyline];
        
        polylineRenderer.lineWidth = 8;
        
        if (naviPolyline.type == MANaviAnnotationTypeWalking)
        {
            polylineRenderer.strokeColor = self.naviRoute.walkingColor;
        }
        else if (naviPolyline.type == MANaviAnnotationTypeRailway)
        {
            polylineRenderer.strokeColor = self.naviRoute.railwayColor;
        }
        else
        {
            polylineRenderer.strokeColor = self.naviRoute.routeColor;
        }
        
        return polylineRenderer;
    }
    
    return nil;
}

- (MAAnnotationView *)mapView:(MAMapView *)mapView viewForAnnotation:(id<MAAnnotation>)annotation
{
    if ([annotation isKindOfClass:[RoutePOIAnnotation class]])
    {
        static NSString *poiIdentifier = @"poiIdentifier";
        MAPinAnnotationView *poiAnnotationView = (MAPinAnnotationView*)[self.mapView dequeueReusableAnnotationViewWithIdentifier:poiIdentifier];
        if (poiAnnotationView == nil)
        {
            poiAnnotationView = [[MAPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:poiIdentifier];
        }
        
        poiAnnotationView.canShowCallout = YES;
        poiAnnotationView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        
        return poiAnnotationView;
    }
    
    if ([annotation isKindOfClass:[MAPointAnnotation class]])
    {
        static NSString *poiIdentifier = @"RouteAnnotationIdentifier";
        MAPinAnnotationView *poiAnnotationView = (MAPinAnnotationView*)[self.mapView dequeueReusableAnnotationViewWithIdentifier:poiIdentifier];
        if (poiAnnotationView == nil)
        {
            poiAnnotationView = [[MAPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:poiIdentifier];
        }
        
        poiAnnotationView.canShowCallout = YES;
        /* 起点. */
        if ([[annotation title] isEqualToString:@"起点"])
        {
            poiAnnotationView.image = [UIImage imageNamed:@"startPoint"];
        }
        /* 终点. */
        else if([[annotation title] isEqualToString:@"终点"])
        {
            poiAnnotationView.image = [UIImage imageNamed:@"endPoint"];
        }
        
        return poiAnnotationView;
    }
    
    return nil;
}

#pragma mark - AMapSearchDelegate

- (void)AMapSearchRequest:(id)request didFailWithError:(NSError *)error
{
    NSLog(@"Error: %@ - %@", error, [ErrorInfoUtility errorDescriptionWithCode:error.code]);
}

/* 路径规划搜索回调. */
- (void)onRouteSearchDone:(AMapRouteSearchBaseRequest *)request response:(AMapRouteSearchResponse *)response
{
    if (response.route == nil)
    {
        return;
    }
    
    if (response.count > 0)
    {
        self.route = response.route;
        [self searchPoiByRoute];
    }
    
}

/* 沿途搜索回调. */
- (void)onRoutePOISearchDone:(AMapRoutePOISearchRequest *)request response:(AMapRoutePOISearchResponse *)response
{
    [self.mapView removeAnnotations:self.mapView.annotations];
    [self initDefaultAnnotations];
    
    if (response.pois.count == 0)
    {
        return;
    }
    
    NSMutableArray *poiAnnotations = [NSMutableArray arrayWithCapacity:response.pois.count];
    
    [response.pois enumerateObjectsUsingBlock:^(AMapRoutePOI *obj, NSUInteger idx, BOOL *stop) {
        
        
        RoutePOIAnnotation *annotation = [[RoutePOIAnnotation alloc] initWithPOI:obj];
        annotation.subtitle   = [self subtitleWithRoutePOI:obj path:self.route.paths.firstObject];
        [poiAnnotations addObject:annotation];
    }];
    
//    添加沿途poi
    [self.mapView addAnnotations:poiAnnotations];
    
//    显示路线
    [self presentCurrentCourse];
}

#pragma mark - Utility

- (NSString *)subtitleWithRoutePOI:(AMapRoutePOI *)poi path:(AMapPath *)path
{
    float distanceDelta = 0.0;
    int durationDelta = 0;
    
    distanceDelta = poi.distance - path.distance;
    durationDelta = (int)(poi.duration - path.duration) / 60;
    
    NSString *distanceUnit = @"米";
    if (distanceDelta >= 1000.0)
    {
        distanceDelta = distanceDelta / 1000.0;
        distanceUnit = @"公里";
    }
    
    return [NSString stringWithFormat:@"+%d分钟 +%.1f%@", durationDelta, distanceDelta, distanceUnit];
}

/* 展示当前路线方案. */
- (void)presentCurrentCourse
{
    if (self.naviRoute == nil)
    {
        self.naviRoute = [MANaviRoute naviRouteForPath:self.route.paths.firstObject withNaviType:MANaviAnnotationTypeDrive showTraffic:NO startPoint:[AMapGeoPoint locationWithLatitude:self.startCoordinate.latitude longitude:self.startCoordinate.longitude] endPoint:[AMapGeoPoint locationWithLatitude:self.destinationCoordinate.latitude longitude:self.destinationCoordinate.longitude]];
        self.naviRoute.anntationVisible = NO;
        
        [self.naviRoute addToMapView:self.mapView];
        
    }
    
    /* 缩放地图使其适应polylines的展示. */
    [self.mapView showOverlays:self.naviRoute.routePolylines animated:YES];
}

- (void)searchPoiByRoute
{
    AMapRoutePOISearchRequest *request = [[AMapRoutePOISearchRequest alloc] init];
    request.origin = [AMapGeoPoint locationWithLatitude:self.startCoordinate.latitude longitude:self.startCoordinate.longitude];
    request.destination = [AMapGeoPoint locationWithLatitude:self.destinationCoordinate.latitude longitude:self.destinationCoordinate.longitude];
    
    request.strategy = self.strategy;
    request.searchType = self.segmentControl.selectedSegmentIndex;
    [self.search AMapRoutePOISearch:request];
}

- (void)searchRoutePlanningDrive
{
    AMapDrivingRouteSearchRequest *navi = [[AMapDrivingRouteSearchRequest alloc] init];
    navi.requireExtension = YES;
    navi.strategy = self.strategy;
    /* 出发点. */
    navi.origin = [AMapGeoPoint locationWithLatitude:self.startCoordinate.latitude
                                           longitude:self.startCoordinate.longitude];
    /* 目的地. */
    navi.destination = [AMapGeoPoint locationWithLatitude:self.destinationCoordinate.latitude
                                                longitude:self.destinationCoordinate.longitude];
    
    [self.search AMapDrivingRouteSearch:navi];
}

- (void)initDefaultAnnotations
{
    MAPointAnnotation *startAnnotation = [[MAPointAnnotation alloc] init];
    startAnnotation.coordinate = self.startCoordinate;
    startAnnotation.title      = @"起点";
    startAnnotation.subtitle   = [NSString stringWithFormat:@"{%f, %f}", self.startCoordinate.latitude, self.startCoordinate.longitude];
    
    MAPointAnnotation *destinationAnnotation = [[MAPointAnnotation alloc] init];
    destinationAnnotation.coordinate = self.destinationCoordinate;
    destinationAnnotation.title      = @"终点";
    destinationAnnotation.subtitle   = [NSString stringWithFormat:@"{%f, %f}", self.destinationCoordinate.latitude, self.destinationCoordinate.longitude];
    [self.mapView addAnnotation:startAnnotation];
    [self.mapView addAnnotation:destinationAnnotation];
}

- (void)initToolBar
{
    UIBarButtonItem *flexbleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    
    UISegmentedControl *segmentControl = [[UISegmentedControl alloc] initWithItems:@[@"加油站", @"维修站", @"ATM", @"厕所"]];
    
    segmentControl.selectedSegmentIndex = 0;
    [segmentControl addTarget:self action:@selector(segmentAction:) forControlEvents:UIControlEventValueChanged];
    
    UIBarButtonItem *mayTypeItem = [[UIBarButtonItem alloc] initWithCustomView:segmentControl];
    self.segmentControl = segmentControl;
    
    self.toolbarItems = [NSArray arrayWithObjects:flexbleItem, mayTypeItem, flexbleItem, nil];
}

#pragma mark - Handle Action

- (void)segmentAction:(UISegmentedControl *)sender
{
    [self searchPoiByRoute];
}

- (void)returnAction
{
    [self.navigationController popViewControllerAnimated:YES];
}

@end
