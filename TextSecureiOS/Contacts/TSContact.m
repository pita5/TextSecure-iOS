//
//  TSContact.m
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 10/20/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "TSContactManager.h"
#import <AddressBook/AddressBook.h>
#import "TSMessagesDatabase.h"

@interface TSContact ()
@property (copy) NSNumber *abID;
@end

@implementation TSContact

- (instancetype)contactWithRegisteredID:(NSString*)registeredID{
    return [self initWithRegisteredID:registeredID relay:nil];
}

-(instancetype) initWithRegisteredID:(NSString*)registeredID relay:(NSString*)relay{

    self = [super init];;
    
    if(self) {
        _registeredID = registeredID;
        _relay = relay;
    }
    return self;
}

-(instancetype) initWithRegisteredID:(NSString*)registeredID relay:(NSString*)relay addressBookID:(NSNumber *)abId{
    self = [self initWithRegisteredID:registeredID relay:relay];
    if (self) {
        _abID = abId;
    }
    return self;
}


- (NSNumber*) addressBookID{
    // Looking up a AddressBook Token might take time if user has a lot of contacts, let's cache it to avoid doing unecessary calls to the AdressBook.
    if (!self.abID) {
        self.abID = [[TSContactManager sharedManager]getContactIDForNumber:self.registeredID];
    }
    return self.abID;
}

- (NSString*) name{
    if ([self addressBookID]){
        ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(nil, nil);
        ABRecordRef currentPerson = ABAddressBookGetPersonWithRecordID(addressBook, [[self addressBookID] intValue]);
        NSString *firstName = (__bridge_transfer NSString *)ABRecordCopyValue(currentPerson, kABPersonFirstNameProperty) ;
        NSString *surname = (__bridge_transfer NSString *)ABRecordCopyValue(currentPerson, kABPersonLastNameProperty) ;
        CFRelease(addressBook);
        return [NSString stringWithFormat:@"%@ %@", firstName?firstName:@"", surname?surname:@""];
    }else{
        return [self registeredID];
    }
}

- (NSString*) labelForRegisteredNumber{
    if ([self addressBookID] && self.registeredID) {
        ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(nil, nil);
        ABRecordRef currentPerson = ABAddressBookGetPersonWithRecordID(addressBook, [[self addressBookID] intValue]);
        
        ABMutableMultiValueRef phoneNumbers = ABRecordCopyValue(currentPerson, kABPersonPhoneProperty);
        
        NSString *label = @"";
        
        for (CFIndex i = 0; i < ABMultiValueGetCount(phoneNumbers); i++)
        {
            CFStringRef phoneNumber, phoneNumberLabel;
            
            phoneNumberLabel = ABMultiValueCopyLabelAtIndex(phoneNumbers, i);
            phoneNumber      = ABMultiValueCopyValueAtIndex(phoneNumbers, i);
            
            NSString *number = (__bridge NSString*) phoneNumber;

            if ([[TSContactManager cleanPhoneNumber:number] isEqualToString:self.registeredID]) {
                
                CFStringRef raw_label = ABMultiValueCopyLabelAtIndex(phoneNumbers, i);
                label = (__bridge_transfer NSString *)(ABAddressBookCopyLocalizedLabel(raw_label));
                CFRelease(raw_label);
                CFRelease(phoneNumberLabel);
                CFRelease(phoneNumber);
                break;
            }
            CFRelease(phoneNumberLabel);
            CFRelease(phoneNumber);
        }
        
        CFRelease(phoneNumbers);
        CFRelease(addressBook);
        
        return label;
        
    } else {
        return @"";
    }
}

-(void) reverseIsSelected {
    self.isSelected = !self.isSelected;
}
-(void) save{
    [TSMessagesDatabase storeContact:self];
}

@end
