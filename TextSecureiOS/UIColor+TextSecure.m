//
//  UIColor+TextSecure.m
//  TextSecureiOS
//
//  Created by Dylan Bourgeois on 16/04/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import "UIColor+TextSecure.h"

@implementation UIColor (TextSecure)

+(UIColor*)TSValidColor
{
    return [UIColor colorWithRed:105.f/255.f green:206.f/255.f blue:38.f/255.f alpha:1];
}
+(UIColor*)TSButtonBackgroundColor
{
    return [UIColor colorWithRed:239.f/255.f green:239.f/255.f blue:244.f/255.f alpha:1];
}
+(UIColor*)TSLightTextColor
{
    return [UIColor colorWithRed:175.f/255.f green:177.f/255.f blue:175.f/255.f alpha:1];
}
+(UIColor*)TSBlueBarColor
{
    //Correction of RGB values for alpha=1
    return [UIColor colorWithRed:101.f/255.f green:187.f/255.f blue:231.f/255.f alpha:1];
}
+(UIColor*)TSBlueBarColorWithAlpha
{
    //Alpha used in Storyboard for bars is 0.7
    return [UIColor colorWithRed:43.f/255.f green:166.f/255.f blue:224.f/255.f alpha:0.7];
}

@end
