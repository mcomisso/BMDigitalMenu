//
//  DocumentsViewController.m
//  BMSdk
//
//  Created by Matteo Comisso on 08/09/14.
//  Copyright (c) 2014 Blue-Mate. All rights reserved.
//

#import "DocumentsViewController.h"

@interface DocumentsViewController ()

@property (strong, nonatomic) IBOutlet UIWebView *documentWebView;

@end

@implementation DocumentsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController setToolbarHidden:NO animated:YES];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    //LOAD the pdf file inside the webview
    [self loadDocument];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Toolbar
    [self setPreferredToolbar];
    
}

-(void)setPreferredToolbar
{
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    
    self.navigationController.navigationBar.translucent = NO;
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    [self.navigationController.navigationBar setBarTintColor:[UIColor colorWithRed:0.61 green:0.77 blue:0.8 alpha:1]];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.navigationItem.hidesBackButton = NO;
}

-(void)addToolbar
{
    UIToolbar *toolBar;
    toolBar.barStyle = UIBarStyleBlack;
    [toolBar sizeToFit];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    UIBarButtonItem *shareButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(shareAction)];
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelAction)];
    
    
    NSArray *barButton  =   [[NSArray alloc] initWithObjects:shareButton,flexibleSpace,doneButton,nil];
    [toolBar setItems:barButton];
    
    [self.view addSubview:toolBar];
    barButton = nil;
}

-(void)shareAction
{
    NSString *automaticText = @"Da oggi posso guardare il menu con #bluemate!";
    
    NSArray *itemsToShare = @[automaticText];

    UIActivityViewController *activityView = [[UIActivityViewController alloc]initWithActivityItems:itemsToShare applicationActivities:nil];
    
    [self presentViewController:activityView animated:YES completion:nil];
}
                                
-(void)cancelAction
{
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)loadDocument
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *PDFDir = [[paths firstObject]stringByAppendingString:@"/PDF/"];
    
    NSString *fileToLoad = [PDFDir stringByAppendingString:self.documentName];
    
    NSURL *fileURL = [NSURL fileURLWithPath:fileToLoad];
    
    [self.documentWebView loadRequest:[NSURLRequest requestWithURL:fileURL]];
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
