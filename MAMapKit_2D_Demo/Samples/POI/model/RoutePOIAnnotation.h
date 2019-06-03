//
//  RoutePOIAnnotation.h
//  MAMapKit_2D_Demo
//
//  Created by xiaoming han on 16/9/5.
//  Copyright © 2016年 Autonavi. All rights reserved.
//

#import <MAMapKit/MAMapKit.h>
#import <AMapSearchKit/AMapCommonObj.h>

@interface RoutePOIAnnotation : NSObject<MAAnnotation>

- (id)initWithPOI:(AMapRoutePOI *)poi;

@property (nonatomic, readonly) AMapRoutePOI *poi;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;

@end
