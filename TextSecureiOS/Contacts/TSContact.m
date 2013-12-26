//
//  TSContact.m
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 10/20/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "TSContact.h"
#import <AddressBook/AddressBook.h>
#import "TSEncryptedDatabase.h"
@implementation TSContact
- (NSString*) name{
  if (self.userABID){
    
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(nil, nil);
    
    ABRecordRef currentPerson = ABAddressBookGetPersonWithRecordID(addressBook, [[self userABID] intValue]);
    NSString *firstName = (__bridge NSString *)ABRecordCopyValue(currentPerson, kABPersonFirstNameProperty) ;
    NSString *surname = (__bridge NSString *)ABRecordCopyValue(currentPerson, kABPersonLastNameProperty) ;
    
    return [NSString stringWithFormat:@"%@ %@", firstName, surname];
    
  }else {return nil;}
}

-(void) save{
  [[TSEncryptedDatabase database] storeTSContact:self];
}
@end
