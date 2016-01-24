//
//  Message.m
//  Intercom
//
//  Created by Karen and Ray Sun on 1/11/16.
//  Copyright © 2016 Ray Sun. All rights reserved.
//

#import "Message.h"

@implementation Message

- (id)init {
    if (self = [super init]) {
        _datetime = [NSDate date];
    }
    return self;
}

@end
