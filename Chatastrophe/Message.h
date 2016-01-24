//
//  Message.h
//  Intercom
//
//  Created by Karen and Ray Sun on 1/11/16.
//  Copyright © 2016 Ray Sun. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Message : NSObject

@property NSDate *datetime;
@property NSString *text;
@property NSString *senderID; // Sender ID will be the OneSignal ID

@end
