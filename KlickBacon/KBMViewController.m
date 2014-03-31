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

@interface KBMViewController ()
@property (strong, nonatomic) NSURL *url;
@property (strong, nonatomic) NSUUID *uuid;
@property (strong, nonatomic) NSString *serverip;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLBeaconRegion *region;
@property (strong, nonatomic) KBMWebViewViewController *vc;
@end

@implementation KBMViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
        // Get user preference
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.uuid = [[NSUUID alloc] initWithUUIDString:[defaults objectForKey:@"uuid"]];
    self.serverip = [defaults objectForKey:@"serverip"];
    
    self.region = [[CLBeaconRegion alloc] initWithProximityUUID:self.uuid identifier:@"TestBeacon"];
        // Initialize location manager and set ourselves as the delegate
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    
        // Tell location manager to start monitoring for the beacon region
    [self.locationManager startMonitoringForRegion:self.region];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
	// Do any additional setup after loading the view, typically from a nib.
//    [self openURL:@"http://www.funcage.com/"];
    

}
- (void)locationManager:(CLLocationManager*)manager didEnterRegion:(CLRegion*)region
{
    [self.locationManager startRangingBeaconsInRegion:self.region];
    [self mlog:@"enter region!!!"];
}

-(void)locationManager:(CLLocationManager*)manager didExitRegion:(CLRegion*)region
{

    [self mlog:(@"exit region!!!")];
}

- (void) openURL: (NSString *)urlString {
    self.url = [NSURL URLWithString:urlString];
    [self performSegueWithIdentifier:@"presentWebview" sender:self];
}

- (void) mlog: (NSString *) string {
    NSDate *now = [NSDate date];
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    [dateFormatter setDateStyle:NSDateFormatterNoStyle];
    [dateFormatter setDateFormat:@"HH:mm:ss"];
    
    self.textview.text = [NSString stringWithFormat:@"%@: %@\n%@", [dateFormatter stringFromDate: now], string, self.textview.text];
}

-(void)locationManager:(CLLocationManager*)manager
       didRangeBeacons:(NSArray*)beacons
              inRegion:(CLBeaconRegion*)region
{
    CLBeacon *beacon = [beacons firstObject];
    
        // You can retrieve the beacon data from its properties
        NSString *uuid = beacon.proximityUUID.UUIDString;
        NSString *major = [NSString stringWithFormat:@"%@", beacon.major];
        NSString *minor = [NSString stringWithFormat:@"%@", beacon.minor];
    [self mlog:(@"Beacon found!")];
    [self mlog: [NSString stringWithFormat:@"uuid: %@, major: %@, minor: %@, promixity: %ld", uuid, major, minor, beacon.proximity]];
    
    if (beacon.proximity == CLProximityImmediate) {
        if (!self.vc) {
            [self openURL:@"http://www.funcage.com/"];
        }
    } else {
        if (self.vc) {
            [self.vc dismissViewController];
            self.vc = nil;
        }
    }
}

 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
     self.vc = [segue destinationViewController];
     self.vc.url = self.url;
 }

@end
