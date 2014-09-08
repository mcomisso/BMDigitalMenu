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

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //LOAD the pdf file inside the webview
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)loadDocument
{
    NSString *filePath = [[NSBundle mainBundle]pathForResource:@"FILENAME" ofType:@"pdf"];
    
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    
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
