//
//  BMUsageStatisticModel.m
//  BMSdk
//
//  Created by Matteo Comisso on 14/10/14.
//  Copyright (c) 2014 Blue-Mate. All rights reserved.
//

#import "BMUsageStatisticModel.h"
#import <sqlite3.h>
#import "FMDB.h"
#import <sys/utsname.h>

#import "CocoaSecurity.h"
@import UIKit;

@interface BMUsageStatisticModel()

@property (nonatomic, strong) NSString *databasePath;
@property (nonatomic) sqlite3 *database;
@property (nonatomic, strong, readwrite) NSMutableDictionary *analyticsData;

@property (nonatomic,strong) FMDatabase *fmdb;


@end

@implementation BMUsageStatisticModel

+(BMUsageStatisticModel *)sharedInstance
{
    static BMUsageStatisticModel *sharedInstance = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedInstance = [[super alloc]initUniqueInstance];
    });
    
    return sharedInstance;
}

-(id)initUniqueInstance
{
    self = [super init];
    if (self != nil) {
        [self openDatabase];
    }
    return self;
}

#pragma mark - SQLITE initialization and methods
/**
 Apre il database e inizializza le variabili di puntamento della classe. Nel caso non sia presente alcun database, lo crea in Documents con nome "analytics"
 */
-(void)openDatabase
{
    NSString *docsDir;
    NSArray *dirPaths;
    
    dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    docsDir = dirPaths[0];
    
    //Build the path to db file
    _databasePath = [[NSString alloc]initWithString:[docsDir stringByAppendingString:@"/analytics.db"]];
    
    
    _fmdb = [FMDatabase databaseWithPath:_databasePath];
    [_fmdb open];
    [self initializeDatabase];
    [_fmdb executeUpdate:@"PRAGMA foreign_keys = 1;"];

    [self collectStaticData];
}

/**
 Inizializza il database nel caso non sia presente in memoria
 */
-(void)initializeDatabase
{
    const char *dbpath = [_databasePath UTF8String];
    DLog(@"%s", dbpath);
    if (sqlite3_open(dbpath, &_database) == SQLITE_OK) {
        char *errMessage;
        const char *sql_stmt =
        "PRAGMA foreign_keys = ON;\
        CREATE TABLE IF NOT EXISTS analytics ( \
            id INTEGER PRIMARY KEY, \
            customer_key TEXT, \
            session_unique_ID TEXT, \
            in_date DATE, \
            out_date DATE, \
            language TEXT, \
            device TEXT, \
            beacon_major INTEGER, \
            beacon_minor INTEGER, \
            FOREIGN KEY (recipesViewed) REFERENCES recipesViewed(id);\
        \
        CREATE TABLE IF NOT EXISTS recipesViewed (\
            id INTEGER PRIMARY KEY, \
            name TEXT, \
            category TEXT, \
            recipeSlug TEXT);";
        
        if (sqlite3_exec(_database, sql_stmt, NULL, NULL, &errMessage) != SQLITE_OK) {
            DLog(@"[BMUsageStatisticModel]Failed To create table, %s", errMessage);
        }
        sqlite3_close(_database);
        DLog(@"[BMUsageStatisticModel] Done creating Database");
    }
    else
    {
        DLog(@"[BMUsageStatisticModel] Failed to open/create database");
    }
}

#pragma mark - SETUP manager
-(void) collectStaticData
{
    [self checkForeignKeys];
    
    // New Session
    CocoaSecurityResult *sessionID = [CocoaSecurity md5:[NSString stringWithFormat:@"%f%@",
                                                         [NSDate date].timeIntervalSince1970,
                                                         [[UIDevice  currentDevice] identifierForVendor]]];
    
    // Get User unique identifier
    NSUUID *customer_key =[[UIDevice currentDevice] identifierForVendor];

    // Get Device Model Type
    NSString *deviceModel = [self getDeviceModel];

    // Get system language
    NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0];

    DLog(@"SessionID: %@, User Key: %@, Device model: %@, Language: %@", sessionID, customer_key, deviceModel, language);
    
    [self.analyticsData setObject:customer_key forKey:@"user_key"];
    [self.analyticsData setObject:deviceModel forKey:@"device"];
    [self.analyticsData setObject:sessionID.hex forKey:@"session_unique_ID"];
    [self.analyticsData setObject:language forKey:@"language"];
    
    // Save into local database
    [self saveLocally:self.analyticsData];
}

#pragma mark - SAVE
-(void)saveLocally:(NSDictionary *)localRecord
{
    [_fmdb executeUpdate:@"INSERT INTO analytics(customer_key, session_unique_ID, language, device) VALUES (?,?,?,?)", [localRecord objectForKey:@"customer_key"], [localRecord objectForKey:@"session_unique_ID"], [localRecord objectForKey:@"language"], [localRecord objectForKey:@"device"]];
}

-(void)saveSeenRecipe
{
    [_fmdb executeUpdate:@""];
}

#pragma mark - UTILS
-(NSString *)getDeviceModel
{
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *sysInformation = [NSString stringWithCString:systemInfo.machine
                                                  encoding:NSUTF8StringEncoding];
    DLog(@"%@", sysInformation);
    return sysInformation;
}


-(void)checkForeignKeys
{
    FMResultSet *result = [_fmdb executeQuery:@"PRAGMA foreign_keys;"];
    if ([result next]) {
        int response = [result intForColumnIndex:0];
        DLog(@"Foreign key is %d", response);
    }
    [result close];
}

@end
