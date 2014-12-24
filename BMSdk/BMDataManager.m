//
//  BMDataManager.m
//  BMSdk
//
//  Created by Matteo Comisso on 05/08/14.
//  Copyright (c) 2014 Blue-Mate. All rights reserved.
//


#import "BMDownloadManager.h"
#import "BMDataManager.h"   

#import <sqlite3.h>
#import "FMDB.h"

#import "RestaurantInfo.h"

@interface BMDataManager()

@property (nonatomic, strong) NSString *databasePath;
@property (nonatomic) sqlite3 *database;

@property (nonatomic,strong) FMDatabase *fmdb;

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
        NSString *docsDir;
        NSArray *dirPaths;
        
        dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        docsDir = dirPaths[0];
        
        _databasePath = [[NSString alloc]initWithString:[docsDir stringByAppendingString:@"/database.db"]];
        _fmdb = [FMDatabase databaseWithPath:_databasePath];
        [_fmdb open];
        [self initializeDatabase];
        [_fmdb executeUpdate:@"PRAGMA foreign_keys = 1;"];
    }
    
    return self;
}

#pragma mark - SQLITE initialization and methods

-(void)checkForeignKeys
{
    FMResultSet *result = [_fmdb executeQuery:@"PRAGMA foreign_keys;"];
    if ([result next]) {
        int response = [result intForColumnIndex:0];
        NSLog(@"Foreign key is %d", response);
    }
    [result close];
}

/**
 Inizializza il database nel caso non sia presente in memoria
 */
-(void)initializeDatabase
{
    
    NSString *createDB =
        @"CREATE TABLE IF NOT EXISTS restaurant (id INTEGER PRIMARY KEY AUTOINCREMENT, slug TEXT UNIQUE, name TEXT, majorBeacon INTEGER, minorBeacon INTEGER); "
    
        @"CREATE TABLE IF NOT EXISTS recipe (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, price REAL, category TEXT, last_edit_datetime DATE, image_url TEXT, description TEXT, ingredients TEXT, slug TEXT UNIQUE, avg_rating INTEGER, restaurant_slug TEXT, FOREIGN KEY (restaurant_slug) REFERENCES restaurant(slug) ON DELETE CASCADE);"
    
        @"CREATE TABLE IF NOT EXISTS dayMenu ( id INTEGER PRIMARY KEY AUTOINCREMENT, day DATE, name TEXT, slug TEXT, price REAL, category TEXT,restaurant_slug TEXT, FOREIGN KEY (restaurant_slug) REFERENCES restaurant(slug) ON DELETE CASCADE );"
    
        @"CREATE TABLE IF NOT EXISTS bestMatch ( id INTEGER PRIMARY KEY, base_recipe_slug TEXT, target_recipe_slug TEXT, FOREIGN KEY (base_recipe_slug) REFERENCES recipe(slug) ON DELETE CASCADE, FOREIGN KEY (target_recipe_slug) REFERENCES recipe(slug) ON DELETE CASCADE);"
    
        @"CREATE TABLE IF NOT EXISTS comment (id INTEGER PRIMARY KEY AUTOINCREMENT, customer TEXT, comment_datetime TEXT, comment TEXT, recipe_slug TEXT, FOREIGN KEY (recipe_slug) REFERENCES recipe(slug) ON DELETE CASCADE);"
    
        @"CREATE TABLE IF NOT EXISTS cartManager(id INTEGER PRIMARY KEY, recipe_slug TEXT, FOREIGN KEY (recipe_slug) REFERENCES recipe(slug) ON DELETE CASCADE);"
    
        @"CREATE TABLE IF NOT EXISTS orders (id INTEGER PRIMARY KEY AUTOINCREMENT, orderDate DATE, recipe_name TEXT, recipe_image_url TEXT, recipe_slug TEXT, recipe_ingredients TEXT, recipe_price REAL, restaurant_slug TEXT);";
    
    if ([_fmdb executeStatements:createDB])
    {
        NSLog(@"Creation completed");
    }
    else
    {
        NSLog(@"ERRORS while creating database %@, %@ - Error Code: %d", [_fmdb lastError], [_fmdb lastErrorMessage], [_fmdb lastErrorCode]);
    }
    
    [self checkForeignKeys];
}

