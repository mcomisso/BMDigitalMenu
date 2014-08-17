//
//  testClassViewController.m
//  BMSdk
//
//  Created by Matteo Comisso on 22/07/14.
//  Copyright (c) 2014 Blue-Mate. All rights reserved.
//

#import "testClassViewController.h"
#import "BMLocationManager.h"

@interface testClassViewController ()

@end

@implementation testClassViewController

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
    BMLocationManager *locationManager = [BMLocationManager sharedInstance];
    
    [self.navigationController.interactivePopGestureRecognizer setEnabled:YES];
    NSLog(@"BMLocationmanager %@", [locationManager description]);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
