//
//  RoutePOIAnnotation.m
//  MAMapKit_2D_Demo
//
//  Created by xiaoming han on 16/9/5.
//  Copyright © 2016年 Autonavi. All rights reserved.
//

#import "RoutePOIAnnotation.h"

@interface RoutePOIAnnotation ()

@property (nonatomic, readwrite, strong) AMapRoutePOI *poi;

@end

@implementation RoutePOIAnnotation

#pragma mark - MAAnnotation Protocol

- (NSString *)title
{
    return self.poi.name;
}

- (CLLocationCoordinate2D)coordinate
{
    return CLLocationCoordinate2DMake(self.poi.location.latitude, self.poi.location.longitude);
}

#pragma mark - Life Cycle

- (id)initWithPOI:(AMapRoutePOI *)poi
{
    if (self = [super init])
    {
        self.poi = poi;
    }
    
    return self;
}


@end
