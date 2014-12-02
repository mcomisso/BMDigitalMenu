//
//  RestaurantStartViewController.m
//  BMSdk
//
//  Created by Matteo Comisso on 28/07/14.
//  Copyright (c) 2014 Blue-Mate. All rights reserved.
//

#import "RestaurantStartViewController.h"
#import "RestaurantStartmenuCell.h"
#import "SDWebImage/UIImageView+WebCache.h"
#import "TDBadgedCell.h"
#import "NGAParallaxMotion.h"

#import "BMDataManager.h"
#import "BMCartManager.h"
#import "BMUsageStatisticManager.h"

#import <Accelerate/Accelerate.h>

#import "MenuListViewController.h"
#import "DocumentsViewController.h"

//Daily Menu
#import "BFPaperButton.h"

//Remove in production
#import "BMDownloadManager.h"


@interface RestaurantStartViewController () <UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate>

//Contenitore della view "tableView" con le categorie
@property (strong, nonatomic) IBOutlet UIView *categoriesMenuContainer;
@property (strong, nonatomic) NSArray *categorie;

//Dettagli del ristorante
@property (strong, nonatomic) IBOutlet UIView *restaurantNameContainer;
@property (strong, nonatomic) IBOutlet UILabel *restaurantLabelName;
@property (strong, nonatomic) IBOutlet UIView *topBarHider;
@property (strong, nonatomic) IBOutlet UIView *pdfViewLoader;

//Bluemate managers classes
@property (strong, nonatomic) BMCartManager *cartManager;
@property (strong, nonatomic) BMUsageStatisticManager *statsManager;


// Daily - PaperButton
@property (strong, nonatomic) IBOutlet BFPaperButton *dailyMenuButton;

/* DAILY MENU DATA*/
@property (nonatomic) BOOL isDayMenuAvailable;
@property (strong, nonatomic) NSArray *dailyCategorieDataSource;
@property (strong, nonatomic) NSArray *dailyRecipesDataSource;

@property (strong, nonatomic) NSDictionary *dailyMenuDataSource;

@end

@implementation RestaurantStartViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.isDayMenuAvailable = NO;
    }
    return self;
}

-(UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self setNeedsStatusBarAppearanceUpdate];
    self.navigationController.navigationBar.barStyle = UIStatusBarStyleDefault;

    [self.tableView reloadData];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [self.navigationController setToolbarHidden:YES animated:NO];

}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
//    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

/**
 Setup del bottone in stile material design (per menu del giorno)
 */
-(void)setupPaperButton
{
    [self.dailyMenuButton addTarget:self action:nil forControlEvents:UIControlEventTouchUpInside];
    
    //Set orange colors
    [self.dailyMenuButton setTapCircleColor:[UIColor colorWithRed:0.91 green:0.25 blue:0.1 alpha:1]];
    [self.dailyMenuButton setBackgroundColor:[UIColor colorWithRed:1 green:0.44 blue:0.2 alpha:1]];
    
    [self.dailyMenuButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.dailyMenuButton setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
    [self.dailyMenuButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];

    self.dailyMenuButton.isRaised = YES;
    
    //Set title
    self.dailyMenuButton.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.dailyMenuButton.titleLabel.textAlignment = NSTextAlignmentLeft;
    [self.dailyMenuButton setTitle:@"MENÙ\nDEL\nGIORNO" forState:UIControlStateNormal];

    self.dailyMenuButton.alpha = 1.f;

    /*[UIView animateWithDuration:0.4
                          delay:0.8
         usingSpringWithDamping:0.8
          initialSpringVelocity:6
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.dailyMenuButton.center = dayMenuButtonNewCenter;
                     }
                     completion:^(BOOL finished) {
                         self.dailyMenuButton.center = dayMenuButtonNewCenter;
                         NSLog(@"%f - %f", self.dailyMenuButton.center.x, self.dailyMenuButton.center.y);
                     }];*/
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.dailyMenuButton.alpha = 0.f;
    
    self.statsManager = [BMUsageStatisticManager sharedInstance];
    
    //restaurant Has Day menu || UpdateMenu
    [self addObservers];

    // Setup the black layer gradient
    [self blackLayerGradient];
    
    // Ask for Background Image
    self.backgroundRestaurantImage.contentMode = UIViewContentModeScaleAspectFill;

    //TODO: change with the right background image
    [self.backgroundRestaurantImage sd_setImageWithURL:[NSURL URLWithString:@"http://s3-eu-west-1.amazonaws.com/misiedo/images/restaurants/823/rbig_alcason_mestre2.jpg"]];
    
    // Appereance Settings
    [self setColors];
    
    //Objects Instantiations
    self.cartManager = [BMCartManager sharedInstance];
    
    [self loadCategories];
    
    if (self.isDayMenuAvailable) {
        [self setupPaperButton];
    }
}

/**
 Sets the colors of the static interface
 */
-(void)setColors
{
    self.topBarHider.backgroundColor = [UIColor whiteColor];
}

-(void)addObservers
{
    //This class is called when the api responds with the day menu
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(setupPaperButton)
                                                name:@"restaurantHasDayMenu"
                                              object:nil];
    
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(dataChangedInDB)
                                                name:@"updateMenu"
                                              object:nil];
    
    BMDataManager *dm = [BMDataManager sharedInstance];
    
    if ([dm isTodayDayMenuAvailableForRestaurant:[[NSUserDefaults standardUserDefaults]objectForKey:@"restaurantSlug"]]) {
        self.isDayMenuAvailable = YES;
    }
}

