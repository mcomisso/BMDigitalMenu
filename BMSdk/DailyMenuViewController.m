//
//  DailyMenuViewController.m
//  BMSdk
//
//  Created by Matteo Comisso on 08/10/14.
//  Copyright (c) 2014 Blue-Mate. All rights reserved.
//

#import "DailyMenuViewController.h"
#import "DailyMenuCell.h"

@interface DailyMenuViewController () <UITableViewDataSource, UITableViewDelegate>

/* DAILY MENU DATA*/
@property (strong, nonatomic) NSArray *dailyCategorieDataSource;
@property (strong, nonatomic) NSDictionary *dailyMenuDataSource;

// Daily Menu labels
@property (strong, nonatomic) IBOutlet UILabel *todayDayLabel;
@property (strong, nonatomic) IBOutlet UILabel *todayDayNameLabel;
@property (strong, nonatomic) IBOutlet UILabel *todayMonthLabel;
@property (strong, nonatomic) IBOutlet UILabel *todayYearLabel;

@end

@implementation DailyMenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setupDailyMenu];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - buttons
- (IBAction)closeView:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Daily menu datasource
-(void)dailyMenuFakerLoader
{
    
    self.dailyMenuDataSource = @{   @"PRIMI":@[
                                            @{
                                                @"name" :@"Linguine al Pesto",
                                                @"price":@"4"
                                            },
                                            @{
                                                @"name" :@"Pasta all'amatriciana",
                                                @"price":@"6"
                                            },
                                            @{
                                                @"name" :@"Pasta al Ragù",
                                                @"price":@"5"
                                            },
                                            @{
                                                @"name" :@"Pasta al Ragù",
                                                @"price":@"2"
                                            }],
                                    @"SECONDI":@[
                                            @{
                                                @"name" : @"Scaloppine al vino bianco",
                                                @"price" : @"12"
                                                },
                                            @{
                                                @"name" : @"Tagliata di manzo",
                                                @"price" : @"123"
                                                },
                                            @{
                                                @"name" : @"Vitello tonnato",
                                                @"price" : @"65"
                                                },
                                            @{
                                                @"name" : @"Cotoletta alla milanese",
                                                @"price" : @"1"
                                                }],
                                    @"CONTORNI": @[
                                            @{
                                                @"name" : @"Carote e insalata",
                                                @"price" : @"51"
                                                },
                                            @{
                                                @"name" : @"Patate al forno",
                                                @"price" : @"6"
                                                },
                                            @{
                                                @"name" : @"Verdure grigliate",
                                                @"price" : @"13"
                                                },
                                            @{
                                                @"name" : @"Spinaci",
                                                @"price" : @"4"
                                                }]
                                    };

    NSLog(@"Numero di elementi in dailyMenuDataSource %lu", (unsigned long)[self.dailyMenuDataSource count]);
    
    self.dailyCategorieDataSource = [self.dailyMenuDataSource allKeys];
}

-(NSUInteger)countOfDailyMenuDataSourceForSection:(NSInteger)section
{
    NSArray *allKeys = [self.dailyMenuDataSource allKeys];
    NSString *category = [allKeys objectAtIndex:section];
    return [[self.dailyMenuDataSource objectForKey:category] count];
}

#pragma mark - Daily menu setters

-(void)setupDailyMenu
{
    if ([self isDailyMenuAvailable]) {
        [self dailyMenuFakerLoader];
        [self setupDatesOfDailyMenu];
    }
    else
    {
        //Remove from superview the container of tableview
        
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
    
    if (day < 10) {
        self.todayDayLabel.text = [NSString stringWithFormat:@"0%ld", (long)day];
    }
    else{
        self.todayDayLabel.text = [NSString stringWithFormat:@"%ld", (long)day];
    }
    self.todayYearLabel.text = [NSString stringWithFormat:@"%ld", (long)year];
    
    self.todayDayNameLabel.text = [dayName uppercaseString];
    self.todayMonthLabel.text = monthName;
    
}

#pragma mark - TableView methods

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self countOfDailyMenuDataSourceForSection:section];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.dailyCategorieDataSource count];
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 30.f;
}

-(UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 30)];
    [headerView setBackgroundColor:[UIColor whiteColor]];
    
    UILabel *titleHeader = [[UILabel alloc]initWithFrame:CGRectMake(20, 0, tableView.bounds.size.width-10, 30)];
    
    [titleHeader setText:[self.dailyCategorieDataSource objectAtIndex:section]];
    titleHeader.font = [UIFont fontWithName:@"Avenir" size:25];
    titleHeader.textColor = [UIColor colorWithRed:0.03 green:0.5 blue:0.84 alpha:1];
    
    titleHeader.textAlignment = NSTextAlignmentLeft;
    
    [headerView addSubview:titleHeader];
    
    return headerView;
}
/*
-(CGFloat)tableView:(UITableView *)tableView estimatedHeightForFooterInSection:(NSInteger)section
{
    return 4;
}

-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UIView *footerView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 4)];
    footerView.backgroundColor = [UIColor colorWithRed:0.12 green:0.12 blue:0.12 alpha:1];
    return footerView;
}*/

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSArray *keys = [self.dailyMenuDataSource allKeys];
    
    if (tableView == self.dailyMenu) {
        NSString *sectionName;
        switch (section) {
            case 0:
                sectionName = [keys objectAtIndex:0];
                break;
            case 1:
                sectionName = [keys objectAtIndex:1];
                break;
            case 2:
                sectionName = [keys objectAtIndex:2];
                break;
            case 3:
                sectionName = [keys objectAtIndex:3];
                break;
            default:
                sectionName = @"nil";
                break;
        }
        return sectionName;
    }
    return nil;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *dailyCellIdentifier = @"dailyCell";
    
    DailyMenuCell *cell = [tableView dequeueReusableCellWithIdentifier:dailyCellIdentifier];
    
    if (cell == nil) {
        cell = [[DailyMenuCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:dailyCellIdentifier];
    }
    
    NSString *sectionKey = [[self.dailyMenuDataSource allKeys]objectAtIndex:indexPath.section];
    NSLog(@"%@", sectionKey);
    
    NSString *recipeNameString = [[[self.dailyMenuDataSource objectForKey:sectionKey]objectAtIndex:indexPath.row] objectForKey:@"name"];
    NSString *recipePriceString = [[[self.dailyMenuDataSource objectForKey:sectionKey]objectAtIndex:indexPath.row] objectForKey:@"price"];
    
    NSLog(@"%@", recipeNameString);

    cell.recipeName.text = recipeNameString;
    cell.recipePrice.text = [[@"Prezzo: " stringByAppendingString:recipePriceString]stringByAppendingString:@"€"];
    
    return cell;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
