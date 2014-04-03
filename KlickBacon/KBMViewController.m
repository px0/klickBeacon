//
//  KBMViewController.m
//  KlickBacon
//
//  Created by Maximilian Gerlach on 3/29/2014.
//  Copyright (c) 2014 Klick. All rights reserved.
//

#import "KBMViewController.h"
#import "GHContextMenuView.h"
#import "AFNetworking.h"
#import "CLBeacon+equal.h"
#import "KBMWebViewDelegate.h"

@interface KBMViewController ()
@property (strong, nonatomic) NSURL *url;
@property (strong, nonatomic) NSUUID *beaconUUID;
@property (strong, nonatomic) NSUUID *deviceUUID;
@property (strong, nonatomic) NSString *websiteURL;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLBeaconRegion *region;
@property (strong, nonatomic) CLBeacon *beaconThatIsBeingPresented;
@property (strong, nonatomic) KBMWebViewDelegate *webviewDelegate;
@end

@implementation KBMViewController

- (void)loadUserDefaults
{
	// Get user preference
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.beaconUUID = [[NSUUID alloc] initWithUUIDString:[defaults objectForKey:@"uuid"]];
    self.websiteURL = [defaults objectForKey:@"websiteurl"];
	self.deviceUUID = [defaults objectForKey:@"deviceuuid"] ?: [[UIDevice currentDevice] identifierForVendor];
	[defaults synchronize];
}

- (void)loadWebsite
{
	self.webviewDelegate = [KBMWebViewDelegate new];
	self.webview.delegate = self.webviewDelegate;
	
	NSURL *url;
	if ([self.websiteURL hasPrefix:@"http"]) {
		url = [NSURL URLWithString:self.websiteURL];
	} else {
		url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@", self.websiteURL]];
	}
	
	[self.webview loadRequest:[NSURLRequest requestWithURL:url]];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	[self loadUserDefaults];

	self.region = [[CLBeaconRegion alloc] initWithProximityUUID:self.beaconUUID identifier:@"Klick"];
	self.region.notifyEntryStateOnDisplay = YES;
	
	// Initialize location manager and set ourselves as the delegate
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    
	// Tell location manager to start monitoring for the beacon region
    [self.locationManager startMonitoringForRegion:self.region];
	[self.locationManager requestStateForRegion:self.region];
    [self.locationManager startRangingBeaconsInRegion:self.region];
	
	[self mlog:(@"starting monitoring")];
	
	[self loadWebsite];

}


- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error
{
	[self mlog:[NSString stringWithFormat:@"monitoringdidfailrforregion: %@", error]];
}

- (void)locationManager:(CLLocationManager*)manager didEnterRegion:(CLRegion*)region
{
    [self mlog:@"enter region!!!"];
}

-(void)locationManager:(CLLocationManager*)manager didExitRegion:(CLRegion*)regionf
{

    [self mlog:(@"exit region!!!")];
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


- (void)executeJavascriptOnWebsite:(NSString *)minor major:(NSString *)major uuid:(NSString *)uuid {
	NSString *apiCall = [NSString stringWithFormat:@"beacon('%@', '%@', '%@', '%@');", uuid, major, minor, self.deviceUUID];
	
	[self.webview stringByEvaluatingJavaScriptFromString:apiCall];
}


-(void)locationManager:(CLLocationManager*)manager
       didRangeBeacons:(NSArray*)beacons
              inRegion:(CLBeaconRegion*)region
{
    CLBeacon *currentBeacon = [beacons firstObject];
	self.beaconThatIsBeingPresented = self.beaconThatIsBeingPresented ?: currentBeacon;
	
	NSString *uuid = currentBeacon.proximityUUID.UUIDString;
	NSString *major = [NSString stringWithFormat:@"%@", currentBeacon.major];
	NSString *minor = [NSString stringWithFormat:@"%@", currentBeacon.minor];
	
	if (currentBeacon)	[self mlog: [NSString stringWithFormat:@"Beacon: major: %@, minor: %@, promixity: %d", major, minor, (int)currentBeacon.proximity]];
	
	if (currentBeacon && currentBeacon.isInRange && ![currentBeacon isEqualToBeacon:self.beaconThatIsBeingPresented]) {
		[self mlog:@"Presenting!"];
		[self executeJavascriptOnWebsite:minor major:major uuid:uuid];
		self.beaconThatIsBeingPresented = currentBeacon;
	}
}





@end
