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

@property (weak, nonatomic) IBOutlet UIImageView *recipeImage;
@property (weak, nonatomic) IBOutlet UILabel *recipeTitle;
@property (weak, nonatomic) IBOutlet UILabel *recipePrice;
@property (weak, nonatomic) IBOutlet UIView *rateViewContainer;
@property (strong, nonatomic) AXRatingView *ratingView;

@property (strong, nonatomic) IBOutlet UIView *whiteViewContainer;

@property (strong, nonatomic) NSString *recipeId;
@property (strong, nonatomic) NSString *recipeImageUrl;

@property (nonatomic) BOOL canWhiteViewBeMovedLeft;
@property (nonatomic) BOOL canWhiteViewBeMovedRight;

@end