#pragma mark - Save methods
/**
 Salva tutti i piatti di un menu ricevuto come Array[Piatto][Piatto][...]
 @param JSONArray L'array contenente in ogni cella un JSON compatibile con tutte le informazioni per il salvataggio in memoria
 */
-(void)saveMenuData:(NSArray *)JSONArray
{
    [self checkForeignKeys];
    
    //Statement for inserting the restaurant data in db, before the recipes
    RestaurantInfo *restaurant = [RestaurantInfo new];
    
    restaurant.name = JSONArray[0][@"restaurant"][@"name"];
    restaurant.slug = JSONArray[0][@"restaurant"][@"slug"];

    restaurant.minorBeacon = [[NSUserDefaults standardUserDefaults] objectForKey:@"minorBeacon"];
    restaurant.majorBeacon = [[NSUserDefaults standardUserDefaults] objectForKey:@"majorBeacon"];

        if ([_fmdb executeUpdate:@"INSERT INTO restaurant (slug, name, majorBeacon, minorBeacon) VALUES (?, ?, ?, ?)", restaurant.slug, restaurant.name, restaurant.majorBeacon, restaurant.minorBeacon])
        {
            NSLog(@"Saved data");
        }
        else
        {
            NSLog(@"%@, %d, %@", [_fmdb lastError], [_fmdb lastErrorCode], [_fmdb lastErrorMessage]);
        }

    //TODO: change for loop with increased performance forin
    for (int i = 0; i < [JSONArray count]; i++) {
        
        RecipeInfo *recipe = [RecipeInfo new];
        
        recipe.name = JSONArray[i][@"name"];
        recipe.category = JSONArray[i][@"category"][@"name"];
        recipe.price = JSONArray[i][@"price"];
        recipe.slug = JSONArray[i][@"slug"];
        recipe.ingredients = JSONArray[i][@"ingredients"];
        recipe.image_url = JSONArray[i][@"image_url"]; // if nil -> @"<null>"
        recipe.last_edit_datetime = [self dateFromString:JSONArray[i][@"last_edit_datetime"]]; // if nil -> @"<null>"
        recipe.recipe_description = JSONArray[i][@"description"]; //if nil -> @"<null>"
        recipe.best_match = [NSArray arrayWithArray:JSONArray[i][@"best_match"]];
        
        if ([_fmdb executeUpdate:@"INSERT INTO recipe VALUES (NULL, ?, ?, ?, ?, ?, ?, ?, ?, 0, ?)", recipe.name, recipe.price, recipe.category, recipe.last_edit_datetime, recipe.image_url, recipe.recipe_description, recipe.ingredients, recipe.slug, restaurant.slug]) {
            NSLog(@"Saved Recipe with slug: %@", recipe.slug);
        }
        else
        {
            NSLog(@"Error while saving recipe: %@,  %@, - Error Code %d", [_fmdb lastError], [_fmdb lastErrorMessage], [_fmdb lastErrorCode]);
        }
    }
    
    [[NSNotificationCenter defaultCenter]postNotificationName:@"updateMenu" object:@"YES"];
    
    //Maybe in a new thread
    [self performSelector:@selector(saveBestMatch:) withObject:JSONArray];
}

/**
 BestMatch saves all the recipes fetched from the database inside the backend.
 @param recipeArray Array containing the recipes with bestmatch
 */
