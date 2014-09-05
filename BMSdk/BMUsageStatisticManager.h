//
//  BMUsageStatisticManager.h
//  BMSdk
//
//  Created by Matteo Comisso on 04/09/14.
//  Copyright (c) 2014 Blue-Mate. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BMUsageStatisticManager : NSObject

+(instancetype)alloc __attribute__((unavailable("alloc not available, call sharedInstance")));
-(instancetype)init __attribute__((unavailable("init not available, call sharedInstance")));
+(instancetype)new __attribute__((unavailable("new not available, call sharedInstance")));


+(BMUsageStatisticManager *)sharedInstance;

// COLLECT DATA TO PRESERVE
-(void)collectDescription:(NSString *)description withKey:(NSString *)key;



// SEND DATA AS JSON




@end
