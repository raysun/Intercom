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

#import "MessagesViewController.h"

@import CloudKit;
#import "AppDelegate.h"

#import "DemoModelData.h"
#import "JSQMessage.h"

//#import "APLViewController.h"

@interface MessagesViewController()

- (void)useNotificationWithString:(NSNotification*)notification;

@property (nonatomic) UIImagePickerController *imagePickerController;

@property (weak, nonatomic) IBOutlet UILabel *welcomeMessage;
@end

@implementation MessagesViewController {
    CKContainer *container;
    AppDelegate *appDelegate;
    DemoModelData *model;
    NSDictionary *allMessages;
    
    NSString *deviceID;
    NSString *deviceName;
//    APLViewController *photoPickerVC;
    UIAlertController *alert;
    
}

#pragma mark - View lifecycle

/**
 *  Override point for customization.
 *
 *  Customize your view.
 *  Look at the properties on `JSQMessagesViewController` and `JSQMessagesCollectionView` to see what is possible.
 *
 *  Customize your layout.
 *  Look at the properties on `JSQMessagesCollectionViewFlowLayout` to see what is possible.
 */
- (void)viewDidLoad
{
    [super viewDidLoad];
    container = [CKContainer containerWithIdentifier:@"iCloud.com.raysun.Intercom"];

    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(useNotificationWithString:)
     name:@"NewMessages"
     object:nil];

    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(useNotificationWithString:)
     name:@"AllMessagesDownloadedFromCloud"
     object:nil];

    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(useNotificationWithString:)
     name:@"ShowWelcomeMessage"
     object:nil];

    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(useNotificationWithString:)
     name:@"ActionSend"
     object:nil];
    
    appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    /**
     *  You MUST set your senderId and display name
     */
 //   self.senderId = kJSQDemoAvatarIdSquires;
    
    if (!(self.senderId = appDelegate.myID)) {
        self.senderId = @"";
    }
    
    self.senderDisplayName = appDelegate.myName;
    
    self.inputToolbar.contentView.textView.pasteDelegate = self;
    allMessages = appDelegate.allMessages;
    
//    NSLog(@"%@",self.inputToolbar.contentView);
    NSMutableArray *toolbarItems = [NSMutableArray new];
    NSArray *emoticons = appDelegate.emoticons;
    for (NSString *emoticon in emoticons) {
        UIBarButtonItem *emotiButton = [[UIBarButtonItem alloc] initWithTitle:emoticon style:UIBarButtonItemStylePlain target:self action:@selector(didSelectEmoticon:)];
        emotiButton.tag = 1;    // 1 is a special emoticon button
        
        [toolbarItems addObject:emotiButton];
    }
    UIBarButtonItem *cameraButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(didSelectCamera:)];
    cameraButton.tintColor = [UIColor darkGrayColor];
    [toolbarItems insertObject:cameraButton atIndex:0];
    [self.inputToolbar.contentView.buttonBar setItems:toolbarItems animated:NO];

    // Set the title
    // no longer checking selectedindex - all messages to ALL
