//
//  TSStorageMasterKey.m
//  TextSecureiOS
//
//  Created by Alban Diquet on 12/29/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "TSStorageMasterKey.h"
#import "Cryptography.h"
#import "RNEncryptor.h"
#import "RNDecryptor.h"
#import "KeychainWrapper.h"
#import "NSData+Base64.h"


#define kStorageMasterKeyWasCreated @"StorageMasterKeyWasCreated"
#define MASTER_KEY_SIZE 32


static uint8_t storageMasterKey[MASTER_KEY_SIZE] = {0};
static BOOL isMasterKeyLocked = TRUE;


@implementation TSStorageMasterKey


+(NSData*) createStorageMasterKeyWithPassword:(NSString *)userPassword {
    NSData *masterKey = [Cryptography generateRandomBytes:36];
    NSData *encryptedMasterKey = [RNEncryptor encryptData:masterKey withSettings:kRNCryptorAES256Settings password:userPassword error:nil];
    if(!encryptedMasterKey) {
        // TODO: Better error handling
        return nil;
    }
    
    if (![KeychainWrapper createKeychainValue:[encryptedMasterKey base64EncodedString] forIdentifier:encryptedMasterSecretKeyStorageId]) {
        // TODO: Better error handling
        return nil;
    }
    
    
    isMasterKeyLocked = FALSE;
    memcpy(storageMasterKey, [masterKey bytes], MASTER_KEY_SIZE);
    
    // Update user preferences
    [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:kStorageMasterKeyWasCreated];
    
    return [NSData dataWithBytesNoCopy:storageMasterKey length:MASTER_KEY_SIZE];
}


+(NSData*) unlockStorageMasterKeyUsingPassword:(NSString *)userPassword error:(NSError **)error {
    NSString *encryptedStorageMasterKey = [KeychainWrapper keychainStringFromMatchingIdentifier:encryptedMasterSecretKeyStorageId];
    if (!encryptedStorageMasterKey) {
        if (error) {
            // TODO: Add error
            //*error = [TSEncryptedDatabaseError dbWasCorrupted];
        }
        return nil;
    }
    
    NSData *masterKey = [RNDecryptor decryptData:[NSData dataFromBase64String:encryptedStorageMasterKey] withPassword:userPassword error:error];
    if ((!masterKey) && (error) && ([*error domain] == kRNCryptorErrorDomain) && ([*error code] == kRNCryptorHMACMismatch)) {
        // Wrong password; clarify the error returned
        // TODO
        //*error = [TSEncryptedDatabaseError invalidPassword];
        return nil;
    }
    
    isMasterKeyLocked = FALSE;
    memcpy(storageMasterKey, [masterKey bytes], MASTER_KEY_SIZE);
    return [NSData dataWithBytesNoCopy:storageMasterKey length:MASTER_KEY_SIZE];
}


+(NSData*) getStorageMasterKeyWithError:(NSError **)error {
    // TODO: wasCreated
    
    if (isMasterKeyLocked) {
        // TODO error
        return nil;
    }
    
    return [NSData dataWithBytesNoCopy:storageMasterKey length:MASTER_KEY_SIZE];
}


+(void) lockStorageMasterKey {
    // Best-effort "secure" erase; may be overkill and may not work at all
    isMasterKeyLocked = TRUE;
    
    // TODO: See if this actually works the way I think it works
    memset(storageMasterKey, 0, MASTER_KEY_SIZE);
}


+(BOOL) isStorageMasterKeyLocked {
    return isMasterKeyLocked;
}


+(void) eraseStorageMasterKey {
    [[NSUserDefaults standardUserDefaults] setBool:FALSE forKey:kStorageMasterKeyWasCreated];
    isMasterKeyLocked = TRUE;
    memset(storageMasterKey, 0, MASTER_KEY_SIZE);
    [KeychainWrapper deleteItemFromKeychainWithIdentifier:encryptedMasterSecretKeyStorageId];
}
    
    
@end
