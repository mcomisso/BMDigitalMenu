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
        "PRAGMA foreign_keys = ON;\
        CREATE TABLE IF NOT EXISTS restaraunt (id INTEGER PRIMARY KEY, name TEXT, beaconNumber INTEGER); \
        CREATE TABLE IF NOT EXISTS menu (categoria TEXT, prezzo REAL, visualizzabile INTEGER, nome TEXT, immagine TEXT, data_creazione INTEGER, descrizione TEXT, id INTEGER PRIMARY KEY, locale_id INTEGER, ingredienti TEXT, FOREIGN KEY (locale_id) REFERENCES restaraunt (id));\
        CREATE TABLE IF NOT EXISTS comments (id INTEGER PRIMARY KEY, locale_id INTEGER, ricetta_id INTEGER, comment TEXT, userId INTEGER, FOREIGN KEY (recipe_id) REFERENCES menu(id) );\
        CREATE TABLE IF NOT EXISTS rating (id INTEGER PRIMARY KEY, locale_id INTEGER, ricetta_id INTEGER, ratingValue INTEGER, FOREIGN KEY (recipe_id) REFERENCES menu(id);";
        
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

#pragma mark - Save methods
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
        NSString *nome = JSONArray[i][@"nome"];
        NSString *immagine = JSONArray[i][@"immagine"];
        NSNumber *idPiatto = JSONArray[i][@"id"];
        NSString *ingredienti = JSONArray[i][@"ingredienti"];
        if (JSONArray[i][@"immagine"] == [NSNull null]) {
            immagine = @"nil";
        }

        //Date Formatter
/*        NSDateFormatter *df = [[NSDateFormatter alloc]init];
        [df setDateFormat:@"yyyy-MM-dd hh:mm:ss"];
        NSDate *data_ultima_modifica = [df dateFromString:JSONArray[i][@"data_ultima_modifica"]];
*/
        NSString *descrizione = JSONArray[i][@"descrizione"];
        if ([descrizione isMemberOfClass:[NSNull class]]) {
            descrizione = @"nil";
        }

//        NSNumber *localeId = JSONArray[i][@"locale_id"];
        
        
        sqlite3_stmt *statement;
        const char *dbPath = [_databasePath UTF8String];
        
        if (sqlite3_open(dbPath, &_database) == SQLITE_OK) {

            /*      
             NSString *insertSQL = [NSString stringWithFormat:
                                   @"INSERT INTO menu (categoria, prezzo, nome, immagine, descrizione, id, ingredienti, data_ultima_modifica) VALUES (\"%@\", %@, \"%@\", \"%@\", \"%@\", %@, \"%@\", %f);", categoria, prezzo, nome, immagine, descrizione, idPiatto, ingredienti, [data_ultima_modifica timeIntervalSince1970]];
            */
            NSString *insertSQL = [NSString stringWithFormat:@"INSERT INTO menu (categoria, prezzo, nome, immagine, descrizione, id, ingredienti) VALUES (\"%@\", %@, \"%@\", \"%@\", \"%@\", %@, \"%@\");", categoria, prezzo, nome, immagine, descrizione, idPiatto, ingredienti];
            
            NSLog(@"[BMData manager] insertSQL: %@", insertSQL);
            const char *insert_stmt = [insertSQL UTF8String];
            int response = sqlite3_prepare_v2(_database, insert_stmt, -1, &statement, NULL);
            NSLog(@"Response insert inside DB : %d %s", response, sqlite3_errmsg(self.database));
            
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
            sqlite3_close(_database);
        }
    }
}

