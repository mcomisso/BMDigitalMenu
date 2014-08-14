//
//  MenuListViewController.m
//  BMSdk
//
//  Created by Matteo Comisso on 28/07/14.
//  Copyright (c) 2014 Blue-Mate. All rights reserved.
//

#import "MenuListViewController.h"
#import "MenuListCell.h"
#import "BMDataManager.h"

@interface MenuListViewController () <UITableViewDataSource, UITableViewDelegate>
@property (strong, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) NSArray *recipesInCategory;

//Testing purpose variables


@end

@implementation MenuListViewController

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
    BMDataManager *dataManger = [BMDataManager sharedInstance];
    
    self.recipesInCategory = [dataManger requestDataForCategory:self.category];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"cellIdentifier";
    
    MenuListCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        cell = [[MenuListCell alloc]initWithStyle:UITableViewCellStyleDefault
                                  reuseIdentifier:cellIdentifier];
        NSDictionary *recipe = [self.recipesInCategory objectAtIndex:indexPath.row];
        cell.recipeTitle.text = [recipe objectForKey:@"nome"];
        
        //Fetch
    }
    
    return cell;
}

/* Deve ritornare il count degli elemeti padre nell NSDictionary */
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

/* Deve ritornare il numero degli elementi children di un nodo padre */
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.recipesInCategory count];
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
