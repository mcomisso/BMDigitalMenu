//
//  cartTableViewCell.h
//  BMSdk
//
//  Created by Matteo Comisso on 27/08/14.
//  Copyright (c) 2014 Blue-Mate. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface cartTableViewCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UILabel *recipeName;
@property (strong, nonatomic) IBOutlet UIImageView *recipeImageView;
@property (strong, nonatomic) NSString *recipeSlug;
@property (strong, nonatomic) IBOutlet UILabel *recipePrice;
@property (weak, nonatomic) IBOutlet UILabel *recipeCategory;

@end
