//
//  TSDatabaseManager.h
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 01/03/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>


@class FMDatabaseQueue;


@interface TSDatabaseManager : NSObject
// TODO: Use notifications to set dbQueue to nil when [TSStorageMasterKey lockStorageMasterKey] gets called
// This would close opened DB handles when we lock the key
@property (nonatomic, retain) FMDatabaseQueue *dbQueue;


/**
 * Calls  databaseCreateAtFilePath:(NSString *)dbFilePath updateBoolPreference:(NSString *)preferenceName withPassword:(NSData*)dbMasterKey error:(NSError **)error
 * with the password: [TSStorageMasterKey getStorageMasterKeyWithError:error]
 */
+(instancetype) databaseCreateAtFilePath:(NSString *)dbFilePath updateBoolPreference:(NSString *)preferenceName error:(NSError **)error;


/**
 * Create an encrypted database and update the corresponding preference.
 * @author Alban Diquet
 *
 * @param dbFilePath The file path where the database should be created.
 * @param preferenceName A BOOL preference that should be set to TRUE upon successful creation of the database.
 * @param the password for the encrypted database. Must not be nil, otherwise return will be nil
 * @param error.
 * @return The newly-created database or nil if an error occured.
 */
+(instancetype) databaseCreateAtFilePath:(NSString *)dbFilePath updateBoolPreference:(NSString *)preferenceName withPassword:(NSData*)dbKey error:(NSError **)error;



/**
 * Calls +(instancetype) databaseOpenAndDecryptAtFilePath:(NSString *)dbFilePath withPassword:(NSData*)dbKey error:(NSError **)error;
 * with the password [TSStorageMasterKey getStorageMasterKeyWithError:error]
 */
+(instancetype) databaseOpenAndDecryptAtFilePath:(NSString *)dbFilePath error:(NSError **)error;


/**
 * Open and decrypt a database.
 * @author Alban Diquet
 *
 * @param dbFilePath The file path to the database.
 * @param the password for the encrypted database. Must not be nil, otherwise return will be nil
 * @param error.
 * @return The database or nil if an error occured.
 */
+(instancetype) databaseOpenAndDecryptAtFilePath:(NSString *)dbFilePath withPassword:(NSData*)dbKey error:(NSError **)error;


/**
 * Erase an encrypted database and update the corresponding preference.
 * @author Alban Diquet
 *
 * @param dbFilePath The file path to the database.
 * @param preferenceName A BOOL preference that should be set to FALSE upon deletion of the database.
 */
+(void) databaseEraseAtFilePath:(NSString *)dbFilePath updateBoolPreference:(NSString *)preferenceName;

@end
