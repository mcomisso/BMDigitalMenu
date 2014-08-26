//
//  MenuListCell.h
//  BMSdk
//
//  Created by Matteo Comisso on 28/07/14.
//  Copyright (c) 2014 Blue-Mate. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RateView/RateView.h"

@interface MenuListCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UIImageView *recipeImage;
@property (strong, nonatomic) NSString *recipeImageUrl;
@property (strong, nonatomic) IBOutlet RateView *rating;
@property (strong, nonatomic) IBOutlet UILabel *recipeTitle;
@property (strong, nonatomic) IBOutlet UILabel *recipePrice;
@property (strong, nonatomic) NSString *recipeId;

@end
