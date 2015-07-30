//
//  TSContactManager.m
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 10/12/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "TSContactManager.h"
#import <NBPhoneNumberUtil.h>
#import <NBPhoneNumber.h>
#import <AddressBook/AddressBook.h>
#import "NSString+Conversion.h"
#import "Cryptography.h"
#import "TSNetworkManager.h"
#import "TSContactsIntersectionRequest.h"

@interface TSContactManager ()
@property NSDictionary *cachedContactLookup;
@end

@implementation TSContactManager

+ (id)sharedManager {
    static TSContactManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    
    return sharedMyManager;
}

- (id)init {
    if (self = [super init]) {
        
    }
    return self;
}

/**
 *  Returns a given phone number in international E.123 format but without any white-spaces
 *
 *  @param number phone number to convert to E.123
 */

+ (NSString*) cleanPhoneNumber:(NSString*)number{
    NBPhoneNumberUtil *phoneUtil = [NBPhoneNumberUtil sharedInstance];

    NBPhoneNumber *phone = [phoneUtil parse:number defaultRegion:[[NSLocale currentLocale]objectForKey:NSLocaleCountryCode] error:nil];
    return [NSString stringWithFormat:@"+%@%@", phone.countryCode,phone.nationalNumber];
}

- (NSNumber*) getContactIDForNumber:(NSString*) phoneNumber{
    
    if (!self.cachedContactLookup) {
        [self makeContactLookupTable];
    }
    
    return [self.cachedContactLookup objectForKey:[[self class]cleanPhoneNumber:phoneNumber]];
}

- (void)makeContactLookupTable{
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, nil);
    NSMutableDictionary *ab = [NSMutableDictionary dictionary];
    __block BOOL accessGranted = NO;
    
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    
    ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
        accessGranted = granted;
        dispatch_semaphore_signal(sema);
    });
    
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    
    if (accessGranted) {
        CFArrayRef all = ABAddressBookCopyArrayOfAllPeople(addressBook);
        CFIndex n = ABAddressBookGetPersonCount(addressBook);
        
        for( int i = 0 ; i < n ; i++ )
        {
            ABRecordRef ref = CFArrayGetValueAtIndex(all, i);
            int referenceID = ABRecordGetRecordID(ref);
            NSNumber *contactReferenceID = [NSNumber numberWithInt:referenceID];
            // We iterate through users
            
            ABMultiValueRef phones = ABRecordCopyValue(ref, kABPersonPhoneProperty);
            for(CFIndex j = 0; j < ABMultiValueGetCount(phones); j++)
            {
                NSString *phoneNumber = (__bridge_transfer NSString *)ABMultiValueCopyValueAtIndex(phones, j);
                
                NSString *cleanedNumber = [[self class] cleanPhoneNumber:phoneNumber];
                
                [ab setObject:contactReferenceID forKey:cleanedNumber];
            }
            CFRelease(phones);
        }
        CFRelease(all);
    }
    CFRelease(addressBook);
    
    self.cachedContactLookup = ab;
}

+ (void) getAllContactsIDs:(void (^)(NSArray *contacts))contactFetchCompletionBlock {
    
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, nil);
    __block BOOL accessGranted = NO;
    
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
        accessGranted = granted;
        dispatch_semaphore_signal(sema);
    });
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    
    if (accessGranted == NO) {
        CFRelease(addressBook);
        return;
    }
    
    CFArrayRef all = ABAddressBookCopyArrayOfAllPeople(addressBook);
    CFIndex n = ABAddressBookGetPersonCount(addressBook);
    NSMutableDictionary *abIdLookup = [NSMutableDictionary dictionary];
    NSMutableDictionary *phoneNumberLookup = [NSMutableDictionary dictionary];
    
    for( int i = 0 ; i < n ; i++ )
    {
        ABRecordRef ref = CFArrayGetValueAtIndex(all, i);
        int referenceID = ABRecordGetRecordID(ref);
        NSNumber *contactReferenceID = [NSNumber numberWithInt:referenceID];
        // We iterate through users
        
        ABMultiValueRef phones = ABRecordCopyValue(ref, kABPersonPhoneProperty);
        for(CFIndex j = 0; j < ABMultiValueGetCount(phones); j++)
        {
            NSString *phoneNumber = (__bridge_transfer NSString *)ABMultiValueCopyValueAtIndex(phones, j);
            NSString *cleanedNumber = [self cleanPhoneNumber:phoneNumber];
            NSString *hashedPhoneNumber = [Cryptography truncatedSHA1Base64EncodedWithoutPadding:cleanedNumber];
            
            // Not showing the user himself in the buddy list.
            
            if (![cleanedNumber isEqualToString:[TSKeyManager getUsernameToken]]) {
                [abIdLookup setObject:contactReferenceID forKey:hashedPhoneNumber];
                [phoneNumberLookup setObject:cleanedNumber forKey:hashedPhoneNumber];
            }
        }
        
        CFRelease(phones);
    }
    
    // Send hashes to server
    [[TSNetworkManager sharedManager]queueAuthenticatedRequest:[[TSContactsIntersectionRequest alloc] initWithHashesArray:[abIdLookup allKeys]] success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSArray *contactsHashes = [responseObject objectForKey:@"contacts"];
        
        NSMutableArray *contacts = [NSMutableArray array];
        for (NSDictionary *contactHash in contactsHashes) {
            
            TSContact *contact = [[TSContact alloc]initWithRegisteredID:[phoneNumberLookup objectForKey:[contactHash objectForKey:@"token"]] relay:[phoneNumberLookup objectForKey:[contactHash objectForKey:@"relay"]] addressBookID:[abIdLookup objectForKey:[contactHash objectForKey:@"token"]]];
            
            [contacts addObject:contact];
        }
        
        contactFetchCompletionBlock(contacts);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        defaultNetworkErrorMessage
        
    }];
    
    CFRelease(all);
    CFRelease(addressBook);
}

- (void)dealloc {
    // Should never be called, but just here for clarity really.
}

@end
