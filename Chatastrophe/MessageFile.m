//
//  MessageFile.m
//  Intercom
//
//  Created by Karen and Ray Sun on 1/12/16.
//  Copyright © 2016 Ray Sun. All rights reserved.
//

#import "MessageFile.h"

@implementation MessageFile {
    JSQMessage *message;
}

- (id)init {
    /*
    self = [super init];
    if (self != nil)
    {
    }
     */
    return self;
}

- (id)contentsForType:(NSString *)typeName error:(NSError * _Nullable __autoreleasing *)outError {
//    message.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:message];
    return data;
}

- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError * _Nullable __autoreleasing *)outError {
    message = [NSKeyedUnarchiver unarchiveObjectWithData:contents];
    return true;
}
@end
