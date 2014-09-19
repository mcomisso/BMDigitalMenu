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
#import "DailyMenuCell.h"

@interface RestarauntStartViewController () <UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate>

@property (strong, nonatomic) IBOutlet UIView *restarauntName;
@property (strong, nonatomic) IBOutlet UILabel *restarauntLabelName;
@property (strong, nonatomic) IBOutlet UIView *topBarHider;
@property (strong, nonatomic) IBOutlet UIView *pdfViewLoader;

@property (strong, nonatomic) BMCartManager *cartManager;
@property (strong, nonatomic) BMUsageStatisticManager *statsManager;

@property (strong, nonatomic) NSArray *categorie;

/* DAILY MENU DATA*/
@property (strong, nonatomic) NSArray *dailyCategorieDataSource;
@property (strong, nonatomic) NSArray *dailyRecipesDataSource;

// Daily Menu Container
@property (strong, nonatomic) IBOutlet UIView *dailyMenuFullContainer;
@property (strong, nonatomic) IBOutlet UIView *viewHandler;
@property (strong, nonatomic) IBOutlet UIView *dailyMenuHider;

@property (strong, nonatomic) IBOutlet UILabel *draggableViewTodayLabel;
@property (strong, nonatomic) IBOutlet UILabel *todayDayLabel;
@property (strong, nonatomic) IBOutlet UILabel *todayDayNameLabel;
@property (strong, nonatomic) IBOutlet UILabel *todayMonthLabel;
@property (strong, nonatomic) IBOutlet UILabel *todayYearLabel;

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

-(void)setupDatesOfDailyMenu
{
    NSDateComponents *calendar = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear | NSCalendarUnitWeekday fromDate:[NSDate date]];

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
    [dateFormatter setDateFormat:@"EEEE"];
    dateFormatter.locale = [NSLocale currentLocale];
    
    NSInteger year = [calendar year];
    NSInteger month = [calendar month];
    
    NSString *monthName = [[[dateFormatter monthSymbols]objectAtIndex:month-1] capitalizedString];
    NSString *dayName = [dateFormatter stringFromDate:[NSDate date]];
    
    NSInteger day = [calendar day];
    
    self.draggableViewTodayLabel.text = [NSString stringWithFormat:@"%ld", (long)day];
    self.todayDayLabel.text = [NSString stringWithFormat:@"%ld", (long)day];
    self.todayYearLabel.text = [NSString stringWithFormat:@"%ld", (long)year];
    
    self.todayDayNameLabel.text = [dayName uppercaseString];
    self.todayMonthLabel.text = monthName;
    
}

/* 
 Initial setup of the position for the daily menu.
 Moves the view out of the window
 */
-(void)initialPositionOfDailyMenu
{
        self.dailyMenuFullContainer.center = CGPointMake(self.dailyMenuFullContainer.center.x + self.dailyMenu.frame.size.width , self.dailyMenu.center.y);
}

/*
 Attach the pangestureRecognizer to the full view for daily menu
 */
-(void)setupDragGestureForDailyMenu
{
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(handlePanOfDailyMenu:)];
    panGestureRecognizer.delegate = self;
    
    [self.viewHandler addGestureRecognizer:panGestureRecognizer];
}


-(void)dailyMenuFakerLoader
{
    self.dailyRecipesDataSource = @[
                                    @[
                                        @"Linguine al Pesto",
                                        @"Pasta all'amatriciana",
                                        @"Pasta al Ragù",
                                        @"Risotto alla milanese"],
                                    @[
                                        @"Scaloppine al vino bianco",
                                        @"Tagliata di manzo",
                                        @"Vitello tonnato",
                                        @"Cotoletta alla milanese"],
                                    @[
                                        @"Carote e insalata",
                                        @"Patate al forno",
                                        @"Verdure grigliate",
                                        @"Spinaci"]
                                    ];
    
    self.dailyCategorieDataSource = @[@"PRIMI",@"SECONDI",@"CONTORNI"];
}

/*
 Handles the pan of the view for daily menu
 */
-(void)handlePanOfDailyMenu:(UIPanGestureRecognizer *)recognizer
{
    UIView *piece = [recognizer view];
    
    if (recognizer.state == UIGestureRecognizerStateBegan || recognizer.state == UIGestureRecognizerStateChanged)
    {
        CGPoint translation = [recognizer translationInView:piece];
//        CGPoint velocity = [recognizer velocityInView:self.view];
        [self.dailyMenuFullContainer setCenter:CGPointMake(self.dailyMenuFullContainer.center.x + translation.x, self.dailyMenuFullContainer.center.y)];
        [recognizer setTranslation:CGPointZero inView:self.view];
    }
}

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

