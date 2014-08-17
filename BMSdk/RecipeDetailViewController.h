//
//  RecipeDetailViewController.h
//  BMSdk
//
//  Created by Matteo Comisso on 28/07/14.
//  Copyright (c) 2014 Blue-Mate. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RecipeDetailViewController : UIViewController

@property (nonatomic, strong) NSString *recipeName;
@property (nonatomic, strong) NSString *recipeId;
@property (nonatomic, strong) NSString *recipePrice;
@property (nonatomic, strong) UIImage *recipeImage;

@end
