//
//  AppDelegate.m
//  Chatastrophe
//
//  Created by Karen and Ray Sun on 1/6/16.
//  Copyright © 2016 Ray Sun. All rights reserved.
//

#import "AppDelegate.h"
#import "MessagesViewController.h"
#import "JSQMessage.h"
@import CloudKit;
#import "APLCloudManager.h"
@import AudioToolbox;

@interface AppDelegate () <UISplitViewControllerDelegate> {
    CKContainer *container;
    CKDatabase *privateDB;
    NSUbiquitousKeyValueStore *store;
    NSUserDefaults *localStore;
    NSArray *notificationSoundFileNames;
    UIAlertController *alert;
    SystemSoundID inAppSound;
}

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    /* Don't need this, unless I go back to the master/detail UI
    // Override point for customization after application launch.
//    UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
 //   UINavigationController *navigationController = [splitViewController.viewControllers lastObject];
//    navigationController.topViewController.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem;
//    splitViewController.delegate = self;
     */
//    NSLog(@"App launching, notifications missed: %@",launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey]);
    
    self.atLeastOneMessageReceived = NO;
    
    // Get the device's name to use in the UI on other devices
    self.myName = [[UIDevice currentDevice] name];
    self.myID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];

    self.myDevice = @{@"deviceID":self.myID,
                      @"deviceName":self.myName
                    };
    self.emoticons = @[@"📚",@"😴",@"🍴",@"🏈",@"🚗",@"❤️"];
    
    // local messages array init
    self.allMessages = [NSMutableDictionary new];
    
    // Messages are per iCloud account
    container = [CKContainer containerWithIdentifier:@"iCloud.com.raysun.Intercom"];
    privateDB = [container privateCloudDatabase];
    
    /* TODO check for no iCloud account case - might be ok, though, you should just get the "no other account found" error
    // Make sure user is signed in to iCloud before using CloudKit
    [[CKContainer defaultContainer] accountStatusWithCompletionHandler:^(CKAccountStatus accountStatus, NSError *error) {
        if (accountStatus == CKAccountStatusNoAccount) {
                 [self notify:@"ShowWelcomeMessage"];

            alert = [UIAlertController alertControllerWithTitle:@"Mom Says requires iCloud"
                                                        message:@"Please enable your account in Settings."
                                                 preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                      style:UIAlertActionStyleCancel
                                                    handler:nil]];
            [self.window.rootViewController.navigationController presentViewController:alert animated:YES completion:nil];
        }
    }];
    */
    
    /* TODO: turning off unless I want to make the app multi-iCloud-friendly
    // Request making this iCloud account discoverable by other users. Other users still need my email address in their contacts.
    [[CKContainer defaultContainer] requestApplicationPermission:CKApplicationPermissionUserDiscoverability completionHandler:^(CKApplicationPermissionStatus applicationPermissionStatus, NSError * _Nullable error) {
        
    }];
     */
    
    /* Hack to create the schema just for testing, won't need in production */
    /*
    CKRecord *dbMessage = [[CKRecord alloc] initWithRecordType:@"Message"];
    dbMessage[@"From"] = @"Mom Says";  //mydeviceid
    dbMessage[@"FromFriendlyName"] = @"Mom Says";
    dbMessage[@"To"] = @"";
    dbMessage[@"ToFriendlyName"] = @"";
    dbMessage[@"Body"] = @"";
    dbMessage[@"Date"] = [NSDate date];
    dbMessage[@"Special"] = @"NO";
    
    [publicDB saveRecord:dbMessage completionHandler:^(CKRecord *savedPlace, NSError *error) {
        // handle errors here
        if (!error) {
            NSLog(@"Saved record %@",savedPlace);
        }
    }];
    [NSThread sleepForTimeInterval:10.0f];
    */
    
    // Register for CloudKit push notifications (based on the subscription server queries)
    UIMutableUserNotificationAction *notificationAction1 = [UIMutableUserNotificationAction new];
    notificationAction1.identifier = @"reply";
    notificationAction1.title = @"Send";
    notificationAction1.activationMode = UIUserNotificationActivationModeBackground;
    notificationAction1.destructive = NO;
    notificationAction1.authenticationRequired = NO;
    notificationAction1.behavior = UIUserNotificationActionBehaviorTextInput;