//    if (self.selectedIndex.section == 0) {
        deviceName = @"All devices";
        deviceID = @"All";
    
        self.demoData = allMessages[@"All"];
    /*
} else {
        deviceName = [deviceList[self.selectedIndex.row] valueForKey:@"deviceName"];
        deviceID = [deviceList[self.selectedIndex.row] valueForKey:@"deviceID"];
        self.title = deviceName;
        self.demoData = allMessages[deviceID];
    }
  */
    /**
     *  You can set custom avatar sizes
     */
    if (![NSUserDefaults incomingAvatarSetting]) {
        self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
    }
    
    if (![NSUserDefaults outgoingAvatarSetting]) {
        self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
    }
    
  //  self.showLoadEarlierMessagesHeader = YES;
    
    /**
     *  Register custom menu actions for cells.
     */

    /*
    [JSQMessagesCollectionViewCell registerMenuAction:@selector(customAction:)];
    [UIMenuController sharedMenuController].menuItems = @[ [[UIMenuItem alloc] initWithTitle:@"Custom Action"
                                                                                      action:@selector(customAction:)] ];
     */
    
    /**
     *  OPT-IN: allow cells to be deleted
     */
    [JSQMessagesCollectionViewCell registerMenuAction:@selector(delete:)];

    /**
     *  Customize your toolbar buttons
     *
     *  self.inputToolbar.contentView.leftBarButtonItem = custom button or nil to remove
     *  self.inputToolbar.contentView.rightBarButtonItem = custom button or nil to remove
     */

    /**
     *  Set a maximum height for the input toolbar
     *
     *  self.inputToolbar.maximumHeight = 150;
     */
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.delegateModal) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop
                                                                                              target:self
                                                                                              action:@selector(closePressed:)];
    }


}

- (void)useNotificationWithString:(NSNotification *)notification {
    
    NSLog(@"MessagesView received notification %@",notification.name);
    if ([notification.name isEqualToString:@"ActionSend"]) {
        if (notification.userInfo[@"EmoticonIndex"]) {
            [self didSelectEmoticon:self.inputToolbar.contentView.buttonBar.items[[notification.userInfo[@"EmoticonIndex"] intValue] + 1]];
        } else {
            [self didPressSendButton:nil withMessageText:notification.userInfo[@"Body"] senderId:appDelegate.myID senderDisplayName:appDelegate.myName date:[NSDate date]];
        }
    } else {
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [self finishReceivingMessageAnimated:YES];
            /* Welcome message inline for no icloud or no messages
             if ([notification.name isEqualToString:@"ShowWelcomeMessage"]) {
             self.welcomeMessage.hidden = NO;
             [self.view bringSubviewToFront:self.welcomeMessage];
             }
             */
        });
    }
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    /**
     *  Enable/disable springy bubbles, default is NO.
     *  You must set this from `viewDidAppear:`
     *  Note: this feature is mostly stable, but still experimental
     */
    self.collectionView.collectionViewLayout.springinessEnabled = [NSUserDefaults springinessSetting];
}



#pragma mark - Testing

- (void)pushMainViewController
{
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UINavigationController *nc = [sb instantiateInitialViewController];
    [self.navigationController pushViewController:nc.topViewController animated:YES];
}

#pragma mark - User sent message

- (void)didPressSendButton:(UIButton *)button
           withMessageText:(NSString *)text
                  senderId:(NSString *)senderId
         senderDisplayName:(NSString *)senderDisplayName
                      date:(NSDate *)date
{
    /**
     *  Sending a message. Your implementation of this method should do *at least* the following:
     *
     *  1. Play sound (optional)
     *  2. Add new id<JSQMessageData> object to your data source
     *  3. Call `finishSendingMessage`
     */
    [JSQSystemSoundPlayer jsq_playMessageSentSound];
    
    JSQMessage *message = [[JSQMessage alloc] initWithSenderId:appDelegate.myID
                                             senderDisplayName:appDelegate.myName
                                                          date:date
                                                          text:text];
    
    [self.demoData.messages addObject:message];

    CKDatabase *privateDB = [container privateCloudDatabase];
    CKRecord *dbMessage = [[CKRecord alloc] initWithRecordType:@"Message"];
    dbMessage[@"From"] = appDelegate.myID;  //mydeviceid
    dbMessage[@"FromFriendlyName"] = appDelegate.myName;
    dbMessage[@"To"] = deviceID;
    dbMessage[@"ToFriendlyName"] = deviceName;
    dbMessage[@"Body"] = text;
    dbMessage[@"Date"] = [NSDate date];
//    dbMessage[@"Special"] = button.tag == 1 ? @"YES" : @"NO";
    dbMessage[@"Special"] = button.tag == 1 ? text : @"NO";
    
    [privateDB saveRecord:dbMessage completionHandler:^(CKRecord *savedPlace, NSError *error) {
            // handle errors here
//        if (!error) {
//            NSLog(@"Saved record %@",savedPlace);
//        }
    }];

    dispatch_async(dispatch_get_main_queue(), ^(void){
        [self finishSendingMessageAnimated:YES];
    });
    
    [self showWarningIfOnlyDevice];
}

