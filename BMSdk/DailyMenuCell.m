//
//  DailyMenuCell.m
//  BMSdk
//
//  Created by Matteo Comisso on 18/09/14.
//  Copyright (c) 2014 Blue-Mate. All rights reserved.
//

#import "DailyMenuCell.h"
#import "BMCartManager.h"

@implementation DailyMenuCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}
- (IBAction)addToCart:(id)sender {
//    BMCartManager *cartManager = [BMCartManager sharedInstance];
//    [cartManager addItemInCart:self.recipeId];
}

@end