-(void)saveCommentsData:(NSArray *)commentsArray
{
    for (int i = 0; i < [commentsArray count]; i++) {

        NSString *ricettaId = [commentsArray[i] objectForKey:@"ricetta_id"];
        NSString *singleComment = [commentsArray[i] objectForKey:@"commento"];
        NSString *userId = [commentsArray[i] objectForKey:@"utente"];
        
        const char *dbPath = [_databasePath UTF8String];
        sqlite3_stmt *statement;
        
        if (sqlite3_open(dbPath, &_database) == SQLITE_OK) {
            //Query id INTEGER PRIMARY KEY, locale_id INTEGER, ricetta_id INTEGER, comment TEXT, userId INTEGER  {"commento": "Tagliere fanstastico, ottimo", "utente": 2, "ricetta_id": 1}
            NSString *query = [NSString stringWithFormat:@"INSERT INTO comments (ricetta_id, comment, userId) VALUES (%@, \"%@\", %@)", ricettaId, singleComment, userId];
            const char *forged = [query UTF8String];
            
            int response = sqlite3_prepare_v2(_database, forged, -1, &statement, NULL);
            NSLog(@"Response insert inside DB : %d %s", response, sqlite3_errmsg(self.database));
            
            if (sqlite3_step(statement) == SQLITE_DONE) {
                NSLog(@"[DataManager] Completed Insert inside database");
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
            sqlite3_close(_database);
        }
    }
}

#pragma mark - Get data methods

/**
 Richiede il menu per il ristorante identificato da restarauntMajorNumber
 @param restarauntMajorNumber Il Major number della rete di beacon che identifica il ristorante.
 */
-(void)checkDataForRestaraunt:(NSNumber *)restarauntMajorNumber
{
    
    NSString *restaraunt = [[NSUserDefaults standardUserDefaults]objectForKey:@"locatedRestaraunt"];
    NSString *lastRecipeDate = [self latestMenuEntryOfRestaraunt:restaraunt];
    
    // Network class manager
    BMDownloadManager *downloadManager = [BMDownloadManager sharedInstance];

    const char *dbPath = [_databasePath UTF8String];
    sqlite3_stmt *statement;
    
    //If there's no errors with the DB, make a query to find data
    if (sqlite3_open(dbPath, &_database) == SQLITE_OK) {
//        NSString *querySQL = [NSString stringWithFormat:@"SELECT data_creazione FROM menu WHERE locale_id = %lu", (long)[restarauntMajorNumber integerValue]];
        NSString *querySQL = [NSString stringWithFormat:@"SELECT data_creazione FROM menu;"];
        const char *query_stmt = [querySQL UTF8String];
        
        if (sqlite3_prepare_v2(_database, query_stmt, -1, &statement, NULL) == SQLITE_OK) {
            if (sqlite3_step(statement) == SQLITE_ROW) {
                NSLog(@"[DataManager] Found Data inside Database!");
                NSLog(@"[DataManager] Check latest recipe date");
                NSString *latestDateInDB = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)];
                // BMNetworkManager -> check latest Date
                if ([latestDateInDB isEqualToString:lastRecipeDate]) {
                    NSLog(@"Già aggiornato.");
                }
                else
                {
                    [self deleteDataFromRestaraunt:[NSString stringWithFormat:@"%@", restarauntMajorNumber]];
                    [downloadManager fetchDataOfRestaraunt:restarauntMajorNumber];
                }
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
-(NSArray *)requestRecipesForCategory:(NSString *)category ofRestaraunt:(NSString *)restarauntID
{
    NSMutableArray *arrval = [[NSMutableArray alloc]init];
    const char *dbPath = [_databasePath UTF8String];
    sqlite3_stmt *statement;
    
    if (sqlite3_open(dbPath, &_database) == SQLITE_OK) {
//        NSString *querySQL = [NSString stringWithFormat:@"SELECT * FROM menu WHERE categoria = \"%@\" AND locale_id = %@", category, restarauntID];
        NSString *querySQL = [NSString stringWithFormat:@"SELECT * FROM menu WHERE categoria = \"%@\";", category];
        const char *forgedStmt = [querySQL UTF8String];
        
        if (sqlite3_prepare_v2(_database, forgedStmt, -1, &statement, NULL) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                //Add all data for selected category
                NSMutableDictionary *recipe = [[NSMutableDictionary alloc]init];

                NSString *nome = [[NSString alloc]initWithUTF8String:(char*)sqlite3_column_text(statement, 3)];
                NSString *prezzo = [[NSString alloc]initWithUTF8String:(char*)sqlite3_column_text(statement, 1)];
                NSString *immagine = [[NSString alloc]initWithUTF8String:(char*)sqlite3_column_text(statement, 4)];
                NSString *idRecipe = [[NSString alloc]initWithUTF8String:(char*)sqlite3_column_text(statement, 7)];
                
                [recipe setObject:nome forKey:@"nome"];
                [recipe setObject:prezzo forKey:@"prezzo"];
                [recipe setObject:immagine forKey:@"immagine"];
                [recipe setObject:idRecipe forKey:@"ricetta_id"];
                
                [arrval addObject:recipe];
            }
        }
        sqlite3_finalize(statement);
    }
    sqlite3_close(_database);
    return arrval;
}

/*
 Richiede i dettagli di un certo piatto
 */
-(NSMutableDictionary*)requestDetailsForRecipe:(NSString *)idRecipe ofRestaraunt:(NSString *)restaraunt
{
    NSMutableDictionary *recipeDetails = [[NSMutableDictionary alloc]init];
    const char *dbPath = [_databasePath UTF8String];
    sqlite3_stmt *statement;
    if (sqlite3_open(dbPath, &_database) == SQLITE_OK) {
//        NSString *querySQL = [NSString stringWithFormat:@"SELECT * FROM menu WHERE id = %@ AND locale_id = %@", idRecipe, restaraunt];
        NSString *querySQL = [NSString stringWithFormat:@"SELECT * FROM menu WHERE id = %@;", idRecipe];
        const char *forged = [querySQL UTF8String];
        
        if (sqlite3_prepare_v2(_database, forged, -1, &statement, NULL) == SQLITE_OK) {
            if (sqlite3_step(statement) == SQLITE_ROW) {
                //Get all data for selected Recipe
                NSString *descrizione = [[NSString alloc]initWithUTF8String:(char*)sqlite3_column_text(statement, 6)];
                NSString *ingredienti = [[NSString alloc]initWithUTF8String:(char*)sqlite3_column_text(statement, 9)];
                
                [recipeDetails setObject:descrizione forKey:@"descrizione"];
                [recipeDetails setObject:ingredienti forKey:@"ingredienti"];
                
            }
            sqlite3_finalize(statement);
        }
        sqlite3_close(_database);
    }
    return recipeDetails;
}

/*Preleva le categorie*/
-(NSArray *)requestCategoriesForRestaraunt:(NSNumber *)restarauntMajorNumber
{
    const char *dbPath = [_databasePath UTF8String];
    sqlite3_stmt *statement;
    
    NSMutableArray *retval = [[NSMutableArray alloc]init];
    
    if (sqlite3_open(dbPath, &_database) == SQLITE_OK) {
//        NSString *query = [[NSString alloc]initWithFormat:@"SELECT DISTINCT categoria FROM menu WHERE locale_id = %@ ORDER BY categoria ASC;", restarauntMajorNumber];
        NSString *query =[[NSString alloc]initWithFormat:@"SELECT DISTINCT categoria FROM menu ORDER BY categoria ASC;"];
        const char *forged = [query UTF8String];
        
        if (sqlite3_prepare_v2(_database, forged, -1, &statement, NULL) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                //Save all in an array
                NSString *categoryName = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)];
                [retval addObject:categoryName];
            }
            sqlite3_finalize(statement);
        }
        sqlite3_close(_database);
    }
    else
    {
        [retval addObject:@"Errors"];
    }
    return retval;
}