-(void)saveBestMatch:(NSArray *)recipeArray
{
    int numberOfRecipes = (int)[recipeArray count];
    
    for (int i = 0; i < numberOfRecipes; i++) {
        NSArray *bestMatchForCurrentRecipe = recipeArray[i][@"best_match"];
        NSString *recipeSlug = recipeArray[i][@"slug"];
        
        int numberOfRecipesInBestmatch = (int) [bestMatchForCurrentRecipe count];
        
        for (int j = 0; j < numberOfRecipesInBestmatch; j++) {

            if([_fmdb executeUpdate:@"INSERT INTO bestMatch(base_recipe_slug, target_recipe_slug) VALUES (?, ?);", recipeSlug, bestMatchForCurrentRecipe[j][@"slug"]])
            {
                NSLog(@"Done inserting data into bestMatch for recipe %@", recipeSlug);
            }
            else
            {
                NSLog(@"Errors while insering bestmatch: %@ %@ %d", [_fmdb lastError], [_fmdb lastErrorMessage], [_fmdb lastErrorCode]);
            }
        }
    }
}

/**
 Saves the current day menu inside the database, for quick caching.
 @param JSONArray The array containg all the recipes
 */
-(void)saveMenu:(NSDictionary *)JSONArray forDay:(NSString *)day
{
    //Slug of restaurant
    NSString *restaurantSlug = JSONArray[@"restaurant"][@"slug"];
    NSLog(@"JSONArray[restaurant][slug]: %@", restaurantSlug);
    
    NSArray *recipes = JSONArray[@"recipes"];

    NSLog(@"Downloaded Day Menu recipes description %@", [recipes description]);

    int recipesCount = (int)[JSONArray[@"recipes"] count];

    for (int i = 0; i < recipesCount; i++) {
        RecipeInfo *dayRecipe = [RecipeInfo new];
        
        dayRecipe.slug = recipes[i][@"slug"];
        dayRecipe.price = recipes[i][@"price"];
        dayRecipe.name = recipes[i][@"name"];
        dayRecipe.category = [recipes[i][@"category"][@"name"] lowercaseString];
        
        if([_fmdb executeUpdate:@"INSERT INTO dayMenu(day, restaurant_slug, category, name, slug, price) VALUES (?, ?, ?, ?, ?, ?);", day, restaurantSlug, dayRecipe.category, dayRecipe.name, dayRecipe.slug, dayRecipe.price])
        {
            NSLog(@"Done inserting data into DayMenu. Recipe: %@", dayRecipe.slug);
        }
        else
        {
            NSLog(@"Errors while insering daymenu: %@ %@ %d", [_fmdb lastError], [_fmdb lastErrorMessage], [_fmdb lastErrorCode]);
        }
    }
    [[NSNotificationCenter defaultCenter]postNotificationName:@"restaurantHasDayMenu" object:@"YES"];
}

-(void)saveOrderedListInHistory:(NSArray *)orderedList
{
//    @"CREATE TABLE IF NOT EXISTS orders (id INTEGER PRIMARY KEY AUTOINCREMENT, orderDate DATE, recipe_name TEXT, recipe_image_url TEXT, recipe_slug TEXT UNIQUE, recipe_ingredients TEXT, recipe_price REAL);";
    
    for (NSString *slug in orderedList) {
        
        RecipeInfo *recipe = [self requestDetailsForRecipe:slug];

        if ([_fmdb executeUpdate:@"INSERT INTO orders(orderDate, recipe_name, recipe_image_url, recipe_slug, recipe_ingredients, recipe_price, restaurant_slug) VALUES (?, ?, ?, ?, ?, ?, ?);", [NSDate date], recipe.name, recipe.image_url, recipe.slug, recipe.ingredients, recipe.price, [[NSUserDefaults standardUserDefaults] objectForKey:@"restaurantSlug"]])
        {
            NSLog(@"Done inserting data into orders");
        }
        else
        {
            NSLog(@"Errors while inserting orders in history. %@ %@ %d", [_fmdb lastError], [_fmdb lastErrorMessage], [_fmdb lastErrorCode]);
        }
    }
}

#pragma mark - Get data methods

/*Preleva le categorie*/
-(NSArray *)requestCategoriesForRestaurantMajorNumber:(NSNumber *)restaurantMajorNumber andMinorNumber:(NSNumber *)restaurantMinorNumber
{
    [self checkForeignKeys];
    
    NSMutableArray *retval = [[NSMutableArray alloc]init];

        FMResultSet *results = [_fmdb executeQuery:@"SELECT DISTINCT category FROM recipe WHERE restaurant_slug = (SELECT slug FROM restaurant WHERE majorBeacon = ? AND minorBeacon = ? LIMIT 1);", restaurantMajorNumber, restaurantMinorNumber];
        while([results next]) {
            NSString *categoryName = [results stringForColumn:@"category"];
            [retval addObject:categoryName];
        }
    [results close];
    return retval;
}

