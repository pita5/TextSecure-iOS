//
//  Constants.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 3/24/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

//
//  Constants.h
//  Kliq
//
//  Defines some constants needed by bamboo, the temporary API we are using as an interface to facebook connect
//
//  Created by Christine Corbett Moran on 6/11/10.
//  Copyright 2010 Cannytrophic LLC. All rights reserved.
//

// We have three server instances running on three ports, two for development one for production
// This requires we have two FB apps, one for dev one for production.
// Their use is configured statically in the app here

extern NSString* const textSecureServer;
extern NSString* const textSecureAccountsAPI;
extern NSString* const appName;
extern NSString* const authenticationTokenStorageId;
typedef enum {
	CREATE_ACCOUNT=0,
	VERIFY_ACCOUNT=1
} TextSecureRequestType;


