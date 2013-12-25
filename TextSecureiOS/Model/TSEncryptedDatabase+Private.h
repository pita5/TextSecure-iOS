//
//  TSEncryptedDatabase+Private.h
//  TextSecureiOS
//
//  Created by Alban Diquet on 11/26/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "TSEncryptedDatabase.h"


// Internal constants exposed for unit testing
#define kDBWasCreatedBool @"DBWasCreated"
#define databaseFileName @"cryptography.db"


@interface TSEncryptedDatabase(Private)

-(instancetype) initWithDatabaseQueue:(FMDatabaseQueue *)queue;

<<<<<<< HEAD
#pragma mark - DB creation helper functions
-(BOOL) generatePersonalPrekeys;
-(BOOL) generateIdentityKey;

#pragma mark - DB master key functions
+(NSData*) generateDatabaseMasterKeyWithPassword:(NSString *)userPassword;
+(NSData*) getDatabaseMasterKeyWithPassword:(NSString *)userPassword error:(NSError **)error;
+(void) eraseDatabaseMasterKey;

=======

>>>>>>> 6de8c85ebe36d78587114bb41810fdaddcb10da3


@end