- (void)showWarningIfOnlyDevice {
    NSUserDefaults *localStore = [NSUserDefaults standardUserDefaults];
    if (appDelegate.deviceList.count < 2 && [[localStore valueForKey:@"atLeastOneMessageReceived"] isEqual: @"NO"]) {
        JSQMessage *message = [[JSQMessage alloc] initWithSenderId:@"WarningID"
                                                 senderDisplayName:@"Warning"
                                                              date:[NSDate date]
                                                              text:@"No other iPhones or iPads found. Intercom only sends messages to devices with iCloud Drive enabled and signed in with your iCloud account."];
        
        [self.demoData.messages addObject:message];
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [self finishSendingMessageAnimated:YES];
        });
        
    }
}

-(void)didSelectEmoticon:(UIBarButtonItem*)sender {
    //    self.selectedEmoticon = sender.title;
    //    [self performSegueWithIdentifier:@"PhotoPickerDismissed" sender:self];
    [self didPressSendButton:(UIButton *)sender withMessageText:sender.title senderId:appDelegate.myID senderDisplayName:appDelegate.myName date:[NSDate date]];
}

-(void)didSelectCamera:(UIBarButtonItem*)sender {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
        UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
        imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
        imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
        imagePickerController.delegate = self;
        
        self.imagePickerController = imagePickerController;
        [self presentViewController:self.imagePickerController animated:YES completion:nil];
    }
}



// this will create a sized down/compressed cached image in the caches folder
- (NSURL *)createCachedImageFromImage:(UIImage *)image size:(CGSize)size
{
    NSURL *resultURL = nil;
    
    if (image != nil)
    {
        if (image.size.width > image.size.height)
        {
            size.height = round(size.width * image.size.height / image.size.width);
        }
        else
        {
            size.width = round(size.height * image.size.width / image.size.height);
        }
        
        UIGraphicsBeginImageContext(size);
        [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
        
        NSData *data = UIImageJPEGRepresentation(UIGraphicsGetImageFromCurrentImageContext(), 0.75);
        UIGraphicsEndImageContext();
        
        // write the image out to a cache file
        NSURL *cachesDirectory = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory
                                                                        inDomain:NSUserDomainMask
                                                               appropriateForURL:nil
                                                                          create:YES
                                                                           error:nil];
        NSString *temporaryName = [[NSUUID UUID].UUIDString stringByAppendingPathExtension:@"jpeg"];
        resultURL = [cachesDirectory URLByAppendingPathComponent:temporaryName];
        [data writeToURL:resultURL atomically:YES];
    }
    
    return resultURL;
}

#pragma mark - UIImagePickerControllerDelegate

// This method is called when an image has been chosen from the library or taken from the camera.
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
    
    self.selectedImage = image;
    
    [self finishAndUpdate];
}

