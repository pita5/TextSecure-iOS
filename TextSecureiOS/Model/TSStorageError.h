//
//  TSStorageError.h
//  TextSecureiOS
//
//  Created by Alban Diquet on 11/29/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const TSStorageErrorDomain;

typedef enum TSStorageErrorCode {
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
} TSStorageErrorCode;


// TODO: change this to TSStorageError
@interface TSStorageError : NSObject

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

