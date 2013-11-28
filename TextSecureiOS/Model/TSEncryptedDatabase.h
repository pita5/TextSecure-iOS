//
//  TSEncryptedDatabase.h
//  TextSecureiOS
//
//  Created by Alban Diquet on 11/25/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ECKeyPair;
@class FMDatabaseQueue;

@interface TSEncryptedDatabase : NSObject


/**
 * Create a new TextSecure database.
 * @author Alban Diquet
 *
 * @param userPassword Password to be used to encrypt the database.
 * @param error A pointer to an error object.
 * @return A reference to the newly created database or nil if an error occurred.
 */
+(instancetype) databaseCreateWithPassword:(NSString *)userPassword error:(NSError **)error;


/**
 * Open and unlock/decrypt the existing TextSecure database.
 * @author Alban Diquet
 *
 * @param userPassword Password to unlock the database.
 * @param error A pointer to an error object.
 * @return A reference to the unlocked database or nil if an error occurred.
 */
+(instancetype) databaseUnlockWithPassword:(NSString *)userPassword error:(NSError **)error;


/**
 * Get a reference to the previously opened TextSecure database; the database might be locked (ie. password-protected).
 * @author Alban Diquet
 *
 * @return A reference to the database or nil if no database was previously created or opened.
 */
+(instancetype) database;


/**
 * Lock the TextSecure database, requiring a call to databaseUnlockWithPassword:error to unlock it. Any code with a reference to the database that tries to access its content while locked will trigger exceptions. TODO: Automatically prompt the user for their password instead.
 * @author Alban Diquet
 *
 */
+(void) databaseLock;  // TODO: Use this to lock (ie. pw-protect) the DB after X minutes


/**
 * Erase the TextSecure database and the corresponding keys. Any code with a reference to the database that tries to access its content after it was erased will instantly crash the app.
 * @author Alban Diquet
 *
 */
+(void) databaseErase;


/**
 * Check if the TextSecure database has already been created on the device.
 * @author Alban Diquet
 *
 * @return YES if a TextSecure database is available.
 */
+(BOOL) databaseWasCreated;


/**
 * Check if the TextSecure database is locked (password-protected).
 * @author Alban Diquet
 *
 * @return YES if the TextSecure database is locked.
 */
-(BOOL) isLocked;


/**
 * Get the identity key stored in the database. Will trigger exceptions if the database is locked. TODO: Automatically prompt the user for their password instead.
 * @author Alban Diquet
 *
 * @return The identity key.
 */
-(ECKeyPair*) getIdentityKey;


/**
 * Get the pre keys stored in the database. Will trigger exceptions if the database is locked. TODO: Automatically prompt the user for their password instead.
 * @author Alban Diquet
 *
 * @return An array of pre-keys.
 */
-(NSArray*) getPersonalPrekeys;

@end

