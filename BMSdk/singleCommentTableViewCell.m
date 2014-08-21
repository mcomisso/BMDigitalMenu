//
//  singleCommentTableViewCell.m
//  BMSdk
//
//  Created by Matteo Comisso on 21/08/14.
//  Copyright (c) 2014 Blue-Mate. All rights reserved.
//

#import "singleCommentTableViewCell.h"

@implementation singleCommentTableViewCell

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
