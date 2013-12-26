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
#import "TSContact.h"
#import "TSNetworkManager.h"
#import "TSContactsIntersectionRequest.h"

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

+ (void) getAllContactsIDs:(void (^)(NSArray *contacts))contactFetchCompletionBlock{
    
    // Lookup contacts
    
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, nil);
    
    __block BOOL accessGranted = NO;

    if (ABAddressBookRequestAccessWithCompletion != NULL) { // we're on iOS 6
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
            accessGranted = granted;
            dispatch_semaphore_signal(sema);
        });
        
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    }
    else { // we're on iOS 5 or older
        accessGranted = YES;
    }
    
    
    if (accessGranted) {
        CFArrayRef all = ABAddressBookCopyArrayOfAllPeople(addressBook);
        CFIndex n = ABAddressBookGetPersonCount(addressBook);
        NBPhoneNumberUtil *phoneUtil = [NBPhoneNumberUtil sharedInstance];
        NSMutableDictionary *hashedAB = [NSMutableDictionary dictionary];
        NSMutableDictionary *originalAB = [NSMutableDictionary dictionary];
        
        for( int i = 0 ; i < n ; i++ )
        {
            ABRecordRef ref = CFArrayGetValueAtIndex(all, i);
            int referenceID = ABRecordGetRecordID(ref);
            NSNumber *contactReferenceID = [NSNumber numberWithInt:referenceID];
            // We iterate through users
            
            ABMultiValueRef phones = ABRecordCopyValue(ref, kABPersonPhoneProperty);
            for(CFIndex j = 0; j < ABMultiValueGetCount(phones); j++)
            {
                CFStringRef phoneNumberRef = ABMultiValueCopyValueAtIndex(phones, j);
                NSString *phoneNumber = (__bridge NSString *)phoneNumberRef;
                
                NBPhoneNumber *phone = [phoneUtil parse:phoneNumber defaultRegion:[[NSLocale currentLocale]objectForKey:NSLocaleCountryCode] error:nil];
                NSString *cleanedNumber = [NSString stringWithFormat:@"+%i%llu", (unsigned)phone.countryCode, phone.nationalNumber];
                NSString *hashedPhoneNumber = [Cryptography truncatedSHA1Base64EncodedWithoutPadding:cleanedNumber];
                
                [hashedAB setObject:hashedPhoneNumber forKey:contactReferenceID];
                [originalAB setObject:cleanedNumber forKey:hashedPhoneNumber];
            }
        }

        // Send hashes to server
        
        [[TSNetworkManager sharedManager]queueAuthenticatedRequest:[[TSContactsIntersectionRequest alloc] initWithHashesArray:[hashedAB allValues]] success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSArray *contactsHashes = [responseObject objectForKey:@"contacts"];

            NSMutableArray *contacts = [NSMutableArray array];
            for (NSDictionary *contactHash in contactsHashes) {
                TSContact *contact = [[TSContact alloc]init];
                // The case where a phone number would be in two contacts sheets is not managed properly yet.
                contact.userABID = [[hashedAB allKeysForObject:[contactHash objectForKey:@"token"]] objectAtIndex:0];
                contact.registeredID = [originalAB objectForKey:[contactHash objectForKey:@"token"]];
                [contacts addObject:contact];
            }
            
            contactFetchCompletionBlock(contacts);
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            
            defaultNetworkErrorMessage
            
        }];
        
    }
}

- (void)dealloc {
    // Should never be called, but just here for clarity really.
}

@end
