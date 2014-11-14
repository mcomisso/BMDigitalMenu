//
//  RestarauntInfo.h
//  BMSdk
//
//  Created by Matteo Comisso on 07/11/14.
//  Copyright (c) 2014 Blue-Mate. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RestaurantInfo : NSObject

@property (nonatomic, strong) NSString *slug;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSNumber *majorBeacon;
@property (nonatomic, strong) NSNumber *minorBeacon;

@end
