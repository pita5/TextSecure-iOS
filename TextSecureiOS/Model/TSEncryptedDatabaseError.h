//
//  TSEncryptedDatabaseError.h
//  TextSecureiOS
//
//  Created by Alban Diquet on 11/29/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const TSEncryptedDatabaseErrorDomain;

typedef enum TSEncryptedDatabaseErrorCode {
    TSStorageErrorDatabaseAlreadyCreated,
    TSStorageErrorDatabaseCreationFailed,
    TSStorageErrorDatabaseNotCreated,
    TSStorageErrorDatabaseCorrupted,
    TSStorageErrorInvalidPassword,
    TSStorageErrorStorageKeyLocked,
    TSStorageErrorStorageKeyCorrupted,
    TSStorageErrorStorageKeyAlreadyCreated,
    TSStorageErrorStorageKeyCreationFailed,
    TSStorageErrorStorageKeyNotCreated
} TSEncryptedDatabaseErrorCode;


// TODO: change this to TSStorageError
@interface TSEncryptedDatabaseError : NSObject

+ (NSString *)domain;
+ (NSError *)errorDatabaseAlreadyCreated;
+ (NSError *)errorDatabaseCreationFailed;
+ (NSError *)errorDatabaseNotCreated;
+ (NSError *)errorDatabaseCorrupted;
+ (NSError *)errorInvalidPassword;
+ (NSError *)errorStorageKeyLocked;
+ (NSError *)errorStorageKeyCorrupted;
+ (NSError *)errorStorageKeyAlreadyCreated;
+ (NSError *)errorStorageKeyCreationFailed;
+ (NSError *)errorStorageKeyNotCreated;

@end

