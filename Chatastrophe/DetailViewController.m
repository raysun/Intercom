//
//  DetailViewController.m
//  Chatastrophe
//
//  Created by Karen and Ray Sun on 1/6/16.
//  Copyright © 2016 Ray Sun. All rights reserved.
//

#import "DetailViewController.h"
#import "AppDelegate.h"
@import Social;

@interface DetailViewController () {
    AppDelegate *appDelegate;
    NSMutableDictionary *payload;
    NSString *playerID;
    NSMutableArray *deviceList;
    NSString *title;
    
}

@end

@implementation DetailViewController

#pragma mark - Managing the detail item

- (void)setDetailItem:(id)newDetailItem {
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
    
        
        appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        
        NSArray *item = (NSArray *)_detailItem;
        if ([item[0] intValue] == 0) {
            NSMutableArray *deviceIDs = [NSMutableArray new];
            for (NSDictionary *device in deviceList) {
                [deviceIDs addObject:device[@"deviceID"]];
            }
            payload = [NSMutableDictionary dictionaryWithDictionary:@{@"include_player_ids":deviceIDs}];
            title = @"All devices";
        } else {
            playerID = [deviceList[[item[1] intValue]] valueForKey:@"deviceID"];
            payload = [NSMutableDictionary dictionaryWithDictionary:@{@"include_player_ids":[NSArray arrayWithObject:playerID]}];
            title = [deviceList[[item[1] intValue]] valueForKey:@"deviceName"];
        }


        // Update the view.
        [self configureView];
    }
}

- (void)configureView {
    // Update the user interface for the detail item.
    if (self.detailItem) {
        self.title = title;
        // self.detailDescriptionLabel.text = title;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(composeMessage)];
    self.navigationItem.rightBarButtonItem = addButton;

    [self configureView];
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
