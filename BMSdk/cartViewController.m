//
//  cartViewController.m
//  BMSdk
//
//  Created by Matteo Comisso on 25/08/14.
//  Copyright (c) 2014 Blue-Mate. All rights reserved.
//

#import "cartViewController.h"
#import "cartTableViewCell.h"
#import "SDWebImage/UIImageView+WebCache.h"
#import "BMCartManager.h"
#import "BMUsageStatisticManager.h"

#define BMAPI @"https://s3-eu-west-1.amazonaws.com/bmbackend/"

@interface cartViewController () <UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) BMCartManager *cartManager;
@property (strong, nonatomic) BMUsageStatisticManager *statsManager;

@property (strong, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) NSMutableArray *dataSource;

@end

@implementation cartViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    //[self setNeedsStatusBarAppearanceUpdate];
    
    self.cartManager = [BMCartManager sharedInstance];
    self.statsManager = [BMUsageStatisticManager sharedInstance];
    
    self.dataSource = [[NSMutableArray alloc] initWithArray:[self.cartManager itemsInCart] copyItems:YES];

    [self setupViewIfEmptyArray];
    
    [self setPreferredToolbar];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    self.tableView.editing=false;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)setupViewIfEmptyArray
{
    if ([self.dataSource count] == 0) {
        self.tableView.alpha = 0;
    }
}

-(void)setPreferredToolbar
{
    self.tableView.scrollsToTop = YES;
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    
    self.navigationController.navigationBar.translucent = NO;
    self.navigationController.navigationBar.tintColor = [UIColor blackColor];
    [self.navigationController.navigationBar setBarTintColor:[UIColor whiteColor]];
    self.navigationController.navigationBar.barStyle = UIStatusBarStyleDefault;
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.navigationItem.hidesBackButton = NO;
}

#pragma mark - tableView methods

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"cellIdentifier";
    
    NSDictionary *recipe = [self.dataSource objectAtIndex:indexPath.row];
    
    cartTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[cartTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault
                                  reuseIdentifier:cellIdentifier];
    }
    cell.recipeId = [recipe objectForKey:@"id"];
    NSLog(@"Recipe Description: %@", [recipe description]);
    
    // SD_IMAGE to set the image in async
    [cell.recipeImageView sd_setImageWithURL:[NSURL URLWithString:[BMAPI stringByAppendingString:[recipe objectForKey:@"image"]]]
                            placeholderImage:[self generateWhiteImage]];

    cell.recipeImageView.clipsToBounds = YES;

    // Set the strings for the labels
    cell.recipePrice.text = [[recipe objectForKey:@"price"]stringByAppendingString:@"€"];
    
    cell.recipeName.text = [recipe objectForKey:@"title"];

    return cell;
}

#pragma mark - Delete Methods
-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        //Delete from source + remove from view
        
        [self.dataSource removeObjectAtIndex:indexPath.row];
        
        cartTableViewCell *cell = (cartTableViewCell*)[tableView cellForRowAtIndexPath:indexPath];

        [self.cartManager deleteFromCartWithId:cell.recipeId];
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationTop];
        if ([self.dataSource count] == 0) {
            [UIView animateWithDuration:0.3
                             animations:^{
                                 self.tableView.alpha = 0.f;
                             }];
        }
    }
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
 
    NSLog(@"Description: %@", [self.dataSource description]);
   return [self.dataSource count];
}

#pragma mark - Utils
-(void)reloadDataFromCart
{
    self.dataSource = [[NSMutableArray alloc]initWithArray:[self.cartManager itemsInCart] copyItems:YES];
}

-(UIImage *)generateWhiteImage
{
    CGRect rect = CGRectMake(0, 0, 1, 1);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    UIColor *color = [[UIColor alloc]initWithCGColor:[UIColor whiteColor].CGColor];
    [color setFill];
    UIRectFill(rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
