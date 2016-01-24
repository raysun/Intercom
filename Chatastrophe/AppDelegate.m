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

@interface AppDelegate () <UISplitViewControllerDelegate> {
    CKDatabase *publicDB;
    NSUbiquitousKeyValueStore *store;
}

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
    UINavigationController *navigationController = [splitViewController.viewControllers lastObject];
    navigationController.topViewController.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem;
    splitViewController.delegate = self;
    
    // Get the device's name to use in the UI on other devices
    self.myName = [[UIDevice currentDevice] name];
    self.myID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    
    self.myDevice = @{@"deviceID":self.myID,
                      @"deviceName":self.myName
                    };
    
    // set up onesignal for APNS
    self.oneSignal = [[OneSignal alloc]
                      initWithLaunchOptions:launchOptions
                      appId:@"ffbc7659-7cd4-4a71-ad91-1c2d31beefa6"
                      handleNotification:^(NSString* message, NSDictionary* additionalData, BOOL isActive) {
                          NSLog(@"OneSignal Notification opened:\nMessage: %@", message);
                          
                          if (additionalData) {
                              NSLog(@"additionalData: %@", additionalData);
                              
                              // Check for and read any custom values you added to the notification
                              // This done with the "Additonal Data" section the dashbaord.
                              // OR setting the 'data' field on our REST API.
                          }
                          
                      }];

    // local messages array init
    self.allMessages = [NSMutableDictionary new];

    // Make sure user is signed in to iCloud before using CloudKit
    [[CKContainer defaultContainer] accountStatusWithCompletionHandler:^(CKAccountStatus accountStatus, NSError *error) {
        if (accountStatus == CKAccountStatusNoAccount) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Sign in to iCloud"
                                                                           message:@"Intercom requires iCloud Drive. Please enable it by..."
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                      style:UIAlertActionStyleCancel
                                                    handler:nil]];
  
            //BUGBUG: not sure which viewcontroller is alive at this point to present the UI. Maybe this check needs to be somewhere else, like in a new custom class for the uisplitviewcontroller
//            [self.window makeKeyAndVisible];
//            [splitViewController presentViewController:alert animated:YES completion:nil];
            
        }
        else {
            // Insert your just-in-time schema code here
        }
    }];
    
    // CloudKit Public Database
    publicDB = [[CKContainer defaultContainer] publicCloudDatabase];
    
    // Register for CloudKit push notifications (based on the subscription server queries)
    UIUserNotificationSettings *notificationSettings = [UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeAlert, UIUserNotificationTypeBadge, UIUserNotificationTypeSound) categories:nil];
    [application registerUserNotificationSettings:notificationSettings];
    [application registerForRemoteNotifications];
    
    store = [NSUbiquitousKeyValueStore defaultStore];
    NSUserDefaults *localStore = [NSUserDefaults standardUserDefaults];

    // RESET APP - uncomment next line
//        [store removeObjectForKey:@"deviceList"];
    
    // DeviceList is completely empty for this user; create it
    if (![store arrayForKey:@"deviceList"]) {
        [store setArray:[NSMutableArray new] forKey:@"deviceList"];
    }

    [[NSNotificationCenter defaultCenter]
     addObserver: self
     selector: @selector (updateKVStoreItems:)
     name: NSUbiquitousKeyValueStoreDidChangeExternallyNotification
     object: [NSUbiquitousKeyValueStore defaultStore]];
    [store synchronize];
    NSLog(@"Cloud store: %@",[store objectForKey:@"deviceList"]);
    
    [localStore setObject:[store objectForKey:@"deviceList"] forKey:@"deviceList"];
    self.deviceList = [localStore objectForKey:@"deviceList"];
    NSLog(@"Local store: %@",[localStore objectForKey:@"deviceList"]);

    // RESET SUBSCRIPTIONS
//    [self resetSubscriptions];
    // Set up CloudKit server queries (subscriptions) - only needs to be run once
