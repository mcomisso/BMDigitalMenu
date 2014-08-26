//
//  RestarauntStartViewController.m
//  BMSdk
//
//  Created by Matteo Comisso on 28/07/14.
//  Copyright (c) 2014 Blue-Mate. All rights reserved.
//

#import "RestarauntStartViewController.h"
#import "RestarauntStartmenuCell.h"
#import "SDWebImage/UIImageView+WebCache.h"
#import "TDBadgedCell.h"

#import "BMDataManager.h"
#import "BMCartManager.h"

#import "MenuListViewController.h"

@interface RestarauntStartViewController () <UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate>

@property (strong, nonatomic) IBOutlet UIView *restarauntName;
@property (strong, nonatomic) IBOutlet UIView *sliderContainer;
@property (strong, nonatomic) IBOutlet UILabel *restarauntLabelName;

@property (strong, nonatomic) BMCartManager *cartManager;

@property (strong, nonatomic) NSArray *categorie;

@property BOOL isTesting;

@end

@implementation RestarauntStartViewController

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
    self.restarauntName.layer.cornerRadius = self.restarauntName.frame.size.width / 2;
    self.restarauntName.layer.backgroundColor = [[UIColor colorWithRed:0.12 green:0.12 blue:0.12 alpha:1]CGColor];
    
    self.cartManager = [BMCartManager sharedInstance];
    
    UIPanGestureRecognizer *pgr = [UIPanGestureRecognizer alloc];
    [self.sliderContainer addGestureRecognizer:pgr];

    self.tableView.backgroundColor = [UIColor colorWithRed:0.12 green:0.12 blue:0.12 alpha:1];
    
    [self.backgroundRestarauntImage sd_setImageWithURL:[NSURL URLWithString:@"http://54.76.193.225/static/images/INDUSTRIALDESIGN.jpg"]];
    
    [self loadCategories];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
    [self.navigationController setToolbarHidden:YES animated:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(void)loadCategories
{
    BMDataManager *dataManager = [BMDataManager sharedInstance];
    self.categorie = [dataManager requestCategoriesForRestaraunt:@2];
    
    [self.tableView reloadData];
}

#pragma mark - Gesture Recognizer Methods

-(BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)panGestureRecognizer
{
    CGPoint velocity = [panGestureRecognizer velocityInView:self.sliderContainer];
    return fabs(velocity.x) < fabs(velocity.y);
}

-(IBAction)handlePan:(UIPanGestureRecognizer *)recognizer
{
    CGPoint translation = [recognizer translationInView:_sliderContainer];
}

#pragma mark - TableView Methods
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    int indexed = (int) indexPath.row;
    
    static NSString *cellIdentifier = @"cellIdentifier";
    static NSString *TDCellIdentifier = @"badgeCellIdentifier";
    
    if (indexed == 0) {
        TDBadgedCell *cell = (TDBadgedCell *)[tableView dequeueReusableCellWithIdentifier:TDCellIdentifier];
        if (cell == nil) {
            cell = [[TDBadgedCell alloc]initWithFrame:CGRectZero];
        }
        cell.badgeString = [NSString stringWithFormat:@"%d",[self.cartManager numbersOfItemInCart]];
        cell.badgeTextColor = [UIColor whiteColor];
        cell.textLabel.textColor = [UIColor greenColor];
        cell.textLabel.text = @"SCELTI";
        
        cell.badgeColor = [UIColor redColor];
        cell.badge.radius = 9;
        cell.badge.fontSize = 18;
        if ([self.cartManager numbersOfItemInCart]) {
            cell.badge.alpha = 1;
        }
        else
        {
            cell.badge.alpha = 0;
        }
        cell.backgroundColor = [UIColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:1];

        return cell;
    }
    else
    {
        RestarauntStartmenuCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];

        if (cell == nil) {
            cell = [[RestarauntStartmenuCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        }
        
        cell.categoryLabel.text = [self.categorie objectAtIndex:indexPath.row - 1];
        
        if ((indexPath.row % 2) == 1) {
            cell.backgroundColor = [UIColor colorWithRed:0.12 green:0.12 blue:0.12 alpha:1];
        }
        else
        {
            cell.backgroundColor = [UIColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:1];
        }
        cell.categoryLabel.textColor = [UIColor whiteColor];
        
        return cell;
    }
    return nil;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Selezionato row %@", [indexPath description]);
    if (indexPath.row == 0) {
        [self performSegueWithIdentifier:@"cartSegue" sender:self];
    }
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.categorie count] + 1;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSString *)nameOfSelectedCell
{
    RestarauntStartmenuCell *cell = (RestarauntStartmenuCell *)[self.tableView cellForRowAtIndexPath:[self.tableView indexPathForSelectedRow]];
    NSString *nameOfCategory = cell.categoryLabel.text;
    NSLog(@"%@", nameOfCategory);
    
    return nameOfCategory;
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier]isEqualToString:@"cartSegue"]) {
        NSLog(@"Cart View segue");
    }
    if ([[segue identifier] isEqualToString:@"showRecipes"])
    {
        MenuListViewController *menuList = [segue destinationViewController];
        menuList.category = [self nameOfSelectedCell];
    }
}


@end
