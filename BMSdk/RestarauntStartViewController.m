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

#import <Accelerate/Accelerate.h>

#import "MenuListViewController.h"
#import "DocumentsViewController.h"

//Daily Menu
#import "BFPaperButton.h"

//Remove in production
#import "BMDownloadManager.h"


@interface RestarauntStartViewController () <UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate>

//Contenitore della view "tableView" con le categorie
@property (strong, nonatomic) IBOutlet UIView *categoriesMenuContainer;
@property (strong, nonatomic) NSArray *categorie;

//Dettagli del ristorante
@property (strong, nonatomic) IBOutlet UIView *restarauntNameContainer;
@property (strong, nonatomic) IBOutlet UILabel *restarauntLabelName;
@property (strong, nonatomic) IBOutlet UIView *topBarHider;
@property (strong, nonatomic) IBOutlet UIView *pdfViewLoader;

//Bluemate managers classes
@property (strong, nonatomic) BMCartManager *cartManager;
@property (strong, nonatomic) BMUsageStatisticManager *statsManager;


// Daily - PaperButton
@property (strong, nonatomic) IBOutlet BFPaperButton *dailyMenuButton;
@property (strong, nonatomic) IBOutlet UIView *dailyButtonContainer;


/* DAILY MENU DATA*/
@property (strong, nonatomic) NSArray *dailyCategorieDataSource;
@property (strong, nonatomic) NSArray *dailyRecipesDataSource;

@property (strong, nonatomic) NSDictionary *dailyMenuDataSource;

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

#pragma mark - DEBUG ONLY
#warning REMOVE ONCE IN PRODUCTION
-(void)downloadCatalogOfRecipesWithoutBeacon
{
    BMDownloadManager *downloadManager = [BMDownloadManager sharedInstance];
    [downloadManager fetchMenuOfRestaraunt:@123];
}

#warning REMOVE ONCE IN PRODUCTION
-(void)setupMutitapForDownload
{
    UITapGestureRecognizer *tpg = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(downloadCatalogOfRecipesWithoutBeacon)];
    
    tpg.delegate = self;
    tpg.numberOfTapsRequired = 5;
    
    [self.restarauntNameContainer addGestureRecognizer:tpg];
}
#pragma mark -


/**
 Scale and rotation transforms are applied relative to the layer's anchor point this method moves a gesture recognizer's view's anchor point between the user's fingers.
 */
- (void)adjustAnchorPointForGestureRecognizer:(UIPanGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        UIView *piece = gestureRecognizer.view;
 
        CGPoint locationInView = [gestureRecognizer locationInView:piece];
        CGPoint locationInSuperview = [gestureRecognizer locationInView:piece.superview];
        
        piece.layer.anchorPoint = CGPointMake(locationInView.x / piece.bounds.size.width, locationInView.y / piece.bounds.size.height);
        piece.center = locationInSuperview;
    }
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
    
    [self animateToPositionsForMenu];
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
    self.dailyMenuButton.cornerRadius = self.dailyMenuButton.frame.size.width / 2;
    [self.dailyMenuButton addTarget:self action:@selector(alertView) forControlEvents:UIControlEventTouchUpInside];
    
    //Colors
    self.dailyMenuButton.tapCircleColor = [UIColor whiteColor];
    [self.dailyMenuButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.dailyMenuButton setTitleColor:[UIColor blueColor] forState:UIControlStateHighlighted];
    
    //puts a shadow behind the button
    self.dailyMenuButton.isRaised = YES;
}

-(void)alertView
{
    NSLog(@"Paper button pressed");
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.statsManager = [BMUsageStatisticManager sharedInstance];

    // Setup the black layer gradient
    [self blackLayerGradient];
    [self setupPaperButton];
    
    /*
     TODO: REMOVE THIS ONCE IN PRODUCTION
     */
    [self setupMutitapForDownload];
    /**/


    // Ask for Background Image
    self.backgroundRestarauntImage.contentMode = UIViewContentModeScaleAspectFill;
    
    [self.backgroundRestarauntImage sd_setImageWithURL:[NSURL URLWithString:@"http://s3-eu-west-1.amazonaws.com/misiedo/images/restaurants/823/rbig_alcason_mestre2.jpg"]];
    
    // Appereance Settings
    [self setColors];
    [self setPdfButton];
    
    //Objects Instantiations
    self.cartManager = [BMCartManager sharedInstance];
    
    [self loadCategories];

    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(dataChangedInDB)
                                                name:@"updateMenu"
                                              object:nil];
}
/**
 Sets the colors of the static interface
 */
