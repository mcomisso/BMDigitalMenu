//
//  RecipeInfo.h
//  BMSdk
//
//  Created by Matteo Comisso on 13/08/14.
//  Copyright (c) 2014 Blue-Mate. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RecipeInfo : NSObject

@property NSString *categoria;
@property NSNumber *prezzo;
@property NSNumber *visualizzabile;
@property NSString *nome;
@property NSString *immagine;
@property NSDate *dataCreazione;
@property NSString *descrizione;
@property NSNumber *localeId;
@property NSArray *ingredienti;

@end