/**
 Richiede tutti i piatti di una certa category
 */
-(NSArray *)requestRecipesForCategory:(NSString *)category ofRestaurantMajorNUmber:(NSNumber *)restaurantMajorNumber andMinorNumber:(NSNumber *)restaurantMinorNumber
{
    NSMutableArray *arrval = [[NSMutableArray alloc]init];
    

        FMResultSet *results = [_fmdb executeQuery:@"SELECT * FROM recipe WHERE category = ? AND restaurant_slug = (SELECT slug FROM restaurant WHERE majorBeacon = ? AND minorBeacon = ? LIMIT 1);", category, restaurantMajorNumber, restaurantMinorNumber];
        while ([results next]) {
            RecipeInfo *recipe = [RecipeInfo new];
            
            //Add all data for selected category
            recipe.name = [results stringForColumn:@"name"];
            recipe.price = [NSNumber numberWithDouble:[results doubleForColumn:@"price"]];
            recipe.image_url = [results stringForColumn:@"image_url"];
            recipe.ingredients = [results stringForColumn:@"ingredients"];
            recipe.slug = [results stringForColumn:@"slug"];
            
            [arrval addObject:recipe];
        }
    return arrval;
}

/*
 Richiede i dettagli di un certo piatto
 */
-(RecipeInfo *)requestDetailsForRecipe:(NSString *)recipeSlug
{
    RecipeInfo *recipeDetails = [RecipeInfo new];

    FMResultSet *results = [_fmdb executeQuery:@"SELECT description, ingredients FROM recipe WHERE slug = ? LIMIT 1;", recipeSlug];
    
    if ([results next]) {
        recipeDetails.recipe_description = [results stringForColumn:@"description"];
        recipeDetails.ingredients = [results stringForColumn:@"ingredients"];
    }
    
    [results close];
    
    return recipeDetails;
}

#pragma mark - CARTMANAGER
#pragma mark Fetch data for cart

-(NSMutableArray *)requestDataForCart:(NSArray*)listOfRecipesToFind
{
    if ([listOfRecipesToFind count] != 0) {
        NSMutableArray *retval = [[NSMutableArray alloc]initWithCapacity:[listOfRecipesToFind count]];

        
        for (NSString *slug in listOfRecipesToFind) {
            FMResultSet *result = [_fmdb executeQuery:@"SELECT * FROM recipe WHERE slug = ?;", slug];
            if ([result next]) {
                RecipeInfo *recipe = [RecipeInfo new];
                recipe.name = [result stringForColumn:@"name"];
                recipe.price = [NSNumber numberWithDouble:[result doubleForColumn:@"price"]];
                recipe.category = [result stringForColumn:@"category"];
                recipe.image_url = [result stringForColumn:@"image_url"];
                recipe.slug = [result stringForColumn:@"slug"];
                
                [retval addObject:recipe];
            }
        }
        return retval;
    }
    return nil;
}

#pragma mark - Comments and rating Management

/* Saves all the comments for the recipe */
-(void)saveCommentsData:(NSDictionary *)commentsDictionary
{
    NSArray *commentsArray = [commentsDictionary objectForKey:@"commenti"];
    for (int i = 0; i < [commentsArray count]; i++) {
        
        NSString *recipe_slug = [commentsArray[i] objectForKey:@"ricetta_id"];
        NSString *singleComment = [commentsArray[i] objectForKey:@"commento"];
        NSString *userId = [commentsArray[i] objectForKey:@"utente"];
        
        if ([_fmdb executeUpdate:@"INSERT INTO comment (recipe_slug, comment, customer) VALUES (?, ?, ?);", recipe_slug, singleComment, userId])
        {
            NSLog(@"Completed insert of comment");
        }
        else
        {
            NSLog(@"Error while inserting comment %@ %@ %d", [_fmdb lastError], [_fmdb lastErrorMessage], [_fmdb lastErrorCode]);
        }
    }
}

