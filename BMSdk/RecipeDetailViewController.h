//
//  RecipeDetailViewController.h
//  BMSdk
//
//  Created by Matteo Comisso on 28/07/14.
//  Copyright (c) 2014 Blue-Mate. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RecipeDetailViewController : UIViewController<UIViewControllerTransitioningDelegate>

@property (nonatomic, strong) NSString *recipeName;
@property (nonatomic, strong) NSString *recipeSlug;
@property (nonatomic, strong) NSString *recipePrice;
@property (nonatomic, strong) NSString *recipeImageUrl;
@property (strong, nonatomic) IBOutlet UIImageView *recipeImageView;

@end
