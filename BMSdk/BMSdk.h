//
//  BMSdk.h
//  BMSdk
//
//  Created by Matteo Comisso on 17/07/14.
//  Copyright (c) 2014 Blue-Mate. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BMSdk : NSObject

/**
 The start method instantiates the framework.
 */
-(void)start;

-(NSDictionary *)handleNotificationOrReturn:(NSDictionary *)userInfo;

@end