-(void)checkCommentsForRecipe:(NSString*)idRecipe
{

}

-(NSArray *)fetchCommentsForRecipe:(NSString *)idRecipe ofRestaraunt:(NSString *)restaraunt
{
    const char *dbPath = [_databasePath UTF8String];
    sqlite3_stmt *statement;
    
    NSMutableArray *retval = [[NSMutableArray alloc]init];
    
    if (sqlite3_open(dbPath, &_database) == SQLITE_OK) {
//        NSString *query = [[NSString alloc]initWithFormat:@"SELECT * FROM commenti WHERE locale_id = %@ AND ricetta_id = %@", restaraunt, idRecipe];
        NSString *query = [[NSString alloc]initWithFormat:@"SELECT * FROM commenti WHERE ricetta_id = %@", idRecipe];
        const char *forged = [query UTF8String];
        
        if (sqlite3_prepare_v2(_database, forged, -1, &statement, NULL) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                // Save all in array
                NSMutableDictionary *singleComment = [[NSMutableDictionary alloc]init];
                
                NSString *user = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 1)];
                NSString *comment = [NSString stringWithUTF8String:(char*)sqlite3_column_text(statement, 2)];
                NSString *date = [NSString stringWithUTF8String:(char*)sqlite3_column_text(statement, 3)];
                
                [singleComment setObject:user forKey:@"user"];
                [singleComment setObject:comment forKey:@"comment"];
                [singleComment setObject:date forKey:@"date"];
                
                [retval addObject:singleComment];
            }
            sqlite3_finalize(statement);
        }
        sqlite3_close(_database);
    }
    else
    {
        [retval addObject:@"Errors"];
    }
    return retval;
}

