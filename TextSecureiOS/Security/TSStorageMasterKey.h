//
//  TSStorageMasterKey.h
//  TextSecureiOS
//
//  Created by Alban Diquet on 12/29/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
#define kStorageMasterKeyWasCreated @"StorageMasterKeyWasCreated"
#define MASTER_KEY_SIZE 32

@interface TSStorageMasterKey : NSObject


#pragma mark Storage master key generation
/**
 * Create a storage master key on the device which will be used to encrypted the TextSecure databases.
 * @author Alban Diquet
 *
 * @param userPassword The password from which the master key should be derived.
 * @param error.
 * @return The newly generated storage master key or nil of an error occured.
 */
+(NSData*) createStorageMasterKeyWithPassword:(NSString *)userPassword error:(NSError **) error;

/**
 * Check if the storage master key has already been generated on the device.
 * @author Alban Diquet
 *
 * @return TRUE if key has already been generated on the device.
 */
+(BOOL) wasStorageMasterKeyCreated;


#pragma mark Storage master key access
/**
 * Unlock the storage master key.
 * @author Alban Diquet
 *
 * @param userPassword The password from which the master key was derived on creation.
 * @param error.
 * @return The storage master key or nil of an error occured.
 */
+(NSData*) unlockStorageMasterKeyUsingPassword:(NSString *)userPassword error:(NSError **)error;

/**
 * Get the previously unlocked storage master key.
 * @author Alban Diquet
 *
 * @param error.
 * @return The storage master key or nil of an error occured (such as the master key being locked).
 */
+(NSData*) getStorageMasterKeyWithError:(NSError **)error;

/**
 * Change the password of the storage master key.
 * @author Christoph Schenkel
 *
 * @param oldPassword Current master key password
 * @param newPassword New master key password
 */
+(void) changeStorageMasterKeyPasswordFrom:(NSString*)oldPassword to:(NSString*)newPassword error:(NSError **)error;

/**
 * Change the password of the storage master key without providing the current password. Storage master key need to be unlocked.
 * @author Christoph Schenkel
 *
 * @param newPassword New master key password
 */
+(void) changeStorageMasterKeyPasswordTo:(NSString*)newPassword error:(NSError **)error;

#pragma mark Storage master key locking
/**
 * Lock the storage master key, thereby requiring a call to unlockStorageMasterKeyUsingPassword:error before the key can be recovered.
 * @author Alban Diquet
 */
+(void) lockStorageMasterKey;


/**
 * Check if the storage master key is currently in a "locked" state.
 * @author Alban Diquet
 *
 * @return TRUE if key is locked.
 */
+(BOOL) isStorageMasterKeyLocked;


#pragma mark Storage master key deletion
/**
 * Erase the storage master key from the device.
 * @author Alban Diquet
 */
+(void) eraseStorageMasterKey;


@end
