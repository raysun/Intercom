//
//  Created by Jesse Squires
//  http://www.jessesquires.com
//
//
//  Documentation
//  http://cocoadocs.org/docsets/JSQMessagesViewController
//
//
//  GitHub
//  https://github.com/jessesquires/JSQMessagesViewController
//
//
//  License
//  Copyright (c) 2014 Jesse Squires
//  Released under an MIT license: http://opensource.org/licenses/MIT
//

#import "DemoModelData.h"
#import "AppDelegate.h"
#import "NSUserDefaults+DemoSettings.h"


/**
 *  This is for demo/testing purposes only.
 *  This object sets up some fake model data.
 *  Do not actually do anything like this.
 */

@implementation DemoModelData {
    AppDelegate *appDelegate;
}

- (id)init {
    self = [super init];
    if (self) {
        appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        
        self.messages = [NSMutableArray new];
        // [self loadFakeMessages]; // Used only for the App Store screenshot
        
        
        /**
         *  Create avatar images once.
         *
         *  Be sure to create your avatars one time and reuse them for good performance.
         *
         *  If you are not using avatars, ignore this.
         */
        JSQMessagesAvatarImage *jsqImage = [JSQMessagesAvatarImageFactory avatarImageWithUserInitials:@"JSQ"
                                                                                      backgroundColor:[UIColor colorWithWhite:0.85f alpha:1.0f]
                                                                                            textColor:[UIColor colorWithWhite:0.60f alpha:1.0f]
                                                                                                 font:[UIFont systemFontOfSize:14.0f]
                                                                                             diameter:kJSQMessagesCollectionViewAvatarSizeDefault];
        
        JSQMessagesAvatarImage *cookImage = [JSQMessagesAvatarImageFactory avatarImageWithImage:[UIImage imageNamed:@"demo_avatar_cook"]
                                                                                       diameter:kJSQMessagesCollectionViewAvatarSizeDefault];
        
        JSQMessagesAvatarImage *jobsImage = [JSQMessagesAvatarImageFactory avatarImageWithImage:[UIImage imageNamed:@"demo_avatar_jobs"]
                                                                                       diameter:kJSQMessagesCollectionViewAvatarSizeDefault];
        
        JSQMessagesAvatarImage *wozImage = [JSQMessagesAvatarImageFactory avatarImageWithImage:[UIImage imageNamed:@"demo_avatar_woz"]
                                                                                      diameter:kJSQMessagesCollectionViewAvatarSizeDefault];
        
        
        self.avatars = @{ kJSQDemoAvatarIdSquires : jsqImage,
                          kJSQDemoAvatarIdCook : cookImage,
                          kJSQDemoAvatarIdJobs : jobsImage,
                          kJSQDemoAvatarIdWoz : wozImage };
        
        
        self.users = @{ kJSQDemoAvatarIdJobs : kJSQDemoAvatarDisplayNameJobs,
                        kJSQDemoAvatarIdCook : kJSQDemoAvatarDisplayNameCook,
                        kJSQDemoAvatarIdWoz : kJSQDemoAvatarDisplayNameWoz,
                        kJSQDemoAvatarIdSquires : kJSQDemoAvatarDisplayNameSquires };
        
        
        /**
         *  Create message bubble images objects.
         *
         *  Be sure to create your bubble images one time and reuse them for good performance.
         *
         */
        JSQMessagesBubbleImageFactory *bubbleFactory = [[JSQMessagesBubbleImageFactory alloc] init];
        
        self.outgoingBubbleImageData = [bubbleFactory outgoingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleBlueColor]];
        self.incomingBubbleImageData = [bubbleFactory incomingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleLightGrayColor]];
    }
    
    return self;
}

- (void)loadOOBEMessages {
    self.messages = [[NSMutableArray alloc] initWithObjects:
                     [[JSQMessage alloc] initWithSenderId:kJSQDemoAvatarIdSquires
                                        senderDisplayName:kJSQDemoAvatarDisplayNameSquires
                                                     date:[NSDate distantPast]
                                                     text:@"Send a message to any of your devices."],
                     nil];
    
}

