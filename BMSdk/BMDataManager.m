//
//  BMDataManager.m
//  BMSdk
//
//  Created by Matteo Comisso on 05/08/14.
//  Copyright (c) 2014 Blue-Mate. All rights reserved.
//

#import "BMDataManager.h"   
#import <sqlite3.h>
#import "BMDownloadManager.h"


@interface BMDataManager()

@property (nonatomic, strong) NSString *databasePath;
@property (nonatomic) sqlite3 *database;

@end

@implementation BMDataManager

+(BMDataManager *)sharedInstance
{
    static BMDataManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedInstance = [[super alloc]initUniqueInstance];
    });
    
    return sharedInstance;
}

-(id)initUniqueInstance
{
    self = [super init];
    
    if (self != nil)
    {
        [self openDatabase];
    }
    
    return self;
}

#pragma mark - SQLITE initialization and methods
/**
 Apre il database e inizializza le variabili di puntamento della classe. Nel caso non sia presente alcun database, lo crea in Documents.
 */
-(void)openDatabase
{
    NSString *docsDir;
    NSArray *dirPaths;

    dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    docsDir = dirPaths[0];
    
    //Build the path to db file
    _databasePath = [[NSString alloc]initWithString:[docsDir stringByAppendingString:@"/database.db"]];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    //Check if database exists
    if ([fileManager fileExistsAtPath:_databasePath] == NO)
    {
        NSLog(@"[DataManager] Database not found, initializing...");
        [self initializeDatabase];

    }
    else
    {
        NSLog(@"[DataManager] Database found");
    }
}

/**
 Inizializza il database nel caso non sia presente in memoria
 */
-(void)initializeDatabase
{
    const char *dbpath = [_databasePath UTF8String];
    NSLog(@"%s", dbpath);
    if (sqlite3_open(dbpath, &_database) == SQLITE_OK) {
        char *errMessage;
        const char *sql_stmt =
        "CREATE TABLE IF NOT EXISTS restaraunt (ID INTEGER PRIMARY KEY AUTOINCREMENT, NAME TEXT); \
        CREATE TABLE IF NOT EXISTS menu (categoria TEXT, prezzo REAL, visualizzabile INTEGER, nome TEXT, immagine TEXT, data_creazione INTEGER, descrizione TEXT, id INTEGER PRIMARY KEY, locale_id INTEGER, ingredienti TEXT);";
        if (sqlite3_exec(_database, sql_stmt, NULL, NULL, &errMessage) != SQLITE_OK) {
            NSLog(@"[DataManager]Failed To create table");
        }
        sqlite3_close(_database);
        NSLog(@"[DataManager] Done creating Database");
    }
    else
    {
        NSLog(@"[DataManager] Failed to open/create database");
    }
}

-(void)enableForeignKeys
{
    const char *dbPath = [_databasePath UTF8String];
    
    if (sqlite3_open(dbPath, &_database)) {
        NSString *stringedQuery = @"PRAGMA foreign_keys = ON;";
        const char *enablerQuery = [stringedQuery UTF8String];
        
        sqlite3_stmt *statement;
        sqlite3_prepare_v2(_database, enablerQuery, -1, &statement, NULL);
        if (sqlite3_step(statement) == SQLITE_DONE) {
            NSLog(@"[DataManager] Foreign Keys Enabled");
        }
    }
    
}

/**
 Salva tutti i piatti di un menu ricevuto come Array[Piatto][Piatto][...]
 @param JSONArray L'array contenente in ogni cella un JSON compatibile con tutte le informazioni per il salvataggio in memoria
 */
-(void)saveMenuData:(NSArray *)JSONArray
{
    for (int i = 0; i < [JSONArray count]; i++) {

        // Data to be saved
        NSString *categoria = JSONArray[i][@"categoria"];
        NSNumber *prezzo = JSONArray[i][@"prezzo"];
        NSNumber *visualizzabile = JSONArray[i][@"visualizzabile"];
        NSString *nome = JSONArray[i][@"nome"];
        NSString *immagine = JSONArray[i][@"immagine"];

        if (JSONArray[i][@"immagine"] == [NSNull null]) {
            immagine = @"nil";
        }

        //Date Formatter
        NSDateFormatter *df = [[NSDateFormatter alloc]init];
        [df setDateFormat:@"yyyy-MM-dd hh:mm:ss"];
        NSDate *dataCreazione = [df dateFromString:JSONArray[i][@"data_creazione"]];
        
        NSString *descrizione = JSONArray[i][@"descrizione"];
        if ([descrizione isMemberOfClass:[NSNull class]]) {
            descrizione = @"nil";
        }
        NSNumber *idPiatto = JSONArray[i][@"id"];
        NSNumber *localeId = JSONArray[i][@"locale_id"];
        NSString *ingredienti = JSONArray[i][@"ingredienti"];
        
        sqlite3_stmt *statement;
        const char *dbPath = [_databasePath UTF8String];
        
        if (sqlite3_open(dbPath, &_database) == SQLITE_OK) {
            NSString *insertSQL = [NSString stringWithFormat:
                                   @"INSERT INTO menu (categoria, prezzo, visualizzabile, nome, immagine, data_creazione, descrizione, id, locale_id, ingredienti) VALUES (\"%@\", %@, %@, \"%@\", \"%@\", %f, \"%@\", %@, %@, \"%@\");", categoria, prezzo, visualizzabile, nome, immagine, [dataCreazione timeIntervalSince1970], descrizione, idPiatto, localeId, ingredienti];
            NSLog(@"%@", insertSQL);
            const char *insert_stmt = [insertSQL UTF8String];
            int response = sqlite3_prepare_v2(_database, insert_stmt, -1, &statement, NULL);
            NSLog(@"Response insert inside DB : %d", response);
            
            NSLog(@"%s", sqlite3_errmsg(self.database));
            
            if (sqlite3_step(statement) == SQLITE_DONE) {
                NSLog(@"[DataManager] Completed insert in database");
            }
            else
            {
                NSLog(@"[DataManager] Failed insert into database");
            }
            sqlite3_finalize(statement);
            sqlite3_close(_database);
        }
        else
        {
            NSLog(@"[DataManager] save - Failed to open database");
        }
    }
}

