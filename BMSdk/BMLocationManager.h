//
//  BMLocationManager.h
//  Blue-Mate alpha
//
//  Created by Matteo Comisso on 15/07/14.
//  Copyright (c) 2014 Matteo Comisso. All rights reserved.
//
/*
 DESCRIPTION:

 Singleton class.
 È usata app-wide per monitorare la presenza o meno di una area geografica determinata dall'emissione BT-LE di un iBeacon

 La classe BMLocationManager implementa il delegate della CLLocationManager, specificando i metodi per l'entrata o l'uscita dall'area e le azioni da compiere in caso di passaggi di stato.

 */
@import Foundation;
@import CoreLocation;

@interface BMLocationManager : NSObject


@property (nonatomic, strong, readonly) NSString *latestRestaurantID;

/**
 Method to activate an external UX element. Use the return value YES|NO to activate or deactivate a interface element, such a button.
 */
@property (nonatomic, readonly) BOOL canStartInterface;

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

@property dispatch_group_t dispatchGroup;

@end
