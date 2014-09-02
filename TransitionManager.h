//
//  TransitionManager.h
//  BMSdk
//
//  Created by Matteo Comisso on 01/09/14.
//  Copyright (c) 2014 Blue-Mate. All rights reserved.
//

#import <Foundation/Foundation.h>
@import UIKit;

typedef NS_ENUM(NSUInteger, TransitionStep)
{
    INITIAL = 0,
    MODAL
};

@interface TransitionManager : NSObject <UIViewControllerAnimatedTransitioning>

@property (nonatomic, assign) TransitionStep transitionTo;

+(UIImage *)blurredImageOfView:(UIView *)view;

@end