- (void)finishAndUpdate
{
    [self dismissViewControllerAnimated:YES completion:NULL];
    
    self.imagePickerController = nil;
    
    //    [self dismissViewControllerAnimated:YES completion:NULL];
    //    [self performSegueWithIdentifier:@"PhotoPickerDismissed" sender:self];
    [JSQSystemSoundPlayer jsq_playMessageSentSound];
    
    // Emoticon button pressed, or image returned?
    JSQPhotoMediaItem *photoItem = [[JSQPhotoMediaItem alloc] initWithImage:self.selectedImage];
    JSQMessage *photoMessage = [JSQMessage messageWithSenderId:appDelegate.myID
                                                   displayName:appDelegate.myName
                                                         media:photoItem];
    
    
    [self.demoData.messages addObject:photoMessage];
    
    CKDatabase *privateDB = [container privateCloudDatabase];
    CKRecord *dbMessage = [[CKRecord alloc] initWithRecordType:@"Message"];
    dbMessage[@"From"] = appDelegate.myID;  //mydeviceid
    dbMessage[@"FromFriendlyName"] = appDelegate.myName;
    dbMessage[@"To"] = deviceID;
    dbMessage[@"ToFriendlyName"] = deviceName;
    dbMessage[@"Body"] = @"Photo";
    dbMessage[@"Date"] = [NSDate date];
    dbMessage[@"Special"] = @"NO";
    
    UIImage *image = self.selectedImage;
    
    // create a sized down/compressed cached image in the caches folder, to utilize CKAsset
    //BUGBUG: doesn't handle portrait photos or selfies properly
    const CGSize kImageSize = {504, 378};
    NSURL *imageURL = [self createCachedImageFromImage:image size:kImageSize];
    if (imageURL != nil)
    {
        CKAsset *asset = [[CKAsset alloc] initWithFileURL:imageURL];
        dbMessage[@"Image"] = asset;
    }
    
    [privateDB saveRecord:dbMessage completionHandler:^(CKRecord *savedPlace, NSError *error) {
        // handle errors here
        if (!error) {
            NSLog(@"Saved record %@",savedPlace);
        }
    }];
    
    dispatch_async(dispatch_get_main_queue(), ^(void){
        [self finishSendingMessageAnimated:YES];
    });
}



- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}












#pragma mark - Old code - // TODO: delete this method if we're not going back to the "select photo or take picture" controller

- (void)didPressAccessoryButton:(UIButton *)sender
{
    /*
     // BUGBUG: For testing, reusing the attachment button to send test text
     int randomNumber = arc4random_uniform(10);
     NSString *testMessage = [NSString stringWithFormat:@"Yo %d",randomNumber];
     [self didPressSendButton:nil withMessageText:testMessage senderId:appDelegate.myID senderDisplayName:appDelegate.myName date:[NSDate date]];
     */
    
    [self.inputToolbar.contentView.textView resignFirstResponder];
    
    [self performSegueWithIdentifier:@"ShowPhotoPicker" sender:self];
    /*
     // grab the view controller we want to show
     UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
     UIViewController *controller = [storyboard instantiateViewControllerWithIdentifier:@"PhotoPicker"];
     
     // present the controller
     // on iPad, this will be a Popover
     // on iPhone, this will be an action sheet
     controller.modalPresentationStyle = UIModalPresentationCustom;
     controller.preferredContentSize = CGSizeMake(600.0,300.0);
     [self presentViewController:controller animated:YES completion:nil];
     
     // configure the Popover presentation controller
     UIPopoverPresentationController *popController = [controller popoverPresentationController];
     popController.permittedArrowDirections = UIPopoverArrowDirectionUp;
     popController.delegate = self;
     
     // in case we don't have a bar button as reference
     popController.sourceView = self.view;
     popController.sourceRect = CGRectMake(30, 50, 10, 10);
     */
}

