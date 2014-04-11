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
#import "JSONModel.h"
#import "NSArray+json.h"

@interface KBMViewController ()
@property (strong, nonatomic) NSURL *url;
@property (strong, nonatomic) NSUUID *beaconUUID;
@property (strong, nonatomic) NSUUID *deviceUUID;
@property (strong, nonatomic) NSString *websiteURL;
@property (nonatomic) BOOL allowLockscreenNotifications;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLBeaconRegion *region;
@property (strong, nonatomic) CLBeacon *beaconThatIsBeingPresented;
@property (strong, nonatomic) KBMWebViewDelegate *webviewDelegate;
@property (strong, nonatomic) NSMutableArray *webviewJavascriptQueue;


@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *debugItems;
- (IBAction)reloadBtnTap:(id)sender;
- (IBAction)fakePingBtnTap:(id)sender;

@end

@implementation KBMViewController

- (void)registerDefaultsFromSettingsBundle // we need this for the first launch when the settings haven't been read yet
{
	NSLog(@"Registering default values from Settings.bundle");
	NSUserDefaults * defs = [NSUserDefaults standardUserDefaults];
	[defs synchronize];
	
	NSString *settingsBundle = [[NSBundle mainBundle] pathForResource:@"Settings" ofType:@"bundle"];
	
	if(!settingsBundle)
	{
		NSLog(@"Could not find Settings.bundle");
		return;
	}
	
	NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:[settingsBundle stringByAppendingPathComponent:@"Root.plist"]];
	NSArray *preferences = [settings objectForKey:@"PreferenceSpecifiers"];
	NSMutableDictionary *defaultsToRegister = [[NSMutableDictionary alloc] initWithCapacity:[preferences count]];
	
	for (NSDictionary *prefSpecification in preferences)
	{
		NSString *key = [prefSpecification objectForKey:@"Key"];
		if (key)
		{
			// check if value readable in userDefaults
			id currentObject = [defs objectForKey:key];
			if (currentObject == nil)
			{
				// not readable: set value from Settings.bundle
				id objectToSet = [prefSpecification objectForKey:@"DefaultValue"];
				[defaultsToRegister setObject:objectToSet forKey:key];
				NSLog(@"Setting object %@ for key %@", objectToSet, key);
			}
			else
			{
				// already readable: don't touch
				NSLog(@"Key %@ is readable (value: %@), nothing written to defaults.", key, currentObject);
			}
		}
	}
	
	[defs registerDefaults:defaultsToRegister];
	[defs synchronize];
}

- (void)loadUserDefaults
{
	[self mlog:@"Loading user defaults"];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.beaconUUID = [[NSUUID alloc] initWithUUIDString:[defaults objectForKey:@"uuid"]];
    self.websiteURL = [defaults objectForKey:@"websiteurl"];
	self.deviceUUID = [defaults objectForKey:@"deviceuuid"] ?: [[UIDevice currentDevice] identifierForVendor];
	self.allowLockscreenNotifications = [defaults boolForKey:@"allowLockscreenNotifications"];
	[defaults synchronize];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
	
	[self registerDefaultsFromSettingsBundle];
	[self loadUserDefaults];
    [[NSNotificationCenter defaultCenter] addObserver:self
               selector:@selector(loadUserDefaults)
                   name:NSUserDefaultsDidChangeNotification
                 object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(resetEverything)
												 name:@"refresh"
											   object:nil];
	
	[self setupDebugGesture];
	[self checkCanDeviceSupportAppBackgroundRefresh];
	[self checkLocationServicesEnabledAndAuthorized];
	
	self.webviewJavascriptQueue = [NSMutableArray new];
	[self startRegionMonitoring];
	[self loadWebsite];
}


- (void)loadWebsite
{
	self.webviewDelegate = [[KBMWebViewDelegate alloc] init];
	self.webview.delegate = self.webviewDelegate;
	
	NSURL *url;
	if ([self.websiteURL hasPrefix:@"http"]) {
		url = [NSURL URLWithString:self.websiteURL];
	} else {
		url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@", self.websiteURL]];
	}
	
	[self.webview loadRequest:[NSURLRequest
                               requestWithURL:url
                               cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                               timeoutInterval:10.0]
     ];
}