//    notificationAction1.parameters = @{UIUserNotificationTextInputActionButtonTitleKey:@"Yo"};
    
    UIMutableUserNotificationCategory *category = [UIMutableUserNotificationCategory new];
    category.identifier = @"category";
    [category setActions:@[notificationAction1] forContext:UIUserNotificationActionContextDefault];
    [category setActions:@[notificationAction1] forContext:UIUserNotificationActionContextMinimal];
    
    NSSet *categories = [NSSet setWithObjects:category, nil];
    
    UIUserNotificationSettings *notificationSettings = [UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeBadge | UIUserNotificationTypeSound) categories:categories];
    
    [application registerUserNotificationSettings:notificationSettings];
    [application registerForRemoteNotifications];
    
    store = [NSUbiquitousKeyValueStore defaultStore];
    localStore = [NSUserDefaults standardUserDefaults];
    
    if (![localStore valueForKey:@"unreadCount"]) [localStore setValue:0 forKey:@"unreadCount"];

    // RESET APP - uncomment next line
//    [store removeObjectForKey:@"deviceList"];
    
    // RESET SUBSCRIPTIONS
    // Can't be done in production - for development testing only
//    [self resetSubscriptions];
//    [NSThread sleepForTimeInterval: 20.0];
    
    // DeviceList is completely empty - first device for this user
    if (![store arrayForKey:@"deviceList"]) {
        [store setArray:[NSMutableArray new] forKey:@"deviceList"];
    }

    // BUGBUG: Should really be done only once per user, but iCloud fails sometimes so redoing it doesn't hurt. If it's a dupe, it doesn't cause any problems. Note that the Subscription Type is created upon CloudKit Dashboard deployment, but no actual subscriptions are created.
    [self createCloudKitSubscriptions];

    [[NSNotificationCenter defaultCenter]
     addObserver: self
     selector: @selector (updateKVStoreItems:)
     name: NSUbiquitousKeyValueStoreDidChangeExternallyNotification
     object: [NSUbiquitousKeyValueStore defaultStore]];
    [store synchronize];
//    NSLog(@"Cloud store: %@",[store objectForKey:@"deviceList"]);
    
    [localStore setObject:[store objectForKey:@"deviceList"] forKey:@"deviceList"];
    self.deviceList = [localStore objectForKey:@"deviceList"];
//    NSLog(@"Local store: %@",[localStore objectForKey:@"deviceList"]);
    
    // Add this device if it's new
    if (![[localStore objectForKey:@"deviceList"] containsObject:self.myDevice]) {
        self.deviceList = [self.deviceList arrayByAddingObjectsFromArray:@[self.myDevice]];
        [localStore setObject:self.deviceList forKey:@"deviceList"];
        [store setObject:self.deviceList forKey:@"deviceList"];
        [localStore synchronize];
        [store synchronize];
    }
    NSLog(@"Startup device list: %@",self.deviceList);
    
    // Load messages (BUGBUG: really shouldn't reload the whole dang database from CloudKit, just new messages, but I don't have the local store yet
    for (NSDictionary *device in self.deviceList) {
        NSString *deviceID = device[@"deviceID"];
        DemoModelData *demoModelData = [DemoModelData new];
        [self.allMessages setValue:demoModelData forKey:deviceID];
    }
    [self.allMessages setValue:[DemoModelData new] forKey:@"All"];
    self.messageIDs = [NSMutableArray new];

    CKQuery *query = [[CKQuery alloc] initWithRecordType:@"Message" predicate:[NSPredicate predicateWithValue:YES]];
    query.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"Date" ascending:true]];
    
    [self performQuery:query];
    
    return YES;
}

- (void)application:(UIApplication *)application
didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    // TODO: handle case where user has disabled (or not accepted) notifications
    NSLog(@"Notifications enabled: %@",[application currentUserNotificationSettings]);
}