-(void)deleteCommentsOfRecipe:(NSString *)recipeSlug
{
    if ([_fmdb executeUpdate:@"DELETE FROM comment WHERE recipe_slug = ?;", recipeSlug]) {
        NSLog(@"Deleted successfully the comments of %@", recipeSlug);
    }
    else
    {
        NSLog(@"Errors while deleting the comments of %@. Error: %@ %@ %d", recipeSlug, [_fmdb lastError], [_fmdb lastErrorMessage], [_fmdb lastErrorCode]);
    }
}

-(NSArray *)requestCommentsForRecipe:(NSString *)recipeSlug
{
    NSMutableArray *retval = [[NSMutableArray alloc]init];
    
    FMResultSet *results = [_fmdb executeQuery:@"SELECT * FROM comment WHERE recipe_slug = ?;", recipeSlug];
    
    while ([results next]) {
        NSMutableDictionary *singleComment = [[NSMutableDictionary alloc]init];
        
        int userID = [results intForColumn:@""];
        NSString *comment = [results stringForColumn:@""];
        
        [singleComment setObject:[NSNumber numberWithInt:userID] forKey:@"user"];
        [singleComment setObject:comment forKey:@"comment"];
        
        [retval addObject:singleComment];
    }
    
    return retval;
}

#pragma mark - Rating
-(void)saveRatingValue:(NSNumber *)value forRecipe:(NSString *)recipeSlug
{
    if ([_fmdb executeUpdate:@"UPDATE recipe SET avg_rating = ? WHERE slug = ?;", value, recipeSlug]) {
        NSLog(@"Updated average rating of recipe %@", recipeSlug);
    }
    else
    {
        NSLog(@"Errors while updating average rating of %@. Errors: %@ %@ | Code: %d", recipeSlug, [_fmdb lastError], [_fmdb lastErrorMessage], [_fmdb lastErrorCode]);
    }
}

-(int)requestRatingForRecipe:(NSString *)recipeSlug
{
    int retval = 0;
    
    FMResultSet *result = [_fmdb executeQuery:@"SELECT avg_rating FROM recipe WHERE slug = ?", recipeSlug];
    if ([result next]) {
        int rating =  [result intForColumn:@"avg_rating"];
        retval = rating;
    }
    return retval;
}

-(NSDictionary *)requestRatingForRecipesInCategory:(NSString *)category
{
    NSMutableDictionary *retval = [[NSMutableDictionary alloc]init];
    FMResultSet *results = [_fmdb executeQuery:@"SELECT avg_rating, recipe_slug FROM recipe WHERE slug IN (SELECT slug FROM recipe WHERE category = ?);", category];

    while ([results next]) {
        int rating = [results intForColumn:@"avg_rating"];
        NSString *recipeSlug = [results stringForColumn:@"recipe_slug"];
        
        [retval setObject:[NSNumber numberWithInt:rating] forKey:recipeSlug];
    }
    
    return retval;
}

#pragma mark -
/**
 Gets from internal sqlite database the latest date of a menu
 @param restaurantId The Id of one restaurant
 @return String with the latest date.
 */
-(NSString *)latestMenuEntryOfRestaurant:(NSString *)restaurantSlug
{
    NSString *latestDateString;
    
    FMResultSet *result = [_fmdb executeQuery:@"SELECT * FROM recipe WHERE restaurant_slug = ? ORDER BY last_edit_datetime DESC LIMIT 1;", restaurantSlug];
    if ([result next]) {
        latestDateString = [result stringForColumn:@"last_edit_datetime"];
    }
    else
    {
        latestDateString = @"";
    }
    return latestDateString;
}

-(int)numberOfrecipesInCacheForRestaurant:(NSString *)restaurantSlug
{
    int total = 0;

    FMResultSet *result = [_fmdb executeQuery:@"SELECT COUNT(*) FROM recipe WHERE restaurant_slug = ?;", restaurantSlug];
    if ([result next]) {
        total = [result intForColumnIndex:0];
    }
    return total;
}

