//
//  BMUsageStatisticModel.m
//  BMSdk
//
//  Created by Matteo Comisso on 14/10/14.
//  Copyright (c) 2014 Blue-Mate. All rights reserved.
//

#import "BMUsageStatisticModel.h"
#import <sqlite3.h>

@interface BMUsageStatisticModel()

@property (nonatomic, strong) NSString *databasePath;
@property (nonatomic) sqlite3 *database;

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
    
    NSFileManager *fileManager = [NSFileManager defaultManager];

    if ([fileManager fileExistsAtPath:_databasePath] == NO)
    {
        DLog(@"[BMUsageStatisticModel] Database not found, initializing...");
        [self initializeDatabase];
    }
    else
    {
        DLog(@"[BMUsageStatisticModel] Database found");
    }
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
            sessionID TEXT, \
            enterTime DATE, \
            exitTime DATE, \
            language TEXT, \
            majorBeacon INTEGER, \
            minorBeacon INTEGER, \
            phoneIdentifier TEXT, \
            usageTimer REAL, \
            FOREIGN KEY (recipesViewed) REFERENCES recipesViewed(id), \
            FOREIGN KEY (functionsUsed) REFERENCES functionsUsed(id));\
        \
        CREATE TABLE IF NOT EXISTS recipesViewed (\
            id INTEGER PRIMARY KEY, \
            name TEXT, \
            category TEXT, \
            recipeSlug TEXT);\
        \
        CREATE TABLE IF NOT EXISTS functionsUsed (\
            id INTEGER PRIMARY KEY, \
            funcName TEXT, \
            times INTEGER, \
            context TEXT);";
        
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

#pragma mark -
#pragma mark - UTILS METHODS
#pragma mark -




@end