// Load all messages
- (void)performQuery:(CKQuery *)query {
    // Special failsafe - lets me show a message on everyone's device by manually creating a public message - depending on the date of the message, I can show it at the top or at the end.
    CKDatabase *db = [container publicCloudDatabase];
    [db performQuery:query inZoneWithID:nil completionHandler:^(NSArray *results, NSError *error) {
        for (CKRecord *record in results) {
            [self saveRecordToLocalMessages:record];
            NSLog(@"public message %@",record);
            [self notify:@"AllMessagesDownloadedFromCloud"];
        }
    }];
    
    [privateDB performQuery:query inZoneWithID:nil completionHandler:^(NSArray *results, NSError *error) {
        for (CKRecord *record in results) {
            [self saveRecordToLocalMessages:record];
        }
        NSLog(@"Query finished, messages loaded");
        [self notify:@"AllMessagesDownloadedFromCloud"];
        /* If I want to show a welcome message when there are no messages. Instead showing error if there are no other devices when you send.
        if (results.count > 0) {
            [self notify:@"AllMessagesDownloadedFromCloud"];
        } else {
            [self notify:@"ShowWelcomeMessage"];
        }
         */

    }];
}

#pragma mark - Received new message notification from CloudKit

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(nonnull NSDictionary *)userInfo fetchCompletionHandler:(nonnull void (^)(UIBackgroundFetchResult))completionHandler {
    
//    application.applicationIconBadgeNumber = 0;

    CKQueryNotification *cloudKitNotification = (CKQueryNotification *)[CKNotification notificationFromRemoteNotificationDictionary:userInfo];
    
    UIApplicationState appState = [[UIApplication sharedApplication] applicationState];
    NSLog(@"Notification received, appstate = %ld",(long)appState);
    
    // Must check for UIAppStateInactive - means user tapped on notification, and we need to not save the message twice - it was saved in background already
    if (cloudKitNotification.notificationType == CKNotificationTypeQuery && appState != UIApplicationStateInactive) {
        self.atLeastOneMessageReceived = YES;
        NSInteger unreadCount = [[localStore valueForKey:@"unreadCount"] integerValue];
        unreadCount++;
        if (appState == UIApplicationStateActive) {
            unreadCount = 0;
        }
        [localStore setValue:[NSString stringWithFormat:@"%ld",unreadCount] forKey:@"unreadCount"];
        [localStore synchronize];
        application.applicationIconBadgeNumber = unreadCount;
        NSLog(@"received Cloud notification ID: %@",cloudKitNotification);
        
        CKRecordID *recordID = [cloudKitNotification recordID];
        [privateDB fetchRecordWithID:recordID completionHandler:^(CKRecord * _Nullable record, NSError * _Nullable error) {
            
            NSString *body = [record valueForKey:@"Body"];
            NSLog(@"Body is %@",body);
//            NSLog(@"FromFriendlyName is %@", cloudKitNotification.recordFields[@"FromFriendlyName"]);
            
            if (appState == UIApplicationStateActive) {
                NSUInteger i = [self.emoticons indexOfObject:body];
                if (i != NSNotFound) {
                    //playsound
                    NSString *soundFileName = [NSString stringWithFormat:@"Text to Speech %ld",i+1];
                    NSString *soundFilePath = [[NSBundle mainBundle]
                                               pathForResource:soundFileName ofType:@"wav"];
                    NSURL *soundURL = [NSURL fileURLWithPath:soundFilePath];
                    AudioServicesCreateSystemSoundID((__bridge CFURLRef)soundURL, &inAppSound);
                    AudioServicesPlaySystemSound(inAppSound);
                }
            }
            
            [self saveRecordToLocalMessages:record];
            
            // Tell message view controller to refresh views
            [self notify:@"NewMessages"];
            
        }];
    }

    if (completionHandler != nil) completionHandler(UIBackgroundFetchResultNewData);
}

// didReceiveRemoteNotification will be called as usual, but in addition this is called if the quick reply is used
- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo withResponseInfo:(nonnull NSDictionary *)responseInfo completionHandler:(nonnull void (^)())completionHandler {

    CKQueryNotification *cloudKitNotification = (CKQueryNotification *)[CKNotification notificationFromRemoteNotificationDictionary:userInfo];
    
    if (cloudKitNotification.notificationType == CKNotificationTypeQuery && [cloudKitNotification.category isEqualToString:@"category"] && [identifier isEqualToString:@"reply"]) {

        NSString *text = responseInfo[UIUserNotificationActionResponseTypedTextKey];
        NSDictionary *textDictionary = @{@"Body":text};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ActionSend" object:nil userInfo:textDictionary];
    }
    
    if(completionHandler != nil)
        completionHandler(UIBackgroundFetchResultNewData);

}