#pragma mark - LocationManager Delegate
- (void)startRegionMonitoring
{
	self.region = [[CLBeaconRegion alloc] initWithProximityUUID:self.beaconUUID identifier:@"Klick"];
	self.region.notifyEntryStateOnDisplay = YES;
	
	// Initialize location manager and set ourselves as the delegate
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    
	// Tell location manager to start monitoring for the beacon region
	if ([CLLocationManager isMonitoringAvailableForClass:[CLBeaconRegion class]]) {
		[self.locationManager startMonitoringForRegion:self.region];
		
		// get status update right away for UI
		[self.locationManager requestStateForRegion:self.region];
		[self mlog:(@"starting monitoring")];
		
	}
	else {
		NSLog(@"This device does not support monitoring beacon regions");
	}
}

-(void) checkCanDeviceSupportAppBackgroundRefresh //http://blog.iteedee.com/2014/02/ibeacon-startmonitoringforregion-doesnt-work/
{
    if ([[UIApplication sharedApplication] backgroundRefreshStatus] == UIBackgroundRefreshStatusAvailable) {
        [self mlog:(@"Background updates are available for the app.")];
    }else if(
			 [[UIApplication sharedApplication] backgroundRefreshStatus] == UIBackgroundRefreshStatusDenied
			 || [[UIApplication sharedApplication] backgroundRefreshStatus] == UIBackgroundRefreshStatusRestricted
			)
    {
		NSString *message = @"You need to enable Background App Refresh in the System Preferences for this app to work";
		[self showUserErrorMessage:message];
	}
}

- (void)checkLocationServicesEnabledAndAuthorized
{
    if (![CLLocationManager locationServicesEnabled]) {
        [self showUserErrorMessage:(@"Couldn't turn on ranging: Location services are not enabled.")];
    }
	
    if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorized) {
        [self showUserErrorMessage:(@"Couldn't turn on monitoring: Location services not authorised.")];
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
	//TODO: This is still broken. Investigate http://beekn.net/2013/11/ibeacon-round-up-move-to-me/
//    [self mlog:(@"exit region!!!")];
//	[self.locationManager stopRangingBeaconsInRegion:self.region];
}

-(CLBeacon*)getBestBeacon:(NSArray*)beacons {
    CLBeacon * best = nil;
    
    for(int i = 0; i < [beacons count]; i++) {
        CLBeacon * cur = [beacons objectAtIndex:i];
        if(cur.rssi && (!best || cur.rssi > best.rssi))
            best = cur;
    }
    
    return best;
}

-(void)locationManager:(CLLocationManager*)manager
       didRangeBeacons:(NSArray*)beacons
              inRegion:(CLBeaconRegion*)region
{
    CLBeacon *currentBeacon = [self getBestBeacon:beacons];
	self.beaconThatIsBeingPresented = self.beaconThatIsBeingPresented ?: nil;
	
	NSString *uuid = currentBeacon.proximityUUID.UUIDString;
	int major = [currentBeacon.major intValue];
	int minor = [currentBeacon.minor intValue];
	
	if (currentBeacon)	[self mlog: [NSString stringWithFormat:@"Beacon: major: %d, minor: %d, promixity: %d", major, minor, (int)currentBeacon.proximity]];
	
	if (currentBeacon && currentBeacon.isInRange && ![currentBeacon isEqualToBeacon:self.beaconThatIsBeingPresented]) {
		[self mlog:@"Presenting!"];
		 [self getMessageForBeaconWithMajor:major minor:minor uuid:uuid proximity:currentBeacon.proximity success:^(NSString *message) {
			 [self sendLocalNotificationWithMessage:message];
		 }];
		//		NSString *jsonBeacons = [self beaconJSONRepresentation:beacons];
		[self executeJavascriptOnWebsite:minor major:major uuid:uuid proximity:currentBeacon.proximity];
		self.beaconThatIsBeingPresented = currentBeacon;
	}
	
}

- (void) resetEverything {
	self.webviewJavascriptQueue = [NSMutableArray new];
	self.beaconThatIsBeingPresented = nil;
}

#pragma mark - Javascript stuff

- (void) processJavascriptQueue
{
	if (self.webviewDelegate.webviewIsReady && self.webviewJavascriptQueue.count > 0) {
		[self mlog:@"ready now, processing queue"];
		for (NSString *call in self.webviewJavascriptQueue) {
			[self.webview stringByEvaluatingJavaScriptFromString:call];
		}
		self.webviewJavascriptQueue = [NSMutableArray new];
	} else {
		[self performSelector:@selector(processJavascriptQueue) withObject:nil afterDelay:1.0];
	}
}

