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
#import "NGAParallaxMotion.h"

#import "BMDataManager.h"
#import "BMCartManager.h"
#import "BMUsageStatisticManager.h"

#import "MenuListViewController.h"
#import "DocumentsViewController.h"

@interface RestarauntStartViewController () <UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate>

@property (strong, nonatomic) IBOutlet UIView *restarauntName;
@property (strong, nonatomic) IBOutlet UILabel *restarauntLabelName;
@property (strong, nonatomic) IBOutlet UIView *headupview;

@property (strong, nonatomic) IBOutlet UIView *pdfViewLoader;

@property (strong, nonatomic) BMCartManager *cartManager;
@property (strong, nonatomic) BMUsageStatisticManager *statsManager;

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

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.statsManager = [BMUsageStatisticManager sharedInstance];
    
    // Ask for Background Image
    self.backgroundRestarauntImage.contentMode = UIViewContentModeScaleAspectFill;
    [self.backgroundRestarauntImage sd_setImageWithURL:[NSURL URLWithString:@"http://s3-eu-west-1.amazonaws.com/misiedo/images/restaurants/154/rbig_ratana2.jpg"]];

    // Appereance Settings
    [self setNeedsStatusBarAppearanceUpdate];
    [self setColors];
    [self setPdfButton];
    
    //Objects Instantiations
    self.cartManager = [BMCartManager sharedInstance];
    
    [self loadCategories];

    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(dataChangedInDB) name:@"updateMenu" object:nil];
}

-(void)setPreferredToolbar
{
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    
    self.navigationController.navigationBar.translucent = NO;
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    [self.navigationController.navigationBar setBarTintColor:[UIColor colorWithRed:0.61 green:0.77 blue:0.8 alpha:0.6]];
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.navigationItem.hidesBackButton = NO;
}

-(void)setColors
{
    self.headupview.backgroundColor = [UIColor whiteColor];
    self.restarauntName.layer.cornerRadius = self.restarauntName.frame.size.width / 2;
    self.restarauntName.layer.backgroundColor = [UIColor colorWithWhite:1 alpha:0.8].CGColor;
 //TableView Background Color
//    self.tableView.backgroundColor = [self BMDarkColor];
    self.tableView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.7];
}

-(void)setPdfButton
{
    self.pdfViewLoader.layer.cornerRadius = self.pdfViewLoader.frame.size.width /2;

    UITapGestureRecognizer *tgr = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(loadPDFView)];
    [self.pdfViewLoader addGestureRecognizer:tgr];
}

-(void)animateToPositionsForMenu
{
    //Central circle with spinning
    //Move central circle to storyboard position
    //Add tableview at side
}

-(void)animateToPositionsForPDF
{
    //Central circle with spinning
    //move central circle up to 2/3
    //Add new button for pdf view
}

-(void)loadPDFView
{
    [self performSegueWithIdentifier:@"pdfView" sender:self];
}

-(void)dataChangedInDB
{
    [self loadCategories];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
    [self setPreferredToolbar];
//    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [self.navigationController setToolbarHidden:YES animated:NO];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
//    [self.navigationController setNavigationBarHidden:NO animated:YES];
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
        cell.textLabel.textColor = [UIColor colorWithRed:0.61 green:0.77 blue:0.8 alpha:1];
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
        cell.backgroundColor = [UIColor whiteColor];

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
            cell.backgroundColor = [UIColor clearColor];
        }
        else
        {
            cell.backgroundColor = [UIColor whiteColor];
        }
        cell.categoryLabel.textColor = [UIColor blackColor];
        
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

-(BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if ([identifier isEqualToString:@"cartSegue"]) {
        if ([self.cartManager numbersOfItemInCart] == 0) {
            return NO;
        }
        return YES;
    }
    else
    {
        return YES;
    }
}

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
    if ([[segue identifier] isEqualToString:@"pdfView"]) {
        DocumentsViewController *dvc = [segue destinationViewController];
        BMDataManager *dataManager = [BMDataManager sharedInstance];
#warning Change the restarauntID
        dvc.documentName = [dataManager requestPDFNameOfRestaraunt:@"Ciao"];
    }
}

@end