#pragma mark - PDF utils
-(NSString *)pathToPDFDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachesDirectory = [paths firstObject];
    NSString *dataPath = [cachesDirectory stringByAppendingPathComponent:@"/PDF"];
    NSError *error = nil;
    
    if (![[NSFileManager defaultManager]fileExistsAtPath:dataPath]) {
        [[NSFileManager defaultManager]createDirectoryAtPath:dataPath withIntermediateDirectories:NO attributes:nil error:&error];
        if (error) {
            NSLog(@"Error while creating directory: %@, %@", [error localizedDescription], [error localizedFailureReason]);
            return nil;
        }
    }
    return dataPath;
}

#pragma mark - NSUserDefaults delete
-(void)applicationWillCloseGuard
{
    [[NSUserDefaults standardUserDefaults]removeObjectForKey:@"majorBeacon"];
    [[NSUserDefaults standardUserDefaults]removeObjectForKey:@"minorBeacon"];
    [[NSUserDefaults standardUserDefaults]synchronize];
}

#pragma mark - BestMatch
-(NSMutableArray *)bestMatchForRecipe:(NSString *)recipeSlug
{
    NSMutableArray *retval = [[NSMutableArray alloc]init];
    FMResultSet *combined = [_fmdb executeQuery:@"SELECT * FROM recipe AS r JOIN bestMatch AS b ON r.slug = b.target_recipe_slug WHERE base_recipe_slug = ?", recipeSlug];

    while ([combined next]) {
        RecipeInfo *recipe = [RecipeInfo new];
        
        recipe.name = [combined stringForColumn:@"name"];
        recipe.slug = [combined stringForColumn:@"slug"];
        recipe.image_url = [combined stringForColumn:@"image_url"];
        recipe.recipe_description = [combined stringForColumn:@"description"];
        recipe.ingredients = [combined stringForColumn:@"ingredients"];
        recipe.category = [combined stringForColumn:@"category"];
        
        
        [retval addObject:recipe];
    }
    
    [combined close];
    
    return retval;
}

#pragma mark - Day Menu
-(NSMutableDictionary *)fetchDayMenuForRestaurant:(NSString *)restaurantSlug andDay:(NSString *)day
{
    NSMutableDictionary *retval = [[NSMutableDictionary alloc]init];


    FMResultSet *categories = [_fmdb executeQuery:@"SELECT DISTINCT category FROM dayMenu WHERE day = ? AND restaurant_slug = ?;", day, restaurantSlug];
    
    while ([categories next]) {
        NSString *category = [categories stringForColumn:@"category"];

        FMResultSet *recipeListForCategory = [_fmdb executeQuery:@"SELECT name, price, slug FROM dayMenu WHERE day = ? AND restaurant_slug = ? AND category = ?;", day, restaurantSlug, category];
        NSLog(@"DEBUG: %@ %@ %d", [_fmdb lastErrorMessage], [_fmdb lastError], [_fmdb lastErrorCode]);
        NSMutableArray *recipesForCategory = [[NSMutableArray alloc]init];
        
        while ([recipeListForCategory next]) {
            RecipeInfo *recipe = [RecipeInfo new];
            
            recipe.slug = [recipeListForCategory stringForColumn:@"slug"];
            recipe.name = [recipeListForCategory stringForColumn:@"name"];
            recipe.price = [NSNumber numberWithDouble:[recipeListForCategory doubleForColumn:@"price"]];
            recipe.category = category;
            
            [recipesForCategory addObject:recipe];
        }
        
        [retval setObject:recipesForCategory forKey:category];
    }
    
    return retval;
}

#pragma mark - Utils

