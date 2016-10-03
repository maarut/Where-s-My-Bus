//
//  Constants.m
//  Where's My Bus
//
//  Created by Maarut Chandegra on 25/07/2016.
//  Copyright © 2016 Maarut Chandegra. All rights reserved.
//

#import "Constants.h"

NSString *const kTFLAppID = TFL_APP_ID;
NSString *const kTFLAppKey = TFL_APP_KEY;
NSString *const kAdMobAppId = ADMOB_APP_ID;
NSString *const kAdMobAdUnitId = ADMOB_ADUNIT_ID;

@implementation MCConstants

static NSArray *kAdMobTestDevices;

+ (NSArray *) adMobTestDevices
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kAdMobTestDevices = [ADMOB_TEST_DEVICES componentsSeparatedByString:@" "];
    });
    return kAdMobTestDevices;
}

@end
