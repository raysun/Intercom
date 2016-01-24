//
//  Model.h
//  Chatastrophe
//
//  Created by Karen and Ray Sun on 1/7/16.
//  Copyright © 2016 Ray Sun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Message.h"

@interface Model : NSObject <NSCoding>
@property (nonatomic, retain) NSMutableArray *deviceList;


+ (Model *) sharedModel;
// - (Message *) getMessage:(NSString *)deviceID atIndex:(NSInteger *)index;
- (NSArray *) getMessages:(NSString *)deviceID;
- (BOOL) addMessage:(NSString *)deviceID;
@end
