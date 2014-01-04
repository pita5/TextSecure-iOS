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
    Undefined = 0,
    DbAlreadyExists,
    DbCreationFailed,
    NoDbAvailable,
    DbWasCorrupted,
    TSStorageErrorInvalidPassword,
    TSStorageErrorMasterKeyLocked,
    TSStorageErrorStorageKeyCorrupted,
    TSStorageErrorStorageKeyAlreadyCreated,
    TSStorageErrorStorageKeyCreationFailed,
    TSStorageErrorStorageKeyNotCreated
} TSEncryptedDatabaseErrorCode;


// TODO: change this to TSStorageError
@interface TSEncryptedDatabaseError : NSObject

+ (NSString *)domain;
//+ (NSError *)dbAlreadyExists;
//+ (NSError *)dbCreationFailed;
//+ (NSError *)noDbAvailable;
//+ (NSError *)dbWasCorrupted;
+ (NSError *)errorInvalidPassword;
+ (NSError *)errorStorageKeyLocked;
+ (NSError *)errorStorageKeyCorrupted;
+ (NSError *)errorStorageKeyAlreadyCreated;
+ (NSError *)errorStorageKeyCreationFailed;
+ (NSError *)errorStorageKeyNotCreated;

@end