- (void)loadFakeMessages
{
    /**
     *  Load some fake messages for screenshot
     */
    self.messages = [[NSMutableArray alloc] initWithObjects:
                     [[JSQMessage alloc] initWithSenderId:@"Karen's iPhone"
                                        senderDisplayName:@"Karen's iPhone"
                                                     date:[NSDate dateWithTimeInterval:-600 sinceDate:[NSDate date]]
                                                     text:@"🍴"],

                     [[JSQMessage alloc] initWithSenderId:@"Karen's iPhone"
                                        senderDisplayName:@"Karen's iPhone"
                                                     date:[NSDate dateWithTimeInterval:-600 sinceDate:[NSDate date]]
                                                     text:@"Time to eat"],
                     
                     [[JSQMessage alloc] initWithSenderId:appDelegate.myID
                                        senderDisplayName:appDelegate.myID
                                                     date:[NSDate dateWithTimeInterval:-600 sinceDate:[NSDate date]]
                                                     text:@"5 minutes mom"],
                     
                     [[JSQMessage alloc] initWithSenderId:@"Karen's iPhone"
                                        senderDisplayName:@"Karen's iPhone"
                                                     date:[NSDate date]
                                                     text:@"🍴"],
                     
                     [[JSQMessage alloc] initWithSenderId:@"Karen's iPhone"
                                        senderDisplayName:@"Karen's iPhone"
                                                     date:[NSDate date]
                                                     text:@"Are you coming? Dinner's on the table"],
                     
                     [[JSQMessage alloc] initWithSenderId:appDelegate.myID
                                        senderDisplayName:appDelegate.myID
                                                     date:[NSDate date]
                                                     text:@"sorry mom on the way! 😀"],
                     nil];
    
//        self.emoticons = @[@"📚",@"😴",@"🍴",@"🏈",@"🚗",@"❤️"];
    
}

// Add a new message to the store, which will then be read by message view & displayed
- (void)add:(JSQMessage *)newMessage {
    [self.messages addObject:newMessage];
}

- (void)addPhotoMediaMessage
{
    JSQPhotoMediaItem *photoItem = [[JSQPhotoMediaItem alloc] initWithImage:[UIImage imageNamed:@"goldengate"]];
    JSQMessage *photoMessage = [JSQMessage messageWithSenderId:kJSQDemoAvatarIdSquires
                                                   displayName:kJSQDemoAvatarDisplayNameSquires
                                                         media:photoItem];
    [self.messages addObject:photoMessage];
}

- (void)addPhotoMediaMessage:(UIImage *)image
{
    JSQPhotoMediaItem *photoItem = [[JSQPhotoMediaItem alloc] initWithImage:image];
    JSQMessage *photoMessage = [JSQMessage messageWithSenderId:appDelegate.myID
                                                   displayName:appDelegate.myName
                                                         media:photoItem];
    [self.messages addObject:photoMessage];
}

- (void)addLocationMediaMessageCompletion:(JSQLocationMediaItemCompletionBlock)completion
{
    CLLocation *ferryBuildingInSF = [[CLLocation alloc] initWithLatitude:37.795313 longitude:-122.393757];
    
    JSQLocationMediaItem *locationItem = [[JSQLocationMediaItem alloc] init];
    [locationItem setLocation:ferryBuildingInSF withCompletionHandler:completion];
    
    JSQMessage *locationMessage = [JSQMessage messageWithSenderId:kJSQDemoAvatarIdSquires
                                                      displayName:kJSQDemoAvatarDisplayNameSquires
                                                            media:locationItem];
    [self.messages addObject:locationMessage];
}

- (void)addVideoMediaMessage
{
    // don't have a real video, just pretending
    NSURL *videoURL = [NSURL URLWithString:@"file://"];
    
    JSQVideoMediaItem *videoItem = [[JSQVideoMediaItem alloc] initWithFileURL:videoURL isReadyToPlay:YES];
    JSQMessage *videoMessage = [JSQMessage messageWithSenderId:kJSQDemoAvatarIdSquires
                                                   displayName:kJSQDemoAvatarDisplayNameSquires
                                                         media:videoItem];
    [self.messages addObject:videoMessage];
}




@end
