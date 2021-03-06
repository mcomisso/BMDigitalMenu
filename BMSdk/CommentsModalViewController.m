//
//  CommentsModalViewController.m
//  BMSdk
//
//  Created by Matteo Comisso on 17/08/14.
//  Copyright (c) 2014 Blue-Mate. All rights reserved.
//
#import "singleCommentTableViewCell.h"
#import "CommentsModalViewController.h"
#import "BMDataManager.h"
#import "REComposeViewController.h"

#import "AFBMHTTPRequestOperationManager.h"

//Security Classes
#import "UAObfuscatedString.h"
#import "CocoaSecurity.h"

#import <Security/Security.h>
#import <CommonCrypto/CommonHMAC.h>
#import <CommonCrypto/CommonCryptor.h>

@interface CommentsModalViewController () <UITableViewDataSource, UITableViewDelegate, REComposeViewControllerDelegate>

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *dataSourceOfComments;

//Background
@property (strong, nonatomic) IBOutlet UIView *backgroundView;
@property (strong, nonatomic) IBOutlet UILabel *noCommentsLabel;

@property (strong, nonatomic) REComposeViewController *composeViewController;

@property (weak, nonatomic) IBOutlet UIButton *addCommentButton;

@end

@implementation CommentsModalViewController

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
    self.backgroundView.backgroundColor = BMDarkValueColor;

    //Load Comments from database
    BMDataManager *dataManager = [BMDataManager sharedInstance];
    self.dataSourceOfComments = [NSMutableArray arrayWithArray:[dataManager requestCommentsForRecipe:self.recipeSlug]];
    DLog(@"%@", self.recipeSlug);
    
    self.addCommentButton.titleLabel.text = BMLocalizedString(@"AddComment", nil);
    
    [self editViewIfNoRecipes];
    
    [self fakeLoader];
}

/**
 Checks if there's comments for the selected recipe. If not, removes the tableview and shows the label.
 */
-(void)editViewIfNoRecipes
{
    if ([self.dataSourceOfComments count] == 0) {
        self.tableView.alpha = 0.f;
        self.noCommentsLabel.text = BMLocalizedString(@"noCommentsAvailable", nil);
    }
    else
    {
        self.noCommentsLabel.alpha = 0.f;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)dismissModal:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self basicCellAtIndexPath:indexPath];
}

-(singleCommentTableViewCell *)basicCellAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"cellIdentifier";
    singleCommentTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    [self configureBasicCell:cell atIndexPath:indexPath];
    return cell;
}

-(void)configureBasicCell:(singleCommentTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *recipe = self.dataSourceOfComments[indexPath.row];
    [self setUsernameForCell:cell item:recipe];
    [self setCommentForCell:cell item:recipe];
}

-(void)setUsernameForCell:(singleCommentTableViewCell *)cell item:(NSDictionary*)item
{
    NSNumber *usernameID = [item objectForKey:@"username"];
    NSString *string = [NSString stringWithFormat:@"%@", usernameID];
    [cell.usernameLabel setText:string];
}

-(void)setCommentForCell:(singleCommentTableViewCell *)cell item:(NSDictionary *)item
{
    NSString *string = [item objectForKey:@"comment"];
    [cell.commentLabel setText:string];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self heightForBasicCellAtIndexPath:indexPath];
}

-(CGFloat)heightForBasicCellAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"cellIdentifier";
    static singleCommentTableViewCell *sizingCell = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sizingCell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    });
    
    [self configureBasicCell:sizingCell atIndexPath:indexPath];
    return [self calculateHeightForConfiguredSizingCell:sizingCell];
}

-(CGFloat)calculateHeightForConfiguredSizingCell:(UITableViewCell *)sizingCell
{
    [sizingCell setNeedsLayout];
    [sizingCell layoutIfNeeded];
    
    CGSize size = [sizingCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    return size.height;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.dataSourceOfComments count];
}

-(void)textViewDidChange:(UITextView *)textView
{
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
}

#pragma mark - Add comment

- (IBAction)callCommentsView:(id)sender {
    
    //TODO: Controllare se l'utente è esistente.
    NSDictionary *msUserDetails = [[NSUserDefaults standardUserDefaults] objectForKey:@"MSUserDetails"];
    NSString *username = [msUserDetails objectForKey:@"username"];
    
    if (username != nil) {
        NSBundle *BMResourcesBundle = [NSBundle bundleWithURL:[[NSBundle mainBundle] URLForResource:@"BMSdk" withExtension:@"bundle"]];
        [BMResourcesBundle load];
        NSString *bluemateLogo = [BMResourcesBundle pathForResource:@"bluemate-logo@2x" ofType:@"png"];
        UIImageView *titleImageView = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:bluemateLogo]];
        titleImageView.frame = CGRectMake(0, 0, 110, 30);
        
        _composeViewController = [[REComposeViewController alloc]init];
        _composeViewController.navigationItem.titleView = titleImageView;
        _composeViewController.delegate = self;
        _composeViewController.hasAttachment = NO;
        _composeViewController.placeholderText = BMLocalizedString(@"CommentPlaceholder", nil);
        [self.composeViewController presentFromViewController:self];
    }
    else
    {
        UIAlertView *alertview = [[UIAlertView alloc]initWithTitle:BMLocalizedString(@"Warning", nil)
                                                           message:BMLocalizedString(@"MSAccountRequired", nil)
                                                          delegate:nil
                                                 cancelButtonTitle:@"Ok"
                                                 otherButtonTitles:nil, nil];
        [alertview show];
    }
}

