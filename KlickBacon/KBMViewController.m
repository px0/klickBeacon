//
//  KBMViewController.m
//  KlickBacon
//
//  Created by Maximilian Gerlach on 3/29/2014.
//  Copyright (c) 2014 Klick. All rights reserved.
//

#import "KBMViewController.h"
#import "KBMWebViewViewController.h"
#import "BCMBeaconManager.h"
#include "AFNetworking.h"
#include "CLBeacon+equal.h"

@interface KBMViewController ()
@property (strong, nonatomic) NSURL *url;
@property (strong, nonatomic) NSUUID *uuid;
@property (strong, nonatomic) NSString *serverip;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLBeaconRegion *region;
@property (strong, nonatomic) KBMWebViewViewController *vc;
@property (strong, nonatomic) CLBeacon *currentBeacon;
@property BOOL currentlyPresenting;
@end

@implementation KBMViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	self.currentlyPresenting = NO;
	
        // Get user preference
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.uuid = [[NSUUID alloc] initWithUUIDString:[defaults objectForKey:@"uuid"]];
    self.serverip = [defaults objectForKey:@"serverip"];

	self.region = [[CLBeaconRegion alloc] initWithProximityUUID:self.uuid identifier:@"TestBeacon"];
	self.region.notifyEntryStateOnDisplay = YES;
	
	// Initialize location manager and set ourselves as the delegate
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    
	// Tell location manager to start monitoring for the beacon region
    [self.locationManager startMonitoringForRegion:self.region];
	[self.locationManager requestStateForRegion:self.region];
    [self.locationManager startRangingBeaconsInRegion:self.region];
	
	[self mlog:(@"starting monitoring")];
}


- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error
{
	[self mlog:[NSString stringWithFormat:@"Error: %@", error]];
}

- (void)locationManager:(CLLocationManager*)manager didEnterRegion:(CLRegion*)region
{
    [self mlog:@"enter region!!!"];
}

-(void)locationManager:(CLLocationManager*)manager didExitRegion:(CLRegion*)region
{

    [self mlog:(@"exit region!!!")];
}

- (void) openURL: (NSString *)urlString {
    self.url = [NSURL URLWithString:urlString];
	[self mlog:[NSString stringWithFormat:@"opening url: %@", urlString]];
    [self performSegueWithIdentifier:@"presentWebview" sender:self];
}

- (void) mlog: (NSString *) string {
    NSDate *now = [NSDate date];
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    [dateFormatter setDateStyle:NSDateFormatterNoStyle];
    [dateFormatter setDateFormat:@"HH:mm:ss"];
    NSString *debugString = [NSString stringWithFormat:@"%@: %@", [dateFormatter stringFromDate: now], string];
	NSLog(@"%@", debugString);
    self.textview.text = [NSString stringWithFormat:@"%@\n%@", debugString, self.textview.text];
}

- (void)visitBeaconWebsite:(NSString *)minor major:(NSString *)major uuid:(NSString *)uuid
{
	NSURL *baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@", self.serverip]];
	AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:baseURL];
	NSString *restAPI = [NSString stringWithFormat:@"/beacon/%@/%@/%@", uuid, major, minor];
	
	[self mlog:@"performing call to webservice"];
	
	[manager GET:restAPI parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
		
		[self mlog:[NSString stringWithFormat:@"JSON: %@", responseObject]];

		NSDictionary *response = (NSDictionary *)responseObject;
		NSString *urlString = response[@"url"];
		[self openURL:urlString];
		
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		[self mlog:[NSString stringWithFormat:@"Error: %@", error]];
	}];
}

-(void)locationManager:(CLLocationManager*)manager
       didRangeBeacons:(NSArray*)beacons
              inRegion:(CLBeaconRegion*)region
{
	static CLBeacon *lastBeacon;
    CLBeacon *beacon = [beacons firstObject];
	self.currentBeacon = self.currentBeacon ?: beacon;
	
	NSString *uuid = beacon.proximityUUID.UUIDString;
	NSString *major = [NSString stringWithFormat:@"%@", beacon.major];
	NSString *minor = [NSString stringWithFormat:@"%@", beacon.minor];
	
	if (beacon)	[self mlog: [NSString stringWithFormat:@"Beacon: major: %@, minor: %@, promixity: %d", major, minor, (int)beacon.proximity]];
	
	// We want a stable connection, so we're checking that we're getting the same signal at least twice before we do anything
	if (! [lastBeacon isEqualAndInRangeToBeacon:beacon]) {
		lastBeacon = beacon;
		return;
	}
	
	lastBeacon = beacon;
    
    if (beacon != nil
		&& ([self.currentBeacon isEqualToBeacon:beacon])
		&& beacon.isInRange
		)
	{
        if (!self.currentlyPresenting) {
			self.currentlyPresenting = YES;
			[self mlog:@"Presenting!"];
			[self visitBeaconWebsite:minor major:major uuid:uuid];
        }
		else {
			// we are still presenting, so we don't do anything
		}
			
    } else {
		[self.vc dismissViewControllerAnimated:YES completion:^{
			self.currentBeacon = nil;
			self.currentlyPresenting = NO;
		}];
	}
}

 #pragma mark - Navigation
  - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
	 if (self.vc) {
		 [self.vc dismissViewControllerAnimated:YES completion:^{
			 self.currentBeacon = nil;
			 self.currentlyPresenting = NO;
		 }];
	 }
		 
		 self.vc = [segue destinationViewController];
		 self.vc.url = self.url;
 }

@end
