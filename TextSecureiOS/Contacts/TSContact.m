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

@implementation TSContact

-(id) initWithRegisteredID:(NSString*)registeredID {
#warning added this to use the compute thread ids methods as is, but awkward as there are some db calls that assume TSContact has more fields (see header) that will crash with a TSContact initialized in this manner.
    
    if(self=[super init]) {
        self.registeredID = registeredID;
    }
    return self;
    
}
- (NSString*) name{
    if (self.userABID){
        
        ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(nil, nil);
        
        ABRecordRef currentPerson = ABAddressBookGetPersonWithRecordID(addressBook, [[self userABID] intValue]);
        NSString *firstName = (__bridge_transfer NSString *)ABRecordCopyValue(currentPerson, kABPersonFirstNameProperty) ;
        NSString *surname = (__bridge_transfer NSString *)ABRecordCopyValue(currentPerson, kABPersonLastNameProperty) ;
        
        CFRelease(addressBook);
    
        return [NSString stringWithFormat:@"%@ %@", firstName?firstName:@"", surname?surname:@""];
        
    }else {return nil;}
}

- (NSString*) labelForRegisteredNumber{
    if (self.userABID && self.registeredID) {
        ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(nil, nil);
        ABRecordRef currentPerson = ABAddressBookGetPersonWithRecordID(addressBook, [[self userABID] intValue]);
        
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