-(void)composeViewController:(REComposeViewController *)composeViewController didFinishWithResult:(REComposeResult)result
{
    [composeViewController dismissViewControllerAnimated:YES completion:nil];
    
    if (result == REComposeResultCancelled) {
        DLog(@"Cancelled Comment");
    }
    else if (result == REComposeResultPosted)
    {
        //Send the content on the server
        [self encryptAndSendComment:composeViewController.text];
        [self updateTheTableViewWithNewComment:composeViewController.text];
    }
}

//TODO: REMOVE THIS IN PROUCTION
-(void)fakeLoader
{
    NSMutableDictionary *userData = [[NSMutableDictionary alloc]init];
    [userData setObject:@"matteo-comisso" forKey:@"username"];
    [userData setObject:@"Matteo Comisso" forKey:@"fullName"];
    
    [[NSUserDefaults standardUserDefaults] setObject:userData forKey:@"MSUserDetails"];
    
    [[NSUserDefaults standardUserDefaults]synchronize];
}

#pragma mark - Send comment to server
-(void)encryptAndSendComment:(NSString *)comment
{
    // Set here a strong password for commenting
    NSString *key = Obfuscate.p.a.s.s.w.o.r.d;
    NSInteger blockSize = 16;
    
    NSMutableDictionary *payload = [[NSMutableDictionary alloc]init];
    
    NSDate *date = [NSDate date];
    double intervalTime = [date timeIntervalSince1970];
    NSString *timeStampIntervalTime = [NSString stringWithFormat:@"%f", intervalTime];
    [payload setObject:timeStampIntervalTime forKey:@"timestamp"];
    
    NSDictionary *MSUserDetails = [[NSUserDefaults standardUserDefaults] objectForKey:@"MSUserDetails"];
    
    [payload setObject:MSUserDetails[@"fullName"] forKey:@"complete_name"];
    [payload setObject:MSUserDetails[@"username"] forKey:@"customer"];
    [payload setObject:self.recipeSlug forKey:@"recipe"];
    [payload setObject:comment forKey:@"comment"];
    
    NSString *dictionaryContent = [NSString stringWithFormat:@"%@", [payload descriptionInStringsFileFormat]];
    
    NSInteger missingChars = blockSize - (dictionaryContent.length % blockSize);
    NSInteger wantedLength = dictionaryContent.length + missingChars;
    
    NSString *paddedString = [dictionaryContent stringByPaddingToLength:wantedLength withString:@"{" startingAtIndex:0];
    
    NSData *resultData = [self cipherData:[paddedString dataUsingEncoding:NSUTF8StringEncoding] key:key];
    
    DLog(@"%@", [resultData base64EncodedStringWithOptions:0]);
    
//    CocoaSecurityResult *aesEncrypt = [CocoaSecurity aesEncrypt:[NSString stringWithFormat:@"%@", paddedString] key:key];
    NSString *encryptedPOST = [NSString stringWithFormat:@"%@", [resultData base64EncodedStringWithOptions:0]];
    
    AFBMHTTPRequestOperationManager *AFBMmanager = [AFBMHTTPRequestOperationManager manager];
    AFBMmanager.requestSerializer = [AFBMHTTPRequestSerializer serializer];
    
    NSString *user = Obfuscate.c.l.i.e.n.t;
    NSString *password = Obfuscate.p.a.s.s.w.o.r.d;
    
    [AFBMmanager.requestSerializer setAuthorizationHeaderFieldWithUsername:user password:password];
    
    NSDictionary *params = @{@"comment":encryptedPOST};
    
    [AFBMmanager POST:BMAPI_CREATE_COMMENT_FOR_RECIPE_SLUG
         parameters:params
            success:^(AFBMHTTPRequestOperation *operation, id responseObject) {
                DLog(@"%@", responseObject);
            }
            failure:^(AFBMHTTPRequestOperation *operation, NSError *error) {
                DLog(@"Error: %@ %@", [error localizedDescription], [error localizedFailureReason]);
            }];
    
}


#pragma mark - AES Reimplementation
- (NSData *)cipherData:(NSData *)data key:(NSString*)key{
    return [self aesOperation:kCCEncrypt OnData:data key:key];
}

- (NSData *)decipherData:(NSData *)data key:(NSString*)key{
    return [self aesOperation:kCCDecrypt OnData:data key:key];
}

- (NSData *)aesOperation:(CCOperation)op
                  OnData:(NSData *)data
                     key:(NSString*)inKey {
    
    const char * key = [inKey UTF8String];
    NSUInteger dataLength = [data length];
    uint8_t unencryptedData[dataLength + kCCKeySizeAES128];
    size_t unencryptedLength;
    
    CCCrypt(op,
            kCCAlgorithmAES128,
            kCCOptionECBMode,
            key,
            kCCKeySizeAES128,
            NULL,
            [data bytes],
            dataLength,
            unencryptedData,
            dataLength,
            &unencryptedLength);
    return [NSData dataWithBytes:unencryptedData length:unencryptedLength];
}



#pragma mark - Update The View
-(void)updateTheTableViewWithNewComment:(NSString *)comment
{

    NSMutableDictionary *userComment = [[NSMutableDictionary alloc]init];
    NSDictionary *msUserDetails = [[NSUserDefaults standardUserDefaults] objectForKey:@"MSUserDetails"];
    NSString *username = [msUserDetails objectForKey:@"username"];
    NSString *fullName = [msUserDetails objectForKey:@"fullName"];

    [userComment setObject:comment forKey:@"comment"];
    [userComment setObject:username forKey:@"username"];
    
    [self.dataSourceOfComments addObject:userComment];
    [self.tableView reloadData];
    self.tableView.alpha = 1.f;
    self.noCommentsLabel.alpha = 0.f;
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