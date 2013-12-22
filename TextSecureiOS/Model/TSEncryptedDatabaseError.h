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
    InvalidPassword,
} TSEncryptedDatabaseErrorCode;


@interface TSEncryptedDatabaseError : NSObject

+ (NSString *)domain;
+ (NSError *)dbAlreadyExists;
+ (NSError *)dbCreationFailed;
+ (NSError *)noDbAvailable;
+ (NSError *)dbWasCorrupted;
+ (NSError *)invalidPassword;

@end