//    [self createCloudKitSubscriptions];

    // Add this device if it's new
    if (![[localStore objectForKey:@"deviceList"] containsObject:self.myDevice]) {
        self.deviceList = [self.deviceList arrayByAddingObjectsFromArray:@[self.myDevice]];
        [localStore setObject:self.deviceList forKey:@"deviceList"];
        [store setObject:self.deviceList forKey:@"deviceList"];
        [localStore synchronize];
        [store synchronize];
    }
    NSLog(@"Startup device list: %@",self.deviceList);
    
    // Register my OneSignalID with the deviceList
    [self.oneSignal IdsAvailable:^(NSString* userId, NSString* pushToken) {
        



        
//    MyObject *object10 = myArray[indexOfObject10];
    }];
    
    // Load messages (BUGBUG: really shouldn't reload the whole dang database from CloudKit, just new messages, but I don't have the local store yet
    for (NSDictionary *device in self.deviceList) {
        NSString *deviceID = device[@"deviceID"];
        DemoModelData *demoModelData = [DemoModelData new];
        [self.allMessages setValue:demoModelData forKey:deviceID];
    }
    [self.allMessages setValue:[DemoModelData new] forKey:@"All"];

    CKQuery *query = [[CKQuery alloc] initWithRecordType:@"Message" predicate:[NSPredicate predicateWithValue:YES]];
    query.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"Date" ascending:false]];
    [self performQuery:query];

    /*
    [self.allMessages setValue:[DemoModelData new] forKey:@"All"];
    CKQuery *query = [[CKQuery alloc] initWithRecordType:@"Message" predicate:[NSPredicate predicateWithFormat:@"To = 'All'"]];
    query.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"Date" ascending:false]];
    [self performQuery:query];
    for (device in self.deviceList) {
        NSString *deviceID = device[@"deviceID"];
        DemoModelData *demoModelData = [DemoModelData new];
        [self.allMessages setValue:demoModelData forKey:deviceID];
        query = [[CKQuery alloc] initWithRecordType:@"Message" predicate:[NSPredicate predicateWithFormat:@"To = %@",deviceID]];
        query.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"Date" ascending:false]];
        [self performQuery:query];
    } */
    
    return YES;
}

#pragma mark - Callback after registering for CloudKit notifications - now that cloudkit is ready, we load messages

- (void)application:(UIApplication *)application
didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
// TODO: handle case where user has disabled (or not accepted) notifications
}

- (void)performQuery:(CKQuery *)query {
    [publicDB performQuery:query inZoneWithID:nil completionHandler:^(NSArray *results, NSError *error) {
        for (CKRecord *record in results) {
            [self saveRecordToLocalMessages:record];
        }
    }];
    
}

#pragma mark - Received new message notification from CloudKit

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(nonnull NSDictionary *)userInfo fetchCompletionHandler:(nonnull void (^)(UIBackgroundFetchResult))completionHandler {
    
    CKQueryNotification *cloudKitNotification = (CKQueryNotification *)[CKNotification notificationFromRemoteNotificationDictionary:userInfo];
//    NSString *alertBody = cloudKitNotification.alertBody;
//    NSLog(@"Awake - even in background");
    
    if (cloudKitNotification.notificationType == CKNotificationTypeQuery) {
        CKRecordID *recordID = [cloudKitNotification recordID];
        [publicDB fetchRecordWithID:recordID completionHandler:^(CKRecord * _Nullable record, NSError * _Nullable error) {
//            NSLog(@"CloudKit Notification %@",record);

            NSLog(@"Body is %@",[record valueForKey:@"Body"]);
            NSLog(@"FromFriendlyName is %@", cloudKitNotification.recordFields[@"FromFriendlyName"]);
            
//            NSDictionary *apsDict = [userInfo objectForKey:@"aps"];
//            NSString *alertText = [apsDict objectForKey:@"alert"];
            
//            if(application.applicationState == UIApplicationStateActive) {
//                UIAlertView * alert = [[UIAlertView alloc] initWithTitle:cloudKitNotification.recordFields[@"From"] message:alertBody delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil];
//                [alert show];
//            } else {
//                    if ([application currentUserNotificationSettings].types & UIUserNotificationTypeBadge) {
            /*
                        UILocalNotification * localNotification = [[UILocalNotification alloc] init];
                        localNotification.alertTitle = cloudKitNotification.recordFields[@"FromFriendlyName"];
//                        localNotification.alertBody = alertText;
                        localNotification.alertBody = [record valueForKey:@"Body"];
                        [application presentLocalNotificationNow:localNotification];
                        NSLog(@"Local Notification %@",localNotification);
             */
//                }
//            }
            
            [self saveRecordToLocalMessages:record];
            
            // Tell message view controller to refresh views
            [self notifyNewMessageArrived];
        
        }];
    }
    completionHandler(UIBackgroundFetchResultNewData);
}