/**
 Richiede il menu per il ristorante identificato da restarauntMajorNumber
 @param restarauntMajorNumber Il Major number della rete di beacon che identifica il ristorante.
 */
-(void)requestDataForRestaraunt:(NSNumber *)restarauntMajorNumber
{
    // Network class manager
    BMDownloadManager *downloadManager = [BMDownloadManager sharedInstance];

    const char *dbPath = [_databasePath UTF8String];
    sqlite3_stmt *statement;
    
    //If there's no errors with the DB, make a query to find data
    if (sqlite3_open(dbPath, &_database) == SQLITE_OK) {
        NSString *querySQL = [NSString stringWithFormat:@"SELECT * FROM menu WHERE locale_id = %lu", (long)[restarauntMajorNumber integerValue]];
        const char *query_stmt = [querySQL UTF8String];
        
        if (sqlite3_prepare_v2(_database, query_stmt, -1, &statement, NULL) == SQLITE_OK) {
            if (sqlite3_step(statement) == SQLITE_ROW) {
                //GET ALL DATA
                NSLog(@"[DataManager] Found Data inside Database! Statement description");
            }
            else
            {
                //NOT FOUND
                NSLog(@"[DataManager] No Data found inside database, requesting from network");
                [downloadManager fetchDataOfRestaraunt:restarauntMajorNumber];
            }
            sqlite3_finalize(statement);
        }
        sqlite3_close(_database);
    }
}

/**
 Richiede tutti i piatti di una certa categoria
 */
-(NSArray *)requestDataForCategory:(NSString *)category
{
    NSMutableArray *arrval = [[NSMutableArray alloc]init];
    const char *dbPath = [_databasePath UTF8String];
    sqlite3_stmt *statement;
    
    if (sqlite3_open(dbPath, &_database) == SQLITE_OK) {
        NSString *querySQL = [NSString stringWithFormat:@"SELECT * FROM menu WHERE categoria = \"%@\"", category];
        const char *forgedStmt = [querySQL UTF8String];
        
        if (sqlite3_prepare_v2(_database, forgedStmt, -1, &statement, NULL) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                //Add all data for selected category
                NSString *name = [[NSString alloc]initWithUTF8String:(char*)sqlite3_column_text(statement, 1)];
                NSMutableDictionary *recipe = [[NSMutableDictionary alloc]init];
                [recipe setObject:name forKey:@"name"];
                [arrval addObject:recipe];
            }
            sqlite3_finalize(statement);
        }
        sqlite3_close(_database);
    }
    return arrval;
}

/**
 Richiede i dettagli di un certo piatto
 */
-(void)requestDataForRecipe:(NSString *)idRecipe ofRestaraunt:(NSString *)restaraunt
{
    const char *dbPath = [_databasePath UTF8String];
    sqlite3_stmt *statement;
    if (sqlite3_open(dbPath, &_database) == SQLITE_OK) {
        NSString *querySQL = [NSString stringWithFormat:@"SELECT * FROM menu WHERE id = %@ AND locale_id = %@", idRecipe, restaraunt];
        const char *forged = [querySQL UTF8String];
        
        if (sqlite3_prepare_v2(_database, forged, -1, &statement, NULL) == SQLITE_OK) {
            if (sqlite3_step(statement) == SQLITE_ROW) {
                //Get all data for selected Recipe
                NSLog(@"");
            }
            sqlite3_finalize(statement);
        }
        sqlite3_close(_database);
    }
}

-(NSString *)checkLatestCreationDate
{
    NSString *latestDate;
    const char *dbPath = [_databasePath UTF8String];
    sqlite3_stmt *statement;
    if (sqlite3_open(dbPath, &_database) == SQLITE_OK) {
        NSString *query = [NSString stringWithFormat:@"SELECT id, data_creazione FROM ricetta ORDER BY data_creazione DESC LIMIT 1;"];
        const char *forged = [query UTF8String];
        
        if (sqlite3_prepare_v2(_database, forged, -1, &statement, NULL) == SQLITE_OK) {
            if (sqlite3_step(statement) == SQLITE_ROW) {
                //Fetched latest
                // Request backend to fetch
                latestDate = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 1)];
                return latestDate;
            }
            sqlite3_finalize(statement);
        }
        sqlite3_close(_database);
    }
    return nil;
}

@end