-(NSNumber *)fetchRatingForRecipe:(NSString *)idRecipe ofRestaraunt:(NSString *)restaraunt
{
    const char *dbPath = [_databasePath UTF8String];
    sqlite3_stmt *statement;
    
    NSNumber *retval = [NSNumber numberWithInt:0];
    
    if (sqlite3_open(dbPath, &_database) == SQLITE_OK) {
        NSString *query = [[NSString alloc]initWithFormat:@"SELECT * FROM commenti WHERE locale_id = %@ AND ricetta_id = %@", restaraunt, idRecipe];
        const char *forged = [query UTF8String];
        
        if (sqlite3_prepare_v2(_database, forged, -1, &statement, NULL) == SQLITE_OK) {
            if (sqlite3_step(statement) == SQLITE_ROW) {
                NSString *numberToConvert = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 3)];
                // Convert string to number
                NSNumberFormatter *nf = [NSNumberFormatter new];
                retval = [nf numberFromString:numberToConvert];
            }
            sqlite3_finalize(statement);
        }
        sqlite3_close(_database);
    }

    return retval;
}

/**
 Gets from internal sqlite database the latest date of a menu
 @param restarauntId The Id of one restaraunt
 @return
 */
-(NSString *)latestMenuEntryOfRestaraunt:(NSString *)restarauntId
{
    NSString *latestDate;
    const char *dbPath = [_databasePath UTF8String];
    sqlite3_stmt *statement;
    if (sqlite3_open(dbPath, &_database) == SQLITE_OK) {
        NSString *query = [NSString stringWithFormat:@"SELECT id, data_creazione FROM menu WHERE locale_id = %@ ORDER BY data_creazione DESC LIMIT 1;", restarauntId];
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

#pragma mark - Delete data from menu

-(void)deleteDataFromRestaraunt:(NSString *)restarauntId
{
    const char *dbPath = [_databasePath UTF8String];
    sqlite3_stmt *statement;
    if (sqlite3_open(dbPath, &_database) == SQLITE_OK) {
        NSString *query = [NSString stringWithFormat:@"DELETE FROM menu WHERE locale_id = %@;", restarauntId];
        const char *forged = [query UTF8String];
        
        if (sqlite3_prepare(_database, forged, -1, &statement, NULL) == SQLITE_OK) {
            //DONE
            
            sqlite3_finalize(statement);
        }
        sqlite3_close(_database);
    }
}

#pragma mark - Comments and rating Management
-(NSArray *)requestCommentsForRecipe:(NSString *)recipeId
{
    NSMutableArray *comments = [[NSMutableArray alloc]init];
    
    const char *dbPath = [_databasePath UTF8String];
    sqlite3_stmt *statement;
    if (sqlite3_open(dbPath, &_database) == SQLITE_OK) {
        NSString *query = [NSString stringWithFormat:@"SELECT * FROM commenti WHERE ricetta_id = %@", recipeId];
        const char *forged = [query UTF8String];
        
        if (sqlite3_prepare(_database, forged, -1, &statement, NULL) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                NSMutableDictionary *specificComment = [[NSMutableDictionary alloc]init];
                
                NSString *textComment = [NSString stringWithUTF8String:(char*)sqlite3_column_text(statement, 1)];
                NSString *userId = [NSString stringWithUTF8String:(char*)sqlite3_column_text(statement, 0)];
                
                [specificComment setObject:textComment forKey:@"comment"];
                [specificComment setObject:userId forKey:@"userId"];
                
                [comments addObject:specificComment];
            }
            sqlite3_finalize(statement);
        }
        sqlite3_close(_database);
    }
    return comments;
}

-(int)requestRatingForRecipe:(NSString *)recipeId
{
    int averageVote = 0;
    
    const char *dbPath = [_databasePath UTF8String];
    sqlite3_stmt *statement;
    if (sqlite3_open(dbPath, &_database) == SQLITE_OK) {
        NSString *query = [NSString stringWithFormat:@"SELECT averageVote FROM rating WHERE ricetta_id = %@", recipeId];
        const char *forged = [query UTF8String];
        
        if (sqlite3_prepare(_database, forged, -1, &statement, NULL) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                //Save Data
                NSString *averageVoteString = [NSString stringWithUTF8String:(char*)sqlite3_column_text(statement, 0)];
                averageVote = [averageVoteString intValue];
            }
            sqlite3_finalize(statement);
        }
        sqlite3_close(_database);
    }
    
    return averageVote;
}

@end
