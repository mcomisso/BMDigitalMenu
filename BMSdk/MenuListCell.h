//
//  MenuListCell.h
//  BMSdk
//
//  Created by Matteo Comisso on 28/07/14.
//  Copyright (c) 2014 Blue-Mate. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AXRatingView.h"
@interface MenuListCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UIImageView *recipeImage;
@property (strong, nonatomic) IBOutlet UILabel *recipeTitle;
@property (strong, nonatomic) IBOutlet UILabel *recipePrice;
@property (strong, nonatomic) IBOutlet UIView *rateViewContainer;
@property (strong, nonatomic) AXRatingView *ratingView;

@property (strong, nonatomic) NSString *recipeId;
@property (strong, nonatomic) NSString *recipeImageUrl;

@end
