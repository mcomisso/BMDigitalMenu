//
//  NoImageTableViewCell.m
//  BMSdk
//
//  Created by Matteo Comisso on 06/09/14.
//  Copyright (c) 2014 Blue-Mate. All rights reserved.
//

#import "NoImageTableViewCell.h"

@implementation NoImageTableViewCell

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
