//
//  Constants.h
//  Where's My Bus
//
//  Created by Maarut Chandegra on 25/07/2016.
//  Copyright © 2016 Maarut Chandegra. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const kTFLAppID;
extern NSString *const kTFLAppKey;
extern NSString *const kAdMobAppId;
extern NSString *const kAdMobAdUnitId;

@interface MCConstants: NSObject
+(NSArray *)adMobTestDevices;
@end
