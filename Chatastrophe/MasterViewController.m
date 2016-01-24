//
//  MasterViewController.m
//  Chatastrophe
//
//  Created by Karen and Ray Sun on 1/6/16.
//  Copyright © 2016 Ray Sun. All rights reserved.
//

#import "AppDelegate.h"
#import "MasterViewController.h"
#import "MessagesViewController.h"
#import "DemoModelData.h"

@interface MasterViewController () {
    AppDelegate *appDelegate;
}

- (void)useNotificationWithString:(NSNotification*)notification;

@property NSArray *objects;

@end

@implementation MasterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Format the title
    NSMutableDictionary *titleBarAttributes = [NSMutableDictionary dictionaryWithDictionary: [[UINavigationBar appearance] titleTextAttributes]];
    [titleBarAttributes setValue:[UIFont fontWithName:@"Avenir Next" size:20] forKey:NSFontAttributeName];
    [[UINavigationBar appearance] setTitleTextAttributes:titleBarAttributes];
    self.title = @"Intercom";
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(useNotificationWithString:)
     name:@"NewDevices"
     object:nil];

    appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
//    deviceList = appDelegate.deviceList;
//    self.objects = [[NSMutableArray alloc] initWithArray:deviceList];
    self.objects = appDelegate.deviceList;

}

- (void)useNotificationWithString:(NSNotification *)notification {
    [self.tableView reloadData];
}

-(void) didTapOnTableView:(UIGestureRecognizer*) recognizer {
    /*
    CGPoint swipeLocation = [recognizer locationInView:self.tableView];
    NSIndexPath *swipedIndexPath = [self.tableView indexPathForRowAtPoint:swipeLocation];
//    UITableViewCell *swipedCell = [self.tableView cellForRowAtIndexPath:swipedIndexPath];
    */

}

- (void)viewWillAppear:(BOOL)animated {
    self.clearsSelectionOnViewWillAppear = self.splitViewController.isCollapsed;
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
- (void)insertNewObject:(id)sender {
    if (!self.objects) {
        self.objects = [[NSMutableArray alloc] init];
    }
    [self.objects insertObject:[NSDate date] atIndex:0];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}
 */

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        MessagesViewController *controller = (MessagesViewController *)[[segue destinationViewController] topViewController];
        
//        [controller.collectionView reloadData];
        // passes the section and row
        controller.selectedIndex = indexPath;
//        [controller setDetailItem:@[@(indexPath.section), @(indexPath.row)]];
        controller.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
        controller.navigationItem.leftItemsSupplementBackButton = YES;
    }
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (section == 0 ? 1 : self.objects.count);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];

    if (indexPath.section == 0 && indexPath.row == 0) {
        cell.textLabel.text = @"All devices";
        cell.imageView.image = [UIImage imageNamed:@"alldevices"];
    } else {
        NSDictionary *object = self.objects[indexPath.row];
        NSString *deviceName = object[@"deviceName"];
        cell.textLabel.text = deviceName;
        // BUGBUG: need to store & check the actual device type not the friendly name
        if ([deviceName containsString:@"iPad"]) {
            cell.imageView.image = [UIImage imageNamed:@"ipad"];
        } else {
            cell.imageView.image = [UIImage imageNamed:@"iphone"];
        }
    }
    return cell;
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
//    return YES;
    return NO;
}

/*
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.objects removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}
 */

@end
