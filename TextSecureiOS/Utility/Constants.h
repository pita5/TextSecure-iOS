//
//  Constants.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 3/24/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

extern NSString* const textSecureServer;
extern NSString* const textSecureAccountsAPI;
extern NSString* const textSecureKeysAPI;

extern NSString* const textSecureMessagesAPI;
extern NSString* const textSecureDirectoryAPI;

extern NSString* const appName;
extern NSString* const authenticationTokenStorageId;
extern NSString* const usernameTokenStorageId;
extern NSString* const signalingTokenStorageId;
extern NSString* const prekeyCounterStorageId;
extern NSString* const encryptedMasterSecretKeyStorageId;
typedef enum {
	CREATE_ACCOUNT=0,
	VERIFY_ACCOUNT=1,
  SEND_APN=2,
  SEND_MESSAGE=3,
  GET_DIRECTORY=4,
  GET_DIRECTORY_LINK=5,
  REGISTER_PRE_KEYS=6,
} TextSecureRequestType;


typedef enum {
	POST=0,
  EMPTYPOST=1,
  GET=2,
  PUT=3,
  DOWNLOAD=4
} HTTPRequestType;

double const timeOutForRequests;