- (void)notifyNewMessageArrived
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"NewMessages" object:nil userInfo:nil];
}

- (void)notifyNewDevice
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"NewDevice" object:nil userInfo:nil];
}

- (void)saveRecordToLocalMessages:(CKRecord *)record {
    NSString *from = [record objectForKey:@"From"];
    NSString *fromFriendlyName = [record objectForKey:@"FromFriendlyName"];
    NSString *to = [record objectForKey:@"To"];
    NSString *body = [record objectForKey:@"Body"];
    NSDate *date = [record objectForKey:@"Date"];
    if (!fromFriendlyName) fromFriendlyName = @"iPhone";
    
    JSQMessage *message = [[JSQMessage alloc] initWithSenderId:from senderDisplayName:fromFriendlyName date:date text:body];
    
    // Messages to ALL always go to ALL. Then messages NOT FROM ME go to OTHERS' mailboxes. Then messages from ME TO OTHERS go to OTHERS.
    if ([to isEqualToString:@"All"]) {
        [((DemoModelData*) self.allMessages[@"All"]) add:message];
    } else if (![from isEqualToString:self.myID]) {
        [((DemoModelData*) self.allMessages[from]) add:message];
    } else {
        [((DemoModelData*) self.allMessages[to]) add:message];
    }
    
}

#pragma mark - Set up CloudKit subscriptions (only need to be called once in app lifetime)

// Listen for changes to CloudKit objects (message and device)
- (void)createCloudKitSubscriptions {

    /* BUGBUG - hack - i'm not checking for user right now, so all push notifications will go to all devices. 
     MUST BE FIXED before going to production - user's devicelist count is 0, then set up ALL query. */
//    if (self.deviceList.count == 0) {
        NSPredicate *predicate = [NSPredicate predicateWithValue:YES];
        [self addSubscriptionForPredicate:predicate];
//    }
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
        /*
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

- (void)addSubscriptionForPredicate:(NSPredicate *)predicate {
    CKNotificationInfo *info = [CKNotificationInfo new];
    info.shouldBadge = YES;
    info.shouldSendContentAvailable = YES;
//    info.alertBody = @"";
    /*
    info.alertLocalizationKey = @"%@: %@";
    info.alertLocalizationArgs = @[
                                   @"FromFriendlyName",
                                   @"Body"
                                   ];
     */
    info.desiredKeys = @[@"FromFriendlyName"];
    
    CKSubscription *subscription = [[CKSubscription alloc] initWithRecordType:@"Message" predicate:predicate options:CKSubscriptionOptionsFiresOnRecordCreation];
    subscription.notificationInfo = info;
    
    [publicDB saveSubscription:subscription
             completionHandler:^(CKSubscription *subscription, NSError *error) {
                 if (error) NSLog(@"ERROR: %@\nwhen subscribing to:%@",error,predicate) else
                     NSLog(@"CloudKit subscription saved %@",subscription);
             }];
    
}

- (void)resetSubscriptions {
    [publicDB fetchAllSubscriptionsWithCompletionHandler:^(NSArray<CKSubscription *> * _Nullable subscriptions, NSError * _Nullable error) {
//        [[CKModifySubscriptionsOperation alloc] initWithSubscriptionsToSave:nil subscriptionIDsToDelete:subscriptions];
        NSLog(@"All current subscriptions: %@",subscriptions);
        for (CKSubscription *subscription in subscriptions) {
            [publicDB deleteSubscriptionWithID:subscription.subscriptionID completionHandler:^(NSString * _Nullable subscriptionID, NSError * _Nullable error) {
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
        [self notifyNewDevice];
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

@end