- (void)executeJavascriptOnWebsite:(int)minor major:(int)major uuid:(NSString *)uuid proximity:(CLProximity)proximity {
	NSString *apiCall = [NSString stringWithFormat:@"beacon('%@', %d, %d, '%@', %d);", uuid, major, minor, self.deviceUUID, (int)proximity];
	
	UIApplicationState state = [[UIApplication sharedApplication] applicationState]; //check if we're in the foreground or the backgorund

	if (self.webviewDelegate.webviewIsReady && state == UIApplicationStateActive) {
		[self.webview stringByEvaluatingJavaScriptFromString:apiCall];
	} else {
		[self mlog:@"webview not ready, adding call to queue"];
		[self.webviewJavascriptQueue addObject:apiCall];
	}
	
	[self processJavascriptQueue];
}




- (NSString *) beaconJSONRepresentation: (NSArray *)beacons {
	NSMutableArray *output = [NSMutableArray new];
	
	for (CLBeacon *b in beacons) {
		[output addObject:[b toJSON]];
	}
	
	return [output toJSON];
}


#pragma mark Gesture recognizer delegate

- (void)setupDebugGesture
{
	UITapGestureRecognizer *doubleFingerDoubleTap = [[UITapGestureRecognizer alloc]
													 initWithTarget:self action:@selector(handleDoubleTap)];
    doubleFingerDoubleTap.numberOfTapsRequired = 2;
    doubleFingerDoubleTap.numberOfTouchesRequired = 2;
    doubleFingerDoubleTap.delegate = self;
    [self.view addGestureRecognizer:doubleFingerDoubleTap];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
	return YES;
}

- (void) handleDoubleTap
{
	[self.debugItems each:^(UIView *item) {
		item.hidden = !item.isHidden;
	}];
}


#pragma mark - Misc

- (void) mlog: (NSString *) string {
    NSDate *now = [NSDate date];
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    [dateFormatter setDateStyle:NSDateFormatterNoStyle];
    [dateFormatter setDateFormat:@"HH:mm:ss"];
    NSString *debugString = [NSString stringWithFormat:@"%@: %@", [dateFormatter stringFromDate: now], string];
	NSLog(@"%@", debugString);
    self.textview.text = [NSString stringWithFormat:@"%@\n%@", debugString, self.textview.text];
}


- (void)showUserErrorMessage:(NSString *)message
{
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

-(void)sendLocalNotificationWithMessage: (NSString *)message {
	UIApplicationState state = [[UIApplication sharedApplication] applicationState]; //check if we're in the foreground or the backgorund
	
	if (_allowLockscreenNotifications && state != UIApplicationStateActive) {
		UILocalNotification *notification = [[UILocalNotification alloc] init];
		notification.alertBody = message;
		[self mlog:[NSString stringWithFormat:@"Presenting push notification with message: %@", message]];
		[[UIApplication sharedApplication] presentLocalNotificationNow:notification];
	}
}

- (void)getMessageForBeaconWithMajor:(int)major minor:(int)minor uuid:(NSString *)uuid proximity:(CLProximity)proximity success:(void (^)(NSString *message))completionBlock {
	NSURL *baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@", self.websiteURL]];
	AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:baseURL];
	NSString *restAPI = [NSString stringWithFormat:@"/beacon/%@/%d/%d", uuid, major, minor];
	
	[self mlog:@"performing call to webservice"];
	
	[manager GET:restAPI parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
		NSDictionary *response = (NSDictionary *)responseObject;
		NSString *title = response[@"title"];
		
        dispatch_async( dispatch_get_main_queue(), ^{
			completionBlock(title);
		});
		
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		[self mlog:[NSString stringWithFormat:@"Error: %@", error]];
	}];
}

- (void) reloadWebsite {
	RIButtonItem *okayButton = [RIButtonItem itemWithLabel:@"Reload"];
	okayButton.action =^{
		[self loadWebsite];
	};
	
	RIButtonItem *cancelButton = [RIButtonItem itemWithLabel:@"Cancel"];
	
	NSString *message = @"Do you want to reload the website?";
	
	[[[UIAlertView alloc] initWithTitle:@"Error!"
								message:message
					   cancelButtonItem:cancelButton
					   otherButtonItems:okayButton, nil]
	 show];
}

- (IBAction)reloadBtnTap:(id)sender {
	[self reloadWebsite];
}

- (IBAction)fakePingBtnTap:(id)sender {
	[self.webview stringByEvaluatingJavaScriptFromString:@"addTest()"];
}
@end
