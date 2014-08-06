//
//  RestarauntStartViewController.m
//  BMSdk
//
//  Created by Matteo Comisso on 28/07/14.
//  Copyright (c) 2014 Blue-Mate. All rights reserved.
//

#import "RestarauntStartViewController.h"
#import "RestarauntStartmenuCell.h"

@interface RestarauntStartViewController () <UITableViewDataSource, UITableViewDelegate>
@property (strong, nonatomic) IBOutlet UIView *restarauntName;

@property (strong, nonatomic) NSArray *testCategorie;
@property (strong, nonatomic) NSMutableArray *testNetworkCategorie;

@property BOOL isTesting;
@end

@implementation RestarauntStartViewController


-(void)networkTester
{
    self.isTesting = YES;
    NSURL *myUrl = [[NSURL alloc]initWithString: @"http://54.76.193.225/api/v1/0/4"];
    //    NSURL *myUrl = [[NSURL alloc]initWithString: @"https://misiedo.com/api/area_tags/list.json?locale=it&withtotal=true"];
    NSURLRequest *request = [[NSURLRequest alloc]initWithURL:myUrl];
    NSURLResponse *resp = nil;
    NSError *err = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request
                                         returningResponse:&resp
                                                     error:&err];
    NSError *error = nil;
    
    self.testNetworkCategorie = [[NSMutableArray alloc]init];

    
    if (!err) {
        NSString * printThis =[[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
        
        NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:[printThis dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:&error];

        if (error) {
            NSLog(@"Error: %@ %@ %@", [error localizedDescription], [error localizedFailureReason], [error localizedRecoverySuggestion]);
        }
        else
        {
            for (NSString *cat in jsonObject) {
                [self.testNetworkCategorie addObject:cat];
                NSLog(@"%@", [self.testNetworkCategorie description]);
            }
            [self.tableView reloadData];
        }
//        NSLog(@"JSON Object: %@", [jsonObject description]);
    }
}

-(void)tester
{
    self.isTesting = YES;
    self.testCategorie = @[@"Antipasti",
                           @"Primi Piatti",
                           @"Secondi Piatti",
                           @"Contorni",
                           @"Bevande",
                           @"Vini",
                           @"Dolci",
                           @"Digestivi"];
}

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
    self.restarauntName.layer.cornerRadius = self.restarauntName.frame.size.width / 2;
    
    //TESTER
//    [self tester];
    
    [self networkTester];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - TableView Methods
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"cellIdentifier";
    
    RestarauntStartmenuCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        cell = [[RestarauntStartmenuCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }

    NSLog(@"netCategories description %@", [self.testNetworkCategorie description]);

    cell.categoryLabel.text = [self.testNetworkCategorie objectAtIndex:indexPath.row];
    
    if ((indexPath.row % 2) == 1) {
        cell.backgroundColor = [UIColor lightGrayColor];
    }
    else
    {
        cell.backgroundColor = [UIColor blackColor];
    }
    cell.categoryLabel.textColor = [UIColor whiteColor];
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Selezionato row %@", [indexPath description]);
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.testNetworkCategorie count];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
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