/*
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    photoPickerVC = [segue destinationViewController];
}

// Coming back from photo picker, we call unwindAction on the segue
// TODO: delete this, I'm no longer unwinding a separate view controller; I'm calling the image picker directly from here.
- (IBAction)unwindAction:(UIStoryboardSegue*)unwindSegue {
    [JSQSystemSoundPlayer jsq_playMessageSentSound];
    
    // Emoticon button pressed, or image returned?
    if (photoPickerVC.selectedEmoticon) {
        [self didPressSendButton:nil withMessageText:photoPickerVC.selectedEmoticon senderId:appDelegate.myID senderDisplayName:appDelegate.myName date:[NSDate date]];
        
    } else {
        
        JSQPhotoMediaItem *photoItem = [[JSQPhotoMediaItem alloc] initWithImage:photoPickerVC.selectedImage];
        JSQMessage *photoMessage = [JSQMessage messageWithSenderId:appDelegate.myID
                                                       displayName:appDelegate.myName
                                                             media:photoItem];
        
        // Was saving the full size image to the local db, but moved it to after the scale down. No point wasting space, it's a TODO: to let you view the full size image anyway. Also, this prevents another bug where the JSQMessage bubble shows a portrait photo squished, since it doesn't crop properly until UI refresh. The createCachedImageFromImage call below does the right cropping.
        //        [self.demoData.messages addObject:photoMessage];
        
        CKDatabase *privateDB = [container privateCloudDatabase];
        CKRecord *dbMessage = [[CKRecord alloc] initWithRecordType:@"Message"];
        dbMessage[@"From"] = appDelegate.myID;  //mydeviceid
        dbMessage[@"FromFriendlyName"] = appDelegate.myName;
        dbMessage[@"To"] = deviceID;
        dbMessage[@"ToFriendlyName"] = deviceName;
        dbMessage[@"Body"] = @"Photo";
        dbMessage[@"Date"] = [NSDate date];
        
        UIImage *image = photoPickerVC.selectedImage;
        
        // create a sized down/compressed cached image in the caches folder, to utilize CKAsset
        //BUGBUG: doesn't handle portrait photos or selfies properly
        const CGSize kImageSize = {504, 378};
        NSURL *imageURL = [self createCachedImageFromImage:image size:kImageSize];
        if (imageURL != nil)
        {
            CKAsset *asset = [[CKAsset alloc] initWithFileURL:imageURL];
            dbMessage[@"Image"] = asset;
        }
        
        [self.demoData.messages addObject:photoMessage];
        
        [privateDB saveRecord:dbMessage completionHandler:^(CKRecord *savedPlace, NSError *error) {
            // handle errors here
            if (!error) {
                NSLog(@"Saved record %@",savedPlace);
            }
        }];
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [self finishSendingMessageAnimated:YES];
        });
        
        [self showWarningIfOnlyDevice];
    }
    
}
*/



#pragma mark - Fake JSQ messages stuff


