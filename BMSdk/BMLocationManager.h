//
//  BMLocationManager.h
//  Blue-Mate alpha
//
//  Created by Matteo Comisso on 15/07/14.
//  Copyright (c) 2014 Matteo Comisso. All rights reserved.
//

@import Foundation;
@import CoreLocation;

@interface BMLocationManager : NSObject

+(BMLocationManager *)sharedInstance;

//Warnings if class used incorrectely
+(instancetype)alloc __attribute__((unavailable("alloc not available, call sharedInstance")));
-(instancetype)init __attribute__((unavailable("init not available, call sharedInstance")));
+(instancetype)new __attribute__((unavailable("new not available, call sharedInstance")));

-(void)startRanging;
-(void)stopRanging;
-(void)enterForeground;
-(void)enterBackground;

@property dispatch_group_t dispatchGroup;

@end
