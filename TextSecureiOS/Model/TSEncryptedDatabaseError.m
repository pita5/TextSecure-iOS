//
//  TSEncryptedDatabaseError.m
//  TextSecureiOS
//
//  Created by Alban Diquet on 11/29/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "TSEncryptedDatabaseError.h"


NSString * const TSEncryptedDatabaseErrorDomain = @"org.whispersystems.whisper.textsecure.TSEncryptedDatabaseErrorDomain";


@implementation TSEncryptedDatabaseError

+ (NSError *)errorWithErrorCode:(NSInteger)errorCode userInfo:(NSDictionary *)userInfo {
    return [NSError errorWithDomain:[self domain] code:errorCode userInfo:userInfo];
}


+ (NSString *)domain
{
    return TSEncryptedDatabaseErrorDomain;
}


+ (NSError *)dbAlreadyExists {
    NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
    [errorDetail setValue:@"A textsecure database already exists on this device" forKey:NSLocalizedDescriptionKey];
    return [self errorWithErrorCode:DbAlreadyExists userInfo:errorDetail];
}


+ (NSError *)noDbAvailable {
    NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
    [errorDetail setValue:@"No textsecure database was found on this device" forKey:NSLocalizedDescriptionKey];
    return [self errorWithErrorCode:NoDbAvailable userInfo:errorDetail];
}


+ (NSError *)dbWasCorrupted {
    NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
    [errorDetail setValue:@"The textsecure database was corrupted and cannot be opened" forKey:NSLocalizedDescriptionKey];
    return [self errorWithErrorCode:DbWasCorrupted userInfo:errorDetail];
}


+ (NSError *)dbCreationFailed {
    NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
    [errorDetail setValue:@"Could not create a textsecure database on this device" forKey:NSLocalizedDescriptionKey];
    return [self errorWithErrorCode:DbCreationFailed userInfo:errorDetail];
}

+ (NSError *)errorInvalidPassword {
    NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
    [errorDetail setValue:@"Could not unlock the storage master key because the supplied password was wrong" forKey:NSLocalizedDescriptionKey];
    return [self errorWithErrorCode:TSStorageErrorInvalidPassword userInfo:errorDetail];
}

+ (NSError *)errorMasterKeyLocked {
    NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
    [errorDetail setValue:@"The storage key is locked and needs to be unlocked with the user's password" forKey:NSLocalizedDescriptionKey];
    return [self errorWithErrorCode:TSStorageErrorMasterKeyLocked userInfo:errorDetail];
}

+ (NSError *)errorMasterKeyCorrupted {
    NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
    [errorDetail setValue:@"Could not recover the storage master key from the Keychain" forKey:NSLocalizedDescriptionKey];
    return [self errorWithErrorCode:TSStorageErrorMasterKeyCorrupted userInfo:errorDetail];
}

+ (NSError *)errorMasterKeyAlreadyCreated {
    NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
    [errorDetail setValue:@"A storage master key has already been created" forKey:NSLocalizedDescriptionKey];
    return [self errorWithErrorCode:TSStorageErrorMasterKeyAlreadyCreated userInfo:errorDetail];
}

+ (NSError *)errorMasterKeyCreationFailed {
    NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
    [errorDetail setValue:@"Could not generate the storage master key" forKey:NSLocalizedDescriptionKey];
    return [self errorWithErrorCode:TSStorageErrorMasterKeyCreationFailed userInfo:errorDetail];
}

+ (NSError *)errorMasterKeyNotCreated {
    NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
    [errorDetail setValue:@"No storage master key has been created" forKey:NSLocalizedDescriptionKey];
    return [self errorWithErrorCode:TSStorageErrorMasterKeyNotCreated userInfo:errorDetail];
}

@end