- (void)application:(UIApplication *)application performActionForShortcutItem:(nonnull UIApplicationShortcutItem *)shortcutItem completionHandler:(nonnull void (^)(BOOL))completionHandler {
    
    NSDictionary *textDictionary = @{@"EmoticonIndex":shortcutItem.type};
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ActionSend" object:nil userInfo:textDictionary];
    
    if (completionHandler != nil) completionHandler(UIBackgroundFetchResultNewData);
}

- (void)notify:(NSString *)notificationName {
    [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil userInfo:nil];
}

- (void)saveRecordToLocalMessages:(CKRecord *)record {
    CKRecordID *recordID = record.recordID;
    NSString *from = [record objectForKey:@"From"];
    NSString *fromFriendlyName = [record objectForKey:@"FromFriendlyName"];
    NSString *to = [record objectForKey:@"To"];
    NSString *body = [record objectForKey:@"Body"];
    NSDate *date = [record objectForKey:@"Date"];
    CKAsset *imageAsset = [record objectForKey:@"Image"];
    UIImage *image = [UIImage imageWithContentsOfFile:imageAsset.fileURL.path];
    if (!fromFriendlyName) fromFriendlyName = @"Unknown name";
    
    // BUGBUG: logging recordIDs that map 1-1 with the index in the message view. Very hacky way to do this; should be storing in overridden JSQMessage object
    [self.messageIDs addObject:recordID];
    
    JSQMessage *message;
    if (image) {
        message = [[JSQMessage alloc] initWithSenderId:from senderDisplayName:fromFriendlyName date:date media:[[JSQPhotoMediaItem alloc] initWithImage:image]];
//        NSLog(@"%@",message);
    } else {
        message = [[JSQMessage alloc] initWithSenderId:from senderDisplayName:fromFriendlyName date:date text:body];
    }
    
    // Messages to ALL always go to ALL. Then messages NOT FROM ME go to OTHERS' mailboxes. Then messages from ME TO OTHERS go to OTHERS.
    if ([to isEqualToString:@"All"]) {
        [((DemoModelData*) self.allMessages[@"All"]) add:message];
    } else if (![from isEqualToString:self.myID]) {
        [((DemoModelData*) self.allMessages[from]) add:message];
    } else {
        [((DemoModelData*) self.allMessages[to]) add:message];
    }
    
    /* TODO: Later, if we want to implement per-user, can utilize this part of APLCloudManager
    // we provide the owner of the current record in the subtite of our cell
    APLCloudManager *cloudManager = [APLCloudManager new];
    [cloudManager fetchUserNameFromRecordID:record.creatorUserRecordID completionHandler:^(NSString *firstName, NSString *lastName) {
        NSLog(@"%@, %@",firstName,lastName);
        if (firstName == nil && lastName == nil)
        {
//            self.createdByLabel.text = [NSString stringWithFormat:@"%@", NSLocalizedString(@"Unknown User Name", nil)];
        }
        else
        {
  //          self.createdByLabel.text = [NSString stringWithFormat:@"%@", [NSString stringWithFormat:@"%@ %@", firstName, lastName]];
        }
    }];
    */
    
}

#pragma mark - Set up CloudKit subscriptions (only called once in development)

