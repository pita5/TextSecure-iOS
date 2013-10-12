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
#import "Cryptography.h"
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

+ (NSArray*) getAllContacts{
    
    // Lookup contacts
    
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, nil);
    
    __block BOOL accessGranted = NO;
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
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
        
        for( int i = 0 ; i < n ; i++ )
        {
            ABRecordRef ref = CFArrayGetValueAtIndex(all, i);
            int referenceID = ABRecordGetRecordID(ref);
            NSNumber *contactReferenceID = [NSNumber numberWithInt:referenceID];
            // We iterate through users
            
            NSMutableArray *userPhoneNumbers = [NSMutableArray array];
            
            ABMultiValueRef phones = ABRecordCopyValue(ref, kABPersonPhoneProperty);
            for(CFIndex j = 0; j < ABMultiValueGetCount(phones); j++)
            {
                CFStringRef phoneNumberRef = ABMultiValueCopyValueAtIndex(phones, j);
                NSString *phoneNumber = (__bridge NSString *)phoneNumberRef;
                
                [userPhoneNumbers addObject:phoneNumber];
        
            }
            
            [dict setObject:[NSArray arrayWithArray:userPhoneNumbers] forKey:contactReferenceID];
        }
        
        // Let's now bring them in standard format
        NBPhoneNumberUtil *phoneUtil = [NBPhoneNumberUtil sharedInstance];
        
        NSMutableDictionary *cleanedAB = [NSMutableDictionary dictionary];
        
        NSArray *keys = [dict allKeys];
        
        for (int i = 0; i < [keys count]; i ++) {
            NSMutableArray *cleanedPhoneNumbers = [NSMutableArray array];
            NSMutableArray *personPhoneNumbers = [dict objectForKey:[keys objectAtIndex:i]];
            
            for (int j = 0; j < [personPhoneNumbers count]; j++) {
                NBPhoneNumber *phone = [phoneUtil parse:[personPhoneNumbers objectAtIndex:j] defaultRegion:[[NSLocale currentLocale]objectForKey:NSLocaleCountryCode] error:nil];
                NSString *phoneNumber = [NSString stringWithFormat:@"+%i%llu", (unsigned)phone.countryCode, phone.nationalNumber];
                NSString *hashedPhoneNumber = [Cryptography computeSHA1DigestForString:phoneNumber];
                [cleanedPhoneNumbers addObject:hashedPhoneNumber];
            }
            
            if ([cleanedPhoneNumbers count] > 0) {
                [cleanedAB setObject:[NSArray arrayWithArray:cleanedPhoneNumbers] forKey:[keys objectAtIndex:i]];
            }
            
        }
        
        NSMutableArray *hashes = [NSMutableArray array];
        
        for (int i = 0; i < [[cleanedAB allValues] count]; i++) {
            for (int j = 0; j < [[[cleanedAB allValues] objectAtIndex:i] count]; j++) {
                [hashes addObject:[[[cleanedAB allValues] objectAtIndex:i] objectAtIndex:j]];
            }
        }
        
        // Send hashes to server
        
        [[TSNetworkManager sharedManager] queueAuthenticatedRequest:[[TSContactsIntersectionRequest alloc] initWithHashesArray:hashes] success:^(AFHTTPRequestOperation *operation, id responseObject) {
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            
        }];
        
        // Lookup the names
        
        
        
        
        return nil;
    } else{
        return nil;
    }
    
}

- (void)dealloc {
    // Should never be called, but just here for clarity really.
}

@end