-(void)blackLayerGradient
{

    UIColor *topColor = [UIColor colorWithWhite:0 alpha:0.95];
    UIColor *bottomColor = [UIColor colorWithWhite:0 alpha:0];
    
    NSArray *gradientColors = @[(id)topColor.CGColor, (id)bottomColor.CGColor];
    NSArray *gradientLocations = @[[NSNumber numberWithInt:0.0], [NSNumber numberWithInt:1.0]];
    
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.colors = gradientColors;
    gradientLayer.locations = gradientLocations;
    
    //Set the layer at 0,0 for the dimension of the frame
    gradientLayer.frame = CGRectMake(0, 0, self.restaurantNameContainer.frame.size.width, self.restaurantNameContainer.frame.size.height);
    
    [self.restaurantNameContainer.layer insertSublayer:gradientLayer atIndex:0];
}

-(void)animateToPositionsForPDF
{
    CGPoint originalCenter = self.restaurantNameContainer.center;
    
    self.restaurantNameContainer.center = self.view.center;

    [self.tableView removeFromSuperview];
    
    [UIView animateWithDuration:0.4 delay:0.3 usingSpringWithDamping:0.8 initialSpringVelocity:6 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.restaurantNameContainer.center = originalCenter;
    } completion:^(BOOL finished) {
        NSLog(@"PDF Button Animation Completed");
    }];
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Tableview utils
-(void)loadCategories
{
    BMDataManager *dataManager = [BMDataManager sharedInstance];
    
    NSNumber *majorNumber = [[NSUserDefaults standardUserDefaults]objectForKey:@"majorBeacon"];
    NSNumber *minorNumber = [[NSUserDefaults standardUserDefaults]objectForKey:@"minorBeacon"];

    [self.restaurantLabelName setText:[dataManager requestRestaurantNameForMajorBeacon:majorNumber andMinorBeacon:minorNumber]];
    self.categorie = [dataManager requestCategoriesForRestaurantMajorNumber:majorNumber andMinorNumber:minorNumber];
    
    if ([_restaurantLabelName.text isEqualToString:@"locale2"]) {
        [self.backgroundRestaurantImage sd_setImageWithURL:[NSURL URLWithString:@"http://s3-eu-west-1.amazonaws.com/misiedo/images/restaurants/981/rbig_pontedeldiavolo.jpeg"]];
    }
    else
    {
        [self.backgroundRestaurantImage sd_setImageWithURL:[NSURL URLWithString:@"http://s3-eu-west-1.amazonaws.com/misiedo/images/restaurants/823/rbig_alcason_mestre2.jpg"]];
    }
    
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

            cell.textLabel.textColor = [UIColor redColor];
            cell.textLabel.text = @"SCELTI";
            cell.textLabel.font = [UIFont boldSystemFontOfSize:18];
            
            cell.badgeColor = [UIColor redColor];
            cell.badge.radius = cell.badge.frame.size.width /2;;
            
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
            RestaurantStartmenuCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
            
            if (cell == nil) {
                cell = [[RestaurantStartmenuCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
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
    RestaurantStartmenuCell *cell = (RestaurantStartmenuCell *)[self.tableView cellForRowAtIndexPath:[self.tableView indexPathForSelectedRow]];
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
//        dvc.documentName = [dataManager requestPDFNameOfRestaurant:@"Ciao"];
    }
}

@end
