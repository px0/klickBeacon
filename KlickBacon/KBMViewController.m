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

- (void)setupDebugGesture
{
	UITapGestureRecognizer *doubleFingerDoubleTap = [[UITapGestureRecognizer alloc]
                                                initWithTarget:self action:@selector(handleDoubleTap)];
    doubleFingerDoubleTap.numberOfTapsRequired = 2;
    doubleFingerDoubleTap.numberOfTouchesRequired = 2;
    doubleFingerDoubleTap.delegate = self;
    [self.view addGestureRecognizer:doubleFingerDoubleTap];
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
	[self setupDebugGesture];

	if (! [self canDeviceSupportAppBackgroundRefresh]) {
		NSString *message = @"You need to enable Background App Refresh in the System Preferences for this app to work";
		RIButtonItem *okayButton = [RIButtonItem itemWithLabel:@"Okay"];
		okayButton.action =^{
			return;
		};
		
		[[[UIAlertView alloc] initWithTitle:@"Error!"
									message:message
						   cancelButtonItem: okayButton
						   otherButtonItems: nil]
		 show];
	}
	
	
	self.region = [[CLBeaconRegion alloc] initWithProximityUUID:self.beaconUUID identifier:@"Klick"];
	self.region.notifyEntryStateOnDisplay = YES;
	
	// Initialize location manager and set ourselves as the delegate
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    
	// Tell location manager to start monitoring for the beacon region
    [self.locationManager startMonitoringForRegion:self.region];
	[self.locationManager requestStateForRegion:self.region];
	
	[self mlog:(@"starting monitoring")];
	
	[self loadWebsite];

}

#pragma mark - LocationManager Delegate

-(BOOL) canDeviceSupportAppBackgroundRefresh //http://blog.iteedee.com/2014/02/ibeacon-startmonitoringforregion-doesnt-work/
{
    // Override point for customization after application launch.
    if ([[UIApplication sharedApplication] backgroundRefreshStatus] == UIBackgroundRefreshStatusAvailable) {
        NSLog(@"Background updates are available for the app.");
        return YES;
    }else if([[UIApplication sharedApplication] backgroundRefreshStatus] == UIBackgroundRefreshStatusDenied)
    {
        NSLog(@"The user explicitly disabled background behavior for this app or for the whole system.");
        return NO;
    }else if([[UIApplication sharedApplication] backgroundRefreshStatus] == UIBackgroundRefreshStatusRestricted)
    {
        NSLog(@"Background updates are unavailable and the user cannot enable them again. For example, this status can occur when parental controls are in effect for the current user.");
        return NO;
    }
	
	return YES;
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (![CLLocationManager locationServicesEnabled]) {
        [self mlog:(@"Couldn't turn on ranging: Location services are not enabled.")];
    }
	
    if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorized) {
        [self mlog:(@"Couldn't turn on monitoring: Location services not authorised.")];
    }
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error
{
	[self mlog:[NSString stringWithFormat:@"monitoringdidfailrforregion: %@", error]];
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
	if (state == CLRegionStateInside) {
		[self locationManager:manager didEnterRegion:region];
	}
}

- (void)locationManager:(CLLocationManager*)manager didEnterRegion:(CLRegion*)region
{
    [self mlog:@"enter region!!!"];
	[self.locationManager startRangingBeaconsInRegion:self.region];
}

-(void)locationManager:(CLLocationManager*)manager didExitRegion:(CLRegion*)region
{
    [self mlog:(@"exit region!!!")];
	[self.locationManager stopRangingBeaconsInRegion:self.region];
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


#pragma mark Gesture recognizer delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}


- (void) handleDoubleTap
{
	NSLog(@"double tap!");
	self.textview.hidden = !self.textview.isHidden;
}



@end
