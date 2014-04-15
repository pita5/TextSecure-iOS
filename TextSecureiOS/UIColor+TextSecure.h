//
//  UIColor+TextSecure.h
//  TextSecureiOS
//
//  Created by Dylan Bourgeois on 16/04/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (TextSecure)
//Green color for validation
+(UIColor*)TSValidColor;
//Light gray background for buttons
+(UIColor*)TSButtonBackgroundColor;
//Light gray color for Text
+(UIColor*)TSLightTextColor;
//Light blue color for underlining text
+(UIColor*)TSBlueBarColor;
//Light blue color for underlining text with alpha=0.7
+(UIColor*)TSBlueBarColorWithAlpha;
@end
