//
//  NSString+Conversion.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 3/27/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "NSString+Conversion.h"

//
//  NSData+Conversion.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 3/26/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//
@implementation NSString (NSString_Conversion)

#pragma mark - Base 64 Conversion
- (NSString *)base64Encoded {
    return [[self dataUsingEncoding: NSASCIIStringEncoding] base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
}


-(NSString *) rot13String {
	const char *_string = [self cStringUsingEncoding:NSASCIIStringEncoding];
	int stringLength = [self length];
	char newString[stringLength+1];
	
	int x;
	for( x=0; x<stringLength; x++ ) {
		unsigned int aCharacter = _string[x];
		
		if( 0x40 < aCharacter && aCharacter < 0x5B ) // A - Z
			newString[x] = (((aCharacter - 0x41) + 0x0D) % 0x1A) + 0x41;
		else if( 0x60 < aCharacter && aCharacter < 0x7B ) // a-z
			newString[x] = (((aCharacter - 0x61) + 0x0D) % 0x1A) + 0x61;
		else  // Not an alpha character
			newString[x] = aCharacter;
	}
	newString[x] = '\0';
	NSString *rotString = [NSString stringWithCString:newString encoding:NSASCIIStringEncoding];
	return( rotString );
}

- (NSString *)unformattedPhoneNumber {
  NSCharacterSet *toExclude = [NSCharacterSet characterSetWithCharactersInString:@"/.()- "];
  return [[self componentsSeparatedByCharactersInSet:toExclude] componentsJoinedByString: @""];
}


@end