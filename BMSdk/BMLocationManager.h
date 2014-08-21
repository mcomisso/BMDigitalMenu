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


@property (nonatomic, strong, readonly) NSString *latestRestarauntID;

/**
 Instantiate a BMLocationManager object. Call only this method to create.
 */
+(BMLocationManager *)sharedInstance;

//Warnings if class used incorrectely
+(instancetype)alloc __attribute__((unavailable("alloc not available, call sharedInstance")));
-(instancetype)init __attribute__((unavailable("init not available, call sharedInstance")));
+(instancetype)new __attribute__((unavailable("new not available, call sharedInstance")));

/**
 Ask the Location Manager to start ranging the Blue-Mate region.
 */
-(void)startRanging;

/**
 Ask the Location Manager to stop ranging the Blue-Mate region.
 */
-(void)stopRanging;

/**
 Warns the Location Manager that the app is going in foreground mode.
 */
-(void)enterForeground;

/**
 Warns the Location Manager that the app is going in background mode.
 */
-(void)enterBackground;

#pragma mark - external methods

/**
 Method to activate an external UX element. Use the return value YES|NO to activate or deactivate a interface element, such a button.
 */
-(BOOL)canStartInterface;

@property dispatch_group_t dispatchGroup;

@end