/*Check if daily menu is available and downloads it*/
-(BOOL)isDailyMenuAvailable
{
    int i = 1;
    
    if (i) {
        return YES;
    }
    else
    {
        return NO;
    }
}

/*
 FIRST CALLER:
 This method initializes every other one
 */
-(void)setupDailyMenu
{
    if ([self isDailyMenuAvailable]) {
        [self dailyMenuFakerLoader];
        [self setupDatesOfDailyMenu];

        [self initialPositionOfDailyMenu];
        [self setupDragGestureForDailyMenu];
    }
    else
    {
        //Remove from superview the container of tableview
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
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.statsManager = [BMUsageStatisticManager sharedInstance];
    
    [self setupDailyMenu];
    
    // Ask for Background Image
    self.backgroundRestarauntImage.contentMode = UIViewContentModeScaleAspectFill;
    [self.backgroundRestarauntImage sd_setImageWithURL:[NSURL URLWithString:@"http://s3-eu-west-1.amazonaws.com/misiedo/images/restaurants/823/rbig_alcason_mestre2.jpg"]];
    
    // Appereance Settings
    [self setColors];
    [self setPdfButton];
    
    //Objects Instantiations
    self.cartManager = [BMCartManager sharedInstance];
    
    [self loadCategories];

    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(dataChangedInDB) name:@"updateMenu" object:nil];
}

-(void)setColors
{
    self.topBarHider.backgroundColor = [UIColor whiteColor];
    self.restarauntName.layer.cornerRadius = self.restarauntName.frame.size.width / 2;
    self.restarauntName.layer.backgroundColor = [UIColor colorWithWhite:1 alpha:0.8].CGColor;

    //TableView Background Color
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
    CGPoint originalCenter = self.restarauntName.center;
    
    CGPoint originalTableCenter = self.tableView.center;
    
    self.pdfViewLoader.alpha = 0.f;

    self.restarauntName.center = self.view.center;
    self.tableView.center = CGPointMake(originalTableCenter.x + self.tableView.frame.size.width, originalTableCenter.y);
    self.dailyMenuHider.center = self.tableView.center;
    
    [UIView animateWithDuration:0.4 delay:0.3 usingSpringWithDamping:0.8 initialSpringVelocity:6 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.restarauntName.center = originalCenter;
        self.tableView.center = originalTableCenter;
        self.dailyMenuHider.center = originalTableCenter;

    } completion:^(BOOL finished) {
        NSLog(@"Completed");
    }];
    //Central circle with spinning
    //Move central circle to storyboard position
    //Add tableview at side
}

-(void)animateToPositionsForPDF
{
    CGPoint originalCenter = self.restarauntName.center;
    
    self.restarauntName.center = self.view.center;

    [self.tableView removeFromSuperview];
    
    [UIView animateWithDuration:0.4 delay:0.3 usingSpringWithDamping:0.8 initialSpringVelocity:6 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.restarauntName.center = originalCenter;
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

-(void)loadCategories
{
    BMDataManager *dataManager = [BMDataManager sharedInstance];
    self.categorie = [dataManager requestCategoriesForRestaraunt:@2];

    [self.tableView reloadData];
}

#pragma mark - TableView Methods
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if (tableView == self.tableView) {
        
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
    }
    else if(tableView == self.dailyMenu)
    {
        static NSString *dailyCellIdentifier = @"dailyCell";
        
        DailyMenuCell *cell = [tableView dequeueReusableCellWithIdentifier:dailyCellIdentifier];
        
        if (cell == nil) {
            cell = [[DailyMenuCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:dailyCellIdentifier];
        }
        cell.recipeName.text = [[self.dailyRecipesDataSource objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
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
    if (tableView == self.tableView) {
        return [self.categorie count] + 1;
    }
    else
    {
        return 4;
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (tableView == self.dailyMenu) {
        return 30;
    }
    else
    {
        return 0;
    }
}

-(UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 30)];
    [headerView setBackgroundColor:[UIColor whiteColor]];
    return headerView;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (tableView == self.dailyMenu) {
        NSString *sectionName;
        switch (section) {
            case 0:
                sectionName = [self.dailyCategorieDataSource objectAtIndex:0];
                break;
            case 1:
                sectionName = [self.dailyCategorieDataSource objectAtIndex:1];
                break;
            case 2:
                sectionName = [self.dailyCategorieDataSource objectAtIndex:2];
                break;
            case 3:
                sectionName = [self.dailyCategorieDataSource objectAtIndex:3];
                break;
            default:
                sectionName = @"nil";
                break;
        }
        return sectionName;
    }
    return nil;
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
