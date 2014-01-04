//
//  TSStorageError.m
//  TextSecureiOS
//
//  Created by Alban Diquet on 11/29/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "TSStorageError.h"


NSString * const TSStorageErrorDomain = @"org.whispersystems.whisper.textsecure.TSStorageErrorDomain";


@implementation TSStorageError

+ (NSError *)errorWithErrorCode:(NSInteger)errorCode userInfo:(NSDictionary *)userInfo {
    return [NSError errorWithDomain:[self domain] code:errorCode userInfo:userInfo];
}


+ (NSString *)domain
{
    return TSStorageErrorDomain;
}


+ (NSError *)errorDatabaseAlreadyCreated {
    NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
    [errorDetail setValue:@"The database was already created" forKey:NSLocalizedDescriptionKey];
    return [self errorWithErrorCode:TSStorageErrorDatabaseAlreadyCreated userInfo:errorDetail];
}


+ (NSError *)errorDatabaseNotCreated {
    NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
    [errorDetail setValue:@"The database could not be found" forKey:NSLocalizedDescriptionKey];
    return [self errorWithErrorCode:TSStorageErrorDatabaseNotCreated userInfo:errorDetail];
}


+ (NSError *)errorDatabaseCorrupted {
    NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
    [errorDetail setValue:@"The database was corrupted and could not be opened" forKey:NSLocalizedDescriptionKey];
    return [self errorWithErrorCode:TSStorageErrorDatabaseCorrupted userInfo:errorDetail];
}


+ (NSError *)errorDatabaseCreationFailed {
    NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
    [errorDetail setValue:@"The database could not be created" forKey:NSLocalizedDescriptionKey];
    return [self errorWithErrorCode:TSStorageErrorDatabaseCreationFailed userInfo:errorDetail];
}

+ (NSError *)errorInvalidPassword {
    NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
    [errorDetail setValue:@"Could not unlock the storage master key because the supplied password was wrong" forKey:NSLocalizedDescriptionKey];
    return [self errorWithErrorCode:TSStorageErrorInvalidPassword userInfo:errorDetail];
}

+ (NSError *)errorStorageKeyLocked {
    NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
    [errorDetail setValue:@"The storage key is locked and needs to be unlocked with the user's password" forKey:NSLocalizedDescriptionKey];
    return [self errorWithErrorCode:TSStorageErrorStorageKeyLocked userInfo:errorDetail];
}

+ (NSError *)errorStorageKeyCorrupted {
    NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
    [errorDetail setValue:@"Could not recover the storage master key from the Keychain" forKey:NSLocalizedDescriptionKey];
    return [self errorWithErrorCode:TSStorageErrorStorageKeyCorrupted userInfo:errorDetail];
}

+ (NSError *)errorStorageKeyAlreadyCreated {
    NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
    [errorDetail setValue:@"The storage master key has already been created" forKey:NSLocalizedDescriptionKey];
    return [self errorWithErrorCode:TSStorageErrorStorageKeyAlreadyCreated userInfo:errorDetail];
}

+ (NSError *)errorStorageKeyCreationFailed {
    NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
    [errorDetail setValue:@"Could not generate the storage master key" forKey:NSLocalizedDescriptionKey];
    return [self errorWithErrorCode:TSStorageErrorStorageKeyCreationFailed userInfo:errorDetail];
}

+ (NSError *)errorStorageKeyNotCreated {
    NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
    [errorDetail setValue:@"The storage master key has been created yet" forKey:NSLocalizedDescriptionKey];
    return [self errorWithErrorCode:TSStorageErrorStorageKeyNotCreated userInfo:errorDetail];
}

@end