-(BOOL)isTodayDayMenuAvailableForRestaurant:(NSString *)restaurantSlug
{
    NSDate *today = [NSDate date];
    
    NSString *stringDate = [self dateInYearMonthDayFormatFromDate:today];
    
    FMResultSet *result = [_fmdb executeQuery:@"SELECT * FROM dayMenu WHERE restaurant_slug = ? AND day = ?;", restaurantSlug, stringDate];
    
    if ([result next]) {
        [result close];
        return YES;
    }
    else
    {
        [result close];
        return NO;
    }
}


/**
 Checks the input string to the current day.
 @param dateToCompare The NSString with date format to be compare.
 @return YES or NO
 */
-(BOOL)isTheSameDayAsToday:(NSString *)dateToCompare
{
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    
    NSDate *menuDate = [dateFormatter dateFromString:dateToCompare];
    
    NSString *today = [self dateInYearMonthDayFormatFromDate:[NSDate date]];
    NSString *dayOfMenu = [self dateInYearMonthDayFormatFromDate:menuDate];
    
    NSLog(@"Components date: %@ - DayMenu: %@", today, dayOfMenu);
    
    //Se la data è di oggi
    if ([today isEqualToString:dayOfMenu]) {
        return YES;
    }
    else
    {
        return NO;
    }
}

-(NSString *)dateInYearMonthDayFormatFromDate:(NSDate *)date
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    
    unsigned int flags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit;
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSDateComponents* components = [calendar components:flags fromDate:date];
    
    NSDate *today = [calendar dateFromComponents:components];
    
    NSString *stringDate = [dateFormatter stringFromDate:today];

    return stringDate;
}

/**
 Closes the database connection
 */
-(void)closeDatabaseConnection
{
    [_fmdb close];
}

/**
 Returns a date from a string
 @param date The date in format yyyy-MM-dd'T'HH:mm:ssz
 */
-(NSDate *)dateFromString:(NSString *)date
{
    if ([date isMemberOfClass:[NSNull class]] || [date isEqualToString:@""]) {
        return [NSDate date];
    }
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssz"];
    return [dateFormatter dateFromString:date];
}

/*Saves the PDF data for the restaurant*/
-(void)savePDFUuid:(NSString *)pdfUUID ofRestaurant:(NSString *)restaurant
{
    const char *dbPath = [_databasePath UTF8String];
    sqlite3_stmt *statement;
    if (sqlite3_open(dbPath, &_database) == SQLITE_OK) {
        NSString *query = [NSString stringWithFormat:@"INSERT INTO restaurant(id, pdfUUID, name) VALUES(1, \"%@\", \"ratana\")", pdfUUID];
        const char *forged = [query UTF8String];
        
        int response = sqlite3_prepare_v2(_database, forged, -1, &statement, NULL);
        
        NSLog(@"[SAVE PDF] Response insert inside DB: %d %s", response, sqlite3_errmsg(self.database));
        if (sqlite3_step(statement) == SQLITE_DONE) {
            NSLog(@"[Save PDF] Completed save");
        }
        else
        {
            NSLog(@"[Save PDF] Failed Insert into database");
        }
        sqlite3_finalize(statement);
        sqlite3_close(_database);
    }
    else
    {
        NSLog(@"[Save PDF] Failed Open Database");
        sqlite3_close(_database);
    }
}

-(NSString *)requestRestaurantNameForMajorBeacon:(NSNumber *)majorBeacon andMinorBeacon:(NSNumber *)minorBeacon
{
    NSString *retval = @"";
    
    FMResultSet *result = [_fmdb executeQuery:@"SELECT name FROM restaurant WHERE majorBeacon = ? AND minorBeacon = ?;", majorBeacon, minorBeacon];
    
    if ([result next]) {
        retval = [result stringForColumn:@"name"];
    }
    
    return retval;
}

#pragma mark Delete data from menu
-(void)deleteDataFromRestaurant:(NSString *)restaurantSlug
{
    
    [self checkForeignKeys];
    
    if ([_fmdb executeUpdate:@"DELETE FROM restaurant WHERE slug = ?;", restaurantSlug])
    {
        NSLog(@"Deleted successfully from db the restaurant and data with slug %@", restaurantSlug);
    }
    else
    {
        NSLog(@"Errors while deleting restaurant");
    }
}

@end