- (void)receiveMessagePressed:(UIBarButtonItem *)sender
{
    /**
     *  DEMO ONLY
     *
     *  The following is simply to simulate received messages for the demo.
     *  Do not actually do this.
     */
    
    
    /**
     *  Show the typing indicator to be shown
     */
    self.showTypingIndicator = !self.showTypingIndicator;
    
    /**
     *  Scroll to actually view the indicator
     */
    [self scrollToBottomAnimated:YES];
    
    /**
     *  Copy last sent message, this will be the new "received" message
     */
    JSQMessage *copyMessage = [[self.demoData.messages lastObject] copy];
    
    if (!copyMessage) {
        copyMessage = [JSQMessage messageWithSenderId:kJSQDemoAvatarIdJobs
                                          displayName:kJSQDemoAvatarDisplayNameJobs
                                                 text:@"First received!"];
    }
    
    /**
     *  Allow typing indicator to show
     */
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        NSMutableArray *userIds = [[self.demoData.users allKeys] mutableCopy];
        [userIds removeObject:self.senderId];
        NSString *randomUserId = userIds[arc4random_uniform((int)[userIds count])];
        
        JSQMessage *newMessage = nil;
        id<JSQMessageMediaData> newMediaData = nil;
        id newMediaAttachmentCopy = nil;
        
        if (copyMessage.isMediaMessage) {
            /**
             *  Last message was a media message
             */
            id<JSQMessageMediaData> copyMediaData = copyMessage.media;
            
            if ([copyMediaData isKindOfClass:[JSQPhotoMediaItem class]]) {
                JSQPhotoMediaItem *photoItemCopy = [((JSQPhotoMediaItem *)copyMediaData) copy];
                photoItemCopy.appliesMediaViewMaskAsOutgoing = NO;
                newMediaAttachmentCopy = [UIImage imageWithCGImage:photoItemCopy.image.CGImage];
                
                /**
                 *  Set image to nil to simulate "downloading" the image
                 *  and show the placeholder view
                 */
                photoItemCopy.image = nil;
                
                newMediaData = photoItemCopy;
            }
            else if ([copyMediaData isKindOfClass:[JSQLocationMediaItem class]]) {
                JSQLocationMediaItem *locationItemCopy = [((JSQLocationMediaItem *)copyMediaData) copy];
                locationItemCopy.appliesMediaViewMaskAsOutgoing = NO;
                newMediaAttachmentCopy = [locationItemCopy.location copy];
                
                /**
                 *  Set location to nil to simulate "downloading" the location data
                 */
                locationItemCopy.location = nil;
                
                newMediaData = locationItemCopy;
            }
            else if ([copyMediaData isKindOfClass:[JSQVideoMediaItem class]]) {
                JSQVideoMediaItem *videoItemCopy = [((JSQVideoMediaItem *)copyMediaData) copy];
                videoItemCopy.appliesMediaViewMaskAsOutgoing = NO;
                newMediaAttachmentCopy = [videoItemCopy.fileURL copy];
                
                /**
                 *  Reset video item to simulate "downloading" the video
                 */
                videoItemCopy.fileURL = nil;
                videoItemCopy.isReadyToPlay = NO;
                
                newMediaData = videoItemCopy;
            }
            else {
                NSLog(@"%s error: unrecognized media item", __PRETTY_FUNCTION__);
            }
            
            newMessage = [JSQMessage messageWithSenderId:randomUserId
                                             displayName:self.demoData.users[randomUserId]
                                                   media:newMediaData];
        }
        else {
            /**
             *  Last message was a text message
             */
            newMessage = [JSQMessage messageWithSenderId:randomUserId
                                             displayName:self.demoData.users[randomUserId]
                                                    text:copyMessage.text];
        }
        
        /**
         *  Upon receiving a message, you should:
         *
         *  1. Play sound (optional)
         *  2. Add new id<JSQMessageData> object to your data source
         *  3. Call `finishReceivingMessage`
         */
        [JSQSystemSoundPlayer jsq_playMessageReceivedSound];
        [self.demoData add:newMessage];
        [self finishReceivingMessageAnimated:YES];
        
        
        if (newMessage.isMediaMessage) {
            /**
             *  Simulate "downloading" media
             */
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                /**
                 *  Media is "finished downloading", re-display visible cells
                 *
                 *  If media cell is not visible, the next time it is dequeued the view controller will display its new attachment data
                 *
                 *  Reload the specific item, or simply call `reloadData`
                 */
                
                if ([newMediaData isKindOfClass:[JSQPhotoMediaItem class]]) {
                    ((JSQPhotoMediaItem *)newMediaData).image = newMediaAttachmentCopy;
                    [self.collectionView reloadData];
                }
                else if ([newMediaData isKindOfClass:[JSQLocationMediaItem class]]) {
                    [((JSQLocationMediaItem *)newMediaData)setLocation:newMediaAttachmentCopy withCompletionHandler:^{
                        [self.collectionView reloadData];
                    }];
                }
                else if ([newMediaData isKindOfClass:[JSQVideoMediaItem class]]) {
                    ((JSQVideoMediaItem *)newMediaData).fileURL = newMediaAttachmentCopy;
                    ((JSQVideoMediaItem *)newMediaData).isReadyToPlay = YES;
                    [self.collectionView reloadData];
                }
                else {
                    NSLog(@"%s error: unrecognized media item", __PRETTY_FUNCTION__);
                }
                
            });
        }
        
    });
}

- (void)closePressed:(UIBarButtonItem *)sender
{
    [self.delegateModal didDismissJSQDemoViewController:self];
}


