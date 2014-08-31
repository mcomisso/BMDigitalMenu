//
//  cartTableViewCell.m
//  BMSdk
//
//  Created by Matteo Comisso on 27/08/14.
//  Copyright (c) 2014 Blue-Mate. All rights reserved.
//

#import "cartTableViewCell.h"

@implementation cartTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
