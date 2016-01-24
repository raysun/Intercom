//
//  Model.m
//  Chatastrophe
//
//  Created by Karen and Ray Sun on 1/7/16.
//  Copyright © 2016 Ray Sun. All rights reserved.
//

#import "Model.h"
#import "Message.h"

@implementation Model {
    NSMutableArray *messageList;
}

static Model *sharedModel = nil;

+ (Model *) sharedModel {
    @synchronized(self) {
        if (sharedModel == nil) {
            sharedModel = [Model new];
        }
    }
    return sharedModel;
}

- (id)init {
    if (self = [super init]) {
//        self.deviceList = [NSMutableArray new];
    }
    return self;
}

- (NSArray *) getMessages:(NSString *)deviceID {
    return messageList;
}

- (BOOL) addMessage:(Message *)message {
    [messageList addObject:message];
    return true;
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    decoder = [NSKeyedUnarchiver unarchiveObjectWithFile:(NSString *)[[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil]];
    messageList = [decoder decodeObjectForKey:@"messageList"];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:messageList forKey:@"messageList"];
    
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath = [NSString stringWithFormat:@"%@/messages",[searchPaths objectAtIndex:0]];
    [NSKeyedArchiver archiveRootObject:encoder toFile:documentPath];
    NSError *error;
    [[NSFileManager defaultManager] setUbiquitous:YES itemAtURL:[NSURL URLWithString:documentPath] destinationURL:[[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil] error:&error];
}



@end