#pragma mark - JSQMessages CollectionView DataSource

- (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.demoData.messages objectAtIndex:indexPath.item];
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didDeleteMessageAtIndexPath:(NSIndexPath *)indexPath
{
    [self.demoData.messages removeObjectAtIndex:indexPath.item];
    
    CKDatabase *privateDB = [container privateCloudDatabase];
    
    [privateDB deleteRecordWithID:appDelegate.messageIDs[indexPath.row] completionHandler:^(CKRecordID * _Nullable recordID, NSError * _Nullable error) {
        if (!error) {
            NSLog(@"Deleted recordID %@",recordID);
        }
    }];
    
}

- (id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  You may return nil here if you do not want bubbles.
     *  In this case, you should set the background color of your collection view cell's textView.
     *
     *  Otherwise, return your previously created bubble image data objects.
     */
    
    JSQMessage *message = [self.demoData.messages objectAtIndex:indexPath.item];
    
    if ([message.senderId isEqualToString:self.senderId]) {
        return self.demoData.outgoingBubbleImageData;
    }
    
    return self.demoData.incomingBubbleImageData;
}

- (id<JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  Return `nil` here if you do not want avatars.
     *  If you do return `nil`, be sure to do the following in `viewDidLoad`:
     *
     *  self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
     *  self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
     *
     *  It is possible to have only outgoing avatars or only incoming avatars, too.
     */
    
    /**
     *  Return your previously created avatar image data objects.
     *
     *  Note: these the avatars will be sized according to these values:
     *
     *  self.collectionView.collectionViewLayout.incomingAvatarViewSize
     *  self.collectionView.collectionViewLayout.outgoingAvatarViewSize
     *
     *  Override the defaults in `viewDidLoad`
     */
    JSQMessage *message = [self.demoData.messages objectAtIndex:indexPath.item];
    
    if ([message.senderId isEqualToString:self.senderId]) {
        if (![NSUserDefaults outgoingAvatarSetting]) {
            return nil;
        }
    }
    else {
        if (![NSUserDefaults incomingAvatarSetting]) {
            return nil;
        }
    }
    
    
    return [self.demoData.avatars objectForKey:message.senderId];
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  This logic should be consistent with what you return from `heightForCellTopLabelAtIndexPath:`
     *  The other label text delegate methods should follow a similar pattern.
     *
     *  Show a timestamp for every 3rd message
     */
    if (indexPath.item % 3 == 0) {
        JSQMessage *message = [self.demoData.messages objectAtIndex:indexPath.item];
        return [[JSQMessagesTimestampFormatter sharedFormatter] attributedTimestampForDate:message.date];
    }
    
    return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    JSQMessage *message = [self.demoData.messages objectAtIndex:indexPath.item];
    
    /**
     *  iOS7-style sender name labels
     */
    if ([message.senderId isEqualToString:self.senderId]) {
        return nil;
    }
    
    if (indexPath.item - 1 > 0) {
        JSQMessage *previousMessage = [self.demoData.messages objectAtIndex:indexPath.item - 1];
        if ([[previousMessage senderId] isEqualToString:message.senderId]) {
            return nil;
        }
    }
    
    /**
     *  Don't specify attributes to use the defaults.
     */
    return [[NSAttributedString alloc] initWithString:message.senderDisplayName];
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

#pragma mark - UICollectionView DataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.demoData.messages count];
}