// Listen for changes to CloudKit objects (message and device)
- (void)createCloudKitSubscriptions {

    /* BUGBUG - hack - i'm not checking for user right now, so all push notifications will go to all devices. 
     MUST BE FIXED before going to production - user's devicelist count is 0, then set up ALL query. */
//    if (self.deviceList.count == 0) {
//        NSPredicate *predicate = [NSPredicate predicateWithValue:YES];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"Special = 'NO'"];
    CKNotificationInfo *info = [self createNotificationInfoWithSound:nil];
    [self addSubscriptionForPredicate:predicate andInfo:info];
    
    NSUInteger soundNumber = 1;
    for (NSString *emoticon in self.emoticons) {
        predicate = [NSPredicate predicateWithFormat:@"Special = %@",emoticon];
        info = [self createNotificationInfoWithSound:[NSString stringWithFormat:@"Text to Speech %ld.wav",soundNumber]];
        [self addSubscriptionForPredicate:predicate andInfo:info];
        
        soundNumber++;
    }
    
    

    /*
    // Create the Notification to ALL and to ME, but do not duplicate else cloudkit will send multiple notifications
    [publicDB fetchAllSubscriptionsWithCompletionHandler:^(NSArray<CKSubscription *> * _Nullable subscriptions, NSError * _Nullable error) {
    
        NSPredicate *predicateAll = [NSPredicate predicateWithFormat:@"To = 'All'"];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"To = %@",self.myID];
    
        // If there are no subscriptions BUGBUG:FOR THIS USER, add the All query
        if (self.deviceList.count == 0) [self addSubscriptionForPredicate:predicateAll];
    
        // If the current device is not in the devicelist, add the predicate for ME
        if (![self.deviceList containsObject:self.myDevice]) {
            [self addSubscriptionForPredicate:predicate];
        }

        // TODO: Fix the hacky check above with a real check for the actual predicates.

        NSUInteger i = [subscriptions indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            return ([[(CKSubscription *)obj predicate] isEqual:predicateAll]);

        }];
        NSLog(@"%lu",(unsigned long)i);
        i = [subscriptions indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            return ([[(CKSubscription *)obj predicate] isEqual:predicate]);
        }];
        NSLog(@"%lu",(unsigned long)i);
         */

}

#pragma mark - Define Notification content for subscription

- (CKNotificationInfo *)createNotificationInfoWithSound:(NSString *)soundName {
    CKNotificationInfo *info = [CKNotificationInfo new];
//    info.shouldBadge = YES;
    info.shouldSendContentAvailable = YES;
    info.alertBody = @" ";
    info.soundName = soundName ? soundName : UILocalNotificationDefaultSoundName;
    //    info.soundName = UILocalNotificationDefaultSoundName;
    /* BUGBUG: Temporarily disabling the From field
     info.alertLocalizationKey = @"%@: %@";
     info.alertLocalizationArgs = @[
     @"FromFriendlyName",
     @"Body"
     ];
     */
    
    info.alertLocalizationKey = @"%@";
    info.alertLocalizationArgs = @[
                                   @"Body"
                                   ];
    info.category = @"category";
    info.alertActionLocalizationKey = @"Send";
//    info.desiredKeys = @[@"FromFriendlyName"];
    
    return info;
}

- (void)addSubscriptionForPredicate:(NSPredicate *)predicate andInfo:(CKNotificationInfo*)info {
    CKSubscription *subscription = [[CKSubscription alloc] initWithRecordType:@"Message" predicate:predicate options:CKSubscriptionOptionsFiresOnRecordCreation];
    subscription.notificationInfo = info;
    
    [privateDB saveSubscription:subscription
             completionHandler:^(CKSubscription *subscription, NSError *error) {
                 if (error) NSLog(@"ERROR: %@\nwhen subscribing to:%@",error,predicate) else
                     NSLog(@"CloudKit subscription saved %@",subscription);
             }];
    
}

- (void)resetSubscriptions {
    [privateDB fetchAllSubscriptionsWithCompletionHandler:^(NSArray<CKSubscription *> * _Nullable subscriptions, NSError * _Nullable error) {
//        [[CKModifySubscriptionsOperation alloc] initWithSubscriptionsToSave:nil subscriptionIDsToDelete:subscriptions];
        NSLog(@"All current subscriptions: %@",subscriptions);
        for (CKSubscription *subscription in subscriptions) {
            [privateDB deleteSubscriptionWithID:subscription.subscriptionID completionHandler:^(NSString * _Nullable subscriptionID, NSError * _Nullable error) {
                //
            }];
        }
    }];

}


