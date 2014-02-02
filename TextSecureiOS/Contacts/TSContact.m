//
//  TSContact.m
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 10/20/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "TSContact.h"
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
        NSString *firstName = (__bridge NSString *)ABRecordCopyValue(currentPerson, kABPersonFirstNameProperty) ;
        NSString *surname = (__bridge NSString *)ABRecordCopyValue(currentPerson, kABPersonLastNameProperty) ;
        
        return [NSString stringWithFormat:@"%@ %@", firstName?firstName:@"", surname?surname:@""];
        
    }else {return nil;}
}

- (NSString*) labelForRegisteredNumber{
    
}

-(void) save{
    [TSMessagesDatabase storeTSContact:self];
}
@end
