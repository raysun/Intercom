//
//  AppDelegate.h
//  Chatastrophe
//
//  Created by Karen and Ray Sun on 1/6/16.
//  Copyright © 2016 Ray Sun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DemoModelData.h"
//#import <OneSignal/OneSignal.h>

#define NSLog(FORMAT, ...) printf("-- %s\n", [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);

@interface AppDelegate : UIResponder <UIApplicationDelegate> {
}

@property (strong, nonatomic) UIWindow *window;
@property (strong, retain) NSMutableDictionary *allMessages;
@property (strong, retain) NSMutableArray *messageIDs;
//@property (strong, retain) NSMutableArray *notificationIDs;
@property (nonatomic, retain) NSArray *deviceList;
@property (strong, retain) NSDictionary *myDevice;
@property (strong, retain) NSString *myID;
@property (strong, retain) NSString *myName;
@property (strong, retain) NSArray *emoticons;
@property BOOL atLeastOneMessageReceived; // Extra check to hide the warning when I've already received a message, even if devicelist is just me


@end

