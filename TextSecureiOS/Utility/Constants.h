//
//  Constants.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 3/24/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

//Colors
#import "UIColor+TextSecure.h"

#define kLastResortKeyId 0xFFFFFF

extern NSString* const textSecureServer;
extern NSString* const textSecureGeneralAPI;
extern NSString* const textSecureAccountsAPI;
extern NSString* const textSecureKeysAPI;

extern NSString* const textSecureMessagesAPI;
extern NSString* const textSecureDirectoryAPI;
extern NSString* const textSecureAttachmentsAPI;
extern NSString* const appName;
extern NSString* const authenticationTokenStorageId;
extern NSString* const usernameTokenStorageId;
extern NSString* const signalingTokenStorageId;
extern NSString* const prekeyCounterStorageId;
extern NSString* const encryptedMasterSecretKeyStorageId;
extern NSString* const textSecureAttachmentsAPI;
extern NSTimeInterval const timeOutForRequests;
extern unsigned char const textSecureVersion;
// CountryCodes.plist constants
extern NSString* const countryInfoPathInMainBundle;
extern NSString* const countryInfoKeyCountryCode;
extern NSString* const countryInfoKeyName;

typedef NS_ENUM(NSInteger, TSGroupContextType) {
    TSUnknownGroupContext = 0,
    TSUpdateGroupContext = 1,
    TSDeliverGroupContext = 2,
    TSQuitGroupContext =3
};

typedef NS_ENUM(NSInteger, TSPushMessageFlags) {
    TSNoFlag = 0,
    TSEndSession = 1
};

typedef NS_ENUM(NSInteger, TSWhisperMessageType) {
    TSUnknownMessageType =0,
    TSEncryptedWhisperMessageType = 1,
    TSIgnoreOnIOSWhisperMessageType=2, // on droid this is the prekey bundle message irrelevant for us
    TSPreKeyWhisperMessageType = 3,
    TSUnencryptedWhisperMessageType = 4,
};

typedef NS_ENUM(NSInteger, TSMACType) {
    TSHMACSHA1Truncated10Bytes = 1,
    TSHMACSHA256Truncated10Bytes = 2

};



#define kTSVersion 
#define kScreenshotProtection @"screenshotProtection"
#define kDBNewMessageNotification @"db_new_message"
#define kContactIdentity @"db_new_message"