-(void)setColors
{
    self.topBarHider.backgroundColor = [UIColor whiteColor];
    self.restarauntNameContainer.layer.backgroundColor = [UIColor colorWithWhite:0 alpha:0.7].CGColor;
}

-(void)blackLayerGradient
{

    UIColor *topColor = [UIColor colorWithWhite:0 alpha:0.8];
    UIColor *bottomColor = [UIColor colorWithWhite:0 alpha:0];
    
    NSArray *gradientColors = @[(id)topColor.CGColor, (id)bottomColor.CGColor];
    NSArray *gradientLocations = @[[NSNumber numberWithInt:0.0], [NSNumber numberWithInt:1.0]];
    
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.colors = gradientColors;
    gradientLayer.locations = gradientLocations;
    
    gradientLayer.frame = self.restarauntNameContainer.frame;
    [self.restarauntNameContainer.layer insertSublayer:gradientLayer atIndex:0];
}

/**
 Sets the pdf "button"
 */
-(void)setPdfButton
{
    self.pdfViewLoader.layer.cornerRadius = self.pdfViewLoader.frame.size.width /2;
    UITapGestureRecognizer *tgr = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(loadPDFView)];
    [self.pdfViewLoader addGestureRecognizer:tgr];
}


/**
 Initial animation for menù entry
 */
-(void)animateToPositionsForMenu
{
//    CGPoint originalCenter = self.restarauntNameContainer.center;
//    CGPoint originalTableCenter = self.categoriesMenuContainer.center;
    CGPoint originalDailyButtonCenter = self.dailyButtonContainer.center;
    
    self.pdfViewLoader.alpha = 0.f;

//    self.restarauntNameContainer.center = CGPointMake(originalCenter.x - self.restarauntNameContainer.frame.size.width, originalCenter.y);
    
//    self.categoriesMenuContainer.center = CGPointMake(originalTableCenter.x + self.categoriesMenuContainer.frame.size.width, originalTableCenter.y);
    
    self.dailyButtonContainer.center = CGPointMake(originalDailyButtonCenter.x, originalDailyButtonCenter.y + self.dailyButtonContainer.frame.size.height);
    
    [UIView animateWithDuration:0.4 delay:2 usingSpringWithDamping:0.8 initialSpringVelocity:6 options:UIViewAnimationOptionCurveEaseOut animations:^{
//        self.restarauntNameContainer.center = originalCenter;
//        self.categoriesMenuContainer.center = originalTableCenter;
        self.dailyButtonContainer.center = originalDailyButtonCenter;
        
    } completion:^(BOOL finished) {
        NSLog(@"Completed");
    }];
    //Central circle with spinning
    //Move central circle to storyboard position
    //Add tableview at side
}

-(void)animateToPositionsForPDF
{
    CGPoint originalCenter = self.restarauntNameContainer.center;
    
    self.restarauntNameContainer.center = self.view.center;

    [self.tableView removeFromSuperview];
    
    [UIView animateWithDuration:0.4 delay:0.3 usingSpringWithDamping:0.8 initialSpringVelocity:6 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.restarauntNameContainer.center = originalCenter;
    } completion:^(BOOL finished) {
        NSLog(@"Completed");
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
//            cell.textLabel.textColor = [UIColor colorWithRed:0.61 green:0.77 blue:0.8 alpha:1];

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
    if (tableView == self.tableView) {
        return 1;
    }
    else if(tableView == self.dailyMenu)
    {
        return [self.dailyCategorieDataSource count];
    }
    else
    {
        return 0;
    }
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
