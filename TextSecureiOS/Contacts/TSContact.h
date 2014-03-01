//
//  TSContact.h
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 10/20/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TSContact : NSObject

#pragma mark Initializing properties
@property (nonatomic, readonly) NSString *relay;
@property (nonatomic, readonly) NSString *registeredID;

#pragma mark Optional properties

@property (nonatomic) NSData *identityKey;
@property (nonatomic) NSArray *deviceIDs;
@property BOOL identityKeyIsVerified;

/**
 *  A TSContact is created to store information about contacts the user is communicating with.
 *
 *  @param registeredID The registered phone number of the TextSecure user
 *  @param relay The relay on which the TextSecure user is registered
 *  @return TSContact instance
 */

- (instancetype)initWithRegisteredID:(NSString*)registeredID relay:(NSString*)relay;

/**
 *  Same as TS initWithRegisteredID:(NSString*)registeredID relay:(NSString*)relay. TSContacts are initiated when the user looks up which of his contacts are using TextSecure. Constructor reflects the parameters given by the contact intersection API (https://github.com/WhisperSystems/TextSecure-Server/wiki/API-Protocol#wiki-getting-a-contact-intersection)
 *
 *  @param registeredID The registered phone number of the TextSecure user
 *  @param relay The relay on which the TextSecure user is registered
 *  @param abId The ABRecordRef for the user
 *  @return TSContact instance
 */
- (instancetype)initWithRegisteredID:(NSString*)registeredID relay:(NSString*)relay addressBookID:(NSNumber*)abId;

/**
 *  Returns the name of the TextSecure user
 *
 *  @return TextSecure user's name. Firstname + Lastname of addressbook
 */

- (NSString*) name;

/**
 *  Returns addressbook's identifier of the contact
 *
 *  @return ABRecordRef NSNumber-encoded
 */
- (NSNumber*) addressBookID;

/**
 *  Returns the label for the registered phone number
 *
 *  @return Localized label of the contact's registered phone number
 */

- (NSString*) labelForRegisteredNumber;

/**
 *  Synchronously saves the TSContact to the database
 */

-(void) save;

@end
