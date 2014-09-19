//
//  NoImageTableViewCell.h
//  BMSdk
//
//  Created by Matteo Comisso on 06/09/14.
//  Copyright (c) 2014 Blue-Mate. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AXRatingView.h"

@interface NoImageTableViewCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UILabel *recipeTitle;
@property (strong, nonatomic) IBOutlet UILabel *recipePrice;
@property (strong, nonatomic) IBOutlet UIView *rateViewContainer;
@property (strong, nonatomic) AXRatingView *ratingView;
@property (strong, nonatomic) IBOutlet UILabel *recipeIngredients;

@property (strong, nonatomic) NSString *recipeId;


@end
