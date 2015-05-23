//
//  BMUsageStatisticModel.h
//  BMSdk
//
//  Created by Matteo Comisso on 14/10/14.
//  Copyright (c) 2014 Blue-Mate. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BMUsageStatisticModel : NSObject

@property (nonatomic, strong, readonly) NSMutableDictionary *analyticsData;

+(instancetype)alloc __attribute__((unavailable("alloc not available, call sharedInstance")));
+(instancetype)new __attribute__((unavailable("new not available, call sharedInstance")));
-(instancetype)init __attribute__((unavailable("init not available, call sharedInstance")));


/**
 Starts a new session, deleting the current
 */
-(void)reinitialize;

/**
 Saves the temporary data inside the database.
 */
-(void)saveLocally:(NSDictionary *)localRecord;

/**
 Loads the temporary data in context to be used and edited.
 */
-(void)restore;


@end