- (UICollectionViewCell *)collectionView:(JSQMessagesCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  Override point for customizing cells
     */
    JSQMessagesCollectionViewCell *cell = (JSQMessagesCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    
    /**
     *  Configure almost *anything* on the cell
     *
     *  Text colors, label text, label colors, etc.
     *
     *
     *  DO NOT set `cell.textView.font` !
     *  Instead, you need to set `self.collectionView.collectionViewLayout.messageBubbleFont` to the font you want in `viewDidLoad`
     *
     *
     *  DO NOT manipulate cell layout information!
     *  Instead, override the properties you want on `self.collectionView.collectionViewLayout` from `viewDidLoad`
     */
    
    JSQMessage *msg = [self.demoData.messages objectAtIndex:indexPath.item];
    
    if (!msg.isMediaMessage) {
        
        if ([msg.senderId isEqualToString:self.senderId]) {
            cell.textView.textColor = [UIColor whiteColor];
        }
        else {
            cell.textView.textColor = [UIColor blackColor];
        }
        
        cell.textView.linkTextAttributes = @{ NSForegroundColorAttributeName : cell.textView.textColor,
                                              NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle | NSUnderlinePatternSolid) };
    }
    
    return cell;
}



#pragma mark - UICollectionView Delegate

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    if (action == @selector(customAction:)) {
        return YES;
    }

    return [super collectionView:collectionView canPerformAction:action forItemAtIndexPath:indexPath withSender:sender];
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    if (action == @selector(customAction:)) {
        [self customAction:sender];
        return;
    }

    [super collectionView:collectionView performAction:action forItemAtIndexPath:indexPath withSender:sender];
}

- (void)customAction:(id)sender
{
    NSLog(@"Custom action received! Sender: %@", sender);
}

#pragma mark - JSQMessages collection view flow layout delegate

#pragma mark - Adjusting cell label heights

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  Each label in a cell has a `height` delegate method that corresponds to its text dataSource method
     */
    
    /**
     *  This logic should be consistent with what you return from `attributedTextForCellTopLabelAtIndexPath:`
     *  The other label height delegate methods should follow similarly
     *
     *  Show a timestamp for every 3rd message
     */
    if (indexPath.item % 3 == 0) {
        return kJSQMessagesCollectionViewCellLabelHeightDefault;
    }
    
    return 0.0f;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  iOS7-style sender name labels
     */
    JSQMessage *currentMessage = [self.demoData.messages objectAtIndex:indexPath.item];
    if ([[currentMessage senderId] isEqualToString:self.senderId]) {
        return 0.0f;
    }
    
    if (indexPath.item - 1 > 0) {
        JSQMessage *previousMessage = [self.demoData.messages objectAtIndex:indexPath.item - 1];
        if ([[previousMessage senderId] isEqualToString:[currentMessage senderId]]) {
            return 0.0f;
        }
    }
    
    return kJSQMessagesCollectionViewCellLabelHeightDefault;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
    return 0.0f;
}

#pragma mark - Responding to collection view tap events

- (void)collectionView:(JSQMessagesCollectionView *)collectionView
                header:(JSQMessagesLoadEarlierHeaderView *)headerView didTapLoadEarlierMessagesButton:(UIButton *)sender
{
    NSLog(@"Load earlier messages!");
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapAvatarImageView:(UIImageView *)avatarImageView atIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Tapped avatar!");
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapMessageBubbleAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Tapped message bubble!");
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapCellAtIndexPath:(NSIndexPath *)indexPath touchLocation:(CGPoint)touchLocation
{
    NSLog(@"Tapped cell at %@!", NSStringFromCGPoint(touchLocation));
}


- (BOOL)composerTextView:(JSQMessagesComposerTextView *)textView shouldPasteWithSender:(id)sender
{
    if ([UIPasteboard generalPasteboard].image) {
        // If there's an image in the pasteboard, construct a media item with that image and `send` it.
        JSQPhotoMediaItem *item = [[JSQPhotoMediaItem alloc] initWithImage:[UIPasteboard generalPasteboard].image];
        JSQMessage *message = [[JSQMessage alloc] initWithSenderId:self.senderId
                                                 senderDisplayName:self.senderDisplayName
                                                              date:[NSDate date]
                                                             media:item];
        [self.demoData.messages addObject:message];
        [self finishSendingMessage];
        return NO;
    }
    return YES;
}


@end
