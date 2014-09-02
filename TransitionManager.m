//
//  TransitionManager.m
//  BMSdk
//
//  Created by Matteo Comisso on 01/09/14.
//  Copyright (c) 2014 Blue-Mate. All rights reserved.
//

#import "TransitionManager.h"
#import "UIImage+ImageEffects.h"

@implementation TransitionManager

-(NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    return 1.f;
}

-(void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    if (self.transitionTo == MODAL) {
        NSLog(@"Transition Started");
        
        float width = fromVC.view.frame.size.width;
        float height = fromVC.view.frame.size.height;
        
        UIImage *blurredSourceImage = [TransitionManager blurredImageOfView:fromVC.view];
        UIImageView *blurredImageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, height, width, 0)];
        
        if (blurredSourceImage == nil) {
            blurredImageView.backgroundColor = [UIColor clearColor];
        }
        
        blurredImageView.clipsToBounds = YES;
        blurredImageView.contentMode = UIViewContentModeBottom;
        blurredImageView.image = blurredSourceImage;
        blurredImageView.alpha = 0.f;
        blurredImageView.frame = fromVC.view.frame;
        
        CGPoint final_toVC_Center = toVC.view.center;
        
        toVC.view.center = CGPointMake(final_toVC_Center.x + fromVC.view.frame.size.width, final_toVC_Center.y);

        UIView *container = [transitionContext containerView];
        
        [container insertSubview:blurredImageView aboveSubview:fromVC.view];
        [container insertSubview:toVC.view aboveSubview:blurredImageView];
        
        [UIView animateWithDuration:0.6
                              delay:0.0
             usingSpringWithDamping:0.0
              initialSpringVelocity:0.0
                            options:UIViewAnimationOptionCurveEaseIn
         
                         animations:^{
                             
                             toVC.view.center = final_toVC_Center;
                             toVC.view.alpha = 1.f;
                             blurredImageView.alpha = 1.f;
                         }
                         completion:^(BOOL finished) {
                             [transitionContext completeTransition:YES];
                         }];
        }
    
    else
    {
        UIView *container = [transitionContext containerView];
        [container insertSubview:toVC.view aboveSubview:fromVC.view];
        
        NSLog(@"%@",[container subviews]);
        
        float width = fromVC.view.frame.size.width;
        float height = fromVC.view.frame.size.height;
        
        UIImage *blurredSourceImage = [TransitionManager blurredImageOfView:fromVC.view];
        UIImageView *blurredImageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, height, width, 0)];
        
        if (blurredSourceImage == nil) {
            blurredImageView.backgroundColor = [UIColor clearColor];
        }
        
        blurredImageView.clipsToBounds = YES;
        blurredImageView.contentMode = UIViewContentModeBottom;
        blurredImageView.image = blurredSourceImage;
        blurredImageView.alpha = 1.f;
        blurredImageView.frame = fromVC.view.frame;
        
        [container insertSubview:blurredImageView aboveSubview:fromVC.view];
        
        // Going Back
        [UIView animateWithDuration:0.6
                              delay:0.0
             usingSpringWithDamping:0.0
              initialSpringVelocity:0.0
                            options:UIViewAnimationOptionCurveEaseOut

                         animations:^{
                             fromVC.view.center = CGPointMake(fromVC.view.center.x + 320, fromVC.view.center.y);
                             blurredImageView.alpha = 0.f;
                             
                         }
                         completion:^(BOOL finished) {
                             [transitionContext completeTransition:YES];
                         }];
    }
}

+(UIImage *)blurredImageOfView:(UIView *)view
{
    UIGraphicsBeginImageContextWithOptions(view.frame.size, YES, [[UIScreen mainScreen]scale]);
    
    BOOL success = [view drawViewHierarchyInRect:CGRectMake(0, 0, view.frame.size.width, view.frame.size.height) afterScreenUpdates:NO];
    
    if (success) {
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        UIImage *blurredImage = [image applyLightEffect];
        return blurredImage;
    }
    else
    {
        return nil;
    }
    
}

@end