- (void)updateKVStoreItems:(NSNotification*)notification {
    // Get the list of keys that changed.
    NSDictionary* userInfo = [notification userInfo];
    NSNumber* reasonForChange = [userInfo objectForKey:NSUbiquitousKeyValueStoreChangeReasonKey];
    NSInteger reason = -1;
    
    // If a reason could not be determined, do not update anything.
    if (!reasonForChange)
        return;
    
    // Update only for changes from the server.
    reason = [reasonForChange integerValue];
    if ((reason == NSUbiquitousKeyValueStoreServerChange) ||
        (reason == NSUbiquitousKeyValueStoreInitialSyncChange)) {
        // If something is changing externally, get the changes
        // and update the corresponding keys locally.
        NSArray* changedKeys = [userInfo objectForKey:NSUbiquitousKeyValueStoreChangedKeysKey];
        //        NSUbiquitousKeyValueStore* store = [NSUbiquitousKeyValueStore defaultStore];
        NSLog(@"Changed Keys %@", changedKeys);
        NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
        
        // This loop assumes you are using the same key names in both
        // the user defaults database and the iCloud key-value store
        for (NSString* key in changedKeys) {
            NSMutableArray *value = (NSMutableArray *)[store objectForKey:key];
            [userDefaults setObject:value forKey:key];
            self.deviceList = value;
        }
        [self notify:@"NewDevice"];
        NSLog(@"Cloud KV store update notification: %@",self.deviceList);
    }
}









#pragma mark - IGNORE - Boilerplate below

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.

    // When app opens, mark unread count back to 0
    application.applicationIconBadgeNumber = 0;
    [localStore setValue:0 forKey:@"unreadCount"];
    [localStore synchronize];
    
    /* This used to clear the cloud's badge - no need anymore, doing on client like I should have done.
    CKModifyBadgeOperation *clearBadge = [[CKModifyBadgeOperation alloc] initWithBadgeValue:0];
    [clearBadge setModifyBadgeCompletionBlock:^(NSError *error) {
        if (error) {
            NSLog(@"Set Cloud Badge Error: %@", error);
        } else {
            NSLog(@"Cloud Badge Cleared");
        }
    }];
    [container addOperation:clearBadge];

     */
    /*
    [self.notificationIDs removeAllObjects];
    CKFetchNotificationChangesOperation *fetchNotificationOperation = [CKFetchNotificationChangesOperation new];
    [fetchNotificationOperation setFetchNotificationChangesCompletionBlock:^(CKServerChangeToken *token, NSError *error) {
        if (error) {
            NSLog(@"Fetch Notifications Read Error: %@", error);
        } else {
//            NSLog(@"Fetch Notifications Read OK - count: %ld", .count);
        }
    }];
    fetchNotificationOperation.notificationChangedBlock = ^(CKNotification *notification){
        [self.notificationIDs addObject:notification.notificationID];

        NSLog(@"fetched %@",notification.notificationID);
                NSLog(@"of type %ld",notification.notificationType);
    };

    CKMarkNotificationsReadOperation *markReadOperation = [[CKMarkNotificationsReadOperation alloc] initWithNotificationIDsToMarkRead:(NSArray *)self.notificationIDs];
    [markReadOperation setMarkNotificationsReadCompletionBlock:^(NSArray<CKNotificationID *> *ids, NSError *error) {
        if (error) {
            NSLog(@"Mark Notifications Read Error: %@", error);
        } else {
            NSLog(@"Mark Notifications Read OK - count: %ld", ids.count);
            [self.notificationIDs removeAllObjects];
        }
    }];


    [(CKOperation *)markReadOperation setContainer:container];
    [(CKOperation *)fetchNotificationOperation setContainer:container];
    [markReadOperation addDependency:fetchNotificationOperation];
    
    NSOperationQueue *queue = [NSOperationQueue new];
    [queue addOperations:@[fetchNotificationOperation, markReadOperation] waitUntilFinished:YES];


//    [container   :@[fetchNotificationOperation, markReadOperation]];
*/

    


//    [privateDB addOperation:clearBadge];
//    [[[CKContainer defaultContainer] publicCloudDatabase] addOperation:clearBadge];
    
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - Split view

- (BOOL)splitViewController:(UISplitViewController *)splitViewController collapseSecondaryViewController:(UIViewController *)secondaryViewController ontoPrimaryViewController:(UIViewController *)primaryViewController {
    
     if ([secondaryViewController isKindOfClass:[UINavigationController class]] && [[(UINavigationController *)secondaryViewController topViewController] isKindOfClass:[MessagesViewController class]] && ([(MessagesViewController *)[(UINavigationController *)secondaryViewController topViewController] selectedIndex] == nil)) {
     // Return YES to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
     return YES;
     } else {
     return NO;
     }
 
//    return YES;
}

// Check icon from Baby Chick Image Illustration of a ...clipartsheep.com

@end
