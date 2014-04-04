//
//  CLBeacon+equal.m
//  KlickBacon
//
//  Created by Max Gerlach on 2014-04-01.
//  Copyright (c) 2014 Klick. All rights reserved.
//

#import "CLBeacon+equal.h"

@implementation CLBeacon (equal)
- (BOOL) isEqualToBeacon: (CLBeacon *)otherBeacon
{
	if ([self.proximityUUID.UUIDString isEqualToString:otherBeacon.proximityUUID.UUIDString]
		&& (self.major.intValue == otherBeacon.major.intValue)
		&& (self.minor.intValue == otherBeacon.minor.intValue)
        && (self.proximity == otherBeacon.proximity))
	{
		return YES;
	}
	
	return NO;
}

- (BOOL) isEqualAndInRangeToBeacon: (CLBeacon *)otherBeacon
{
	// we use this to check if the beacon is the same, but we don't want to fail the test
	// if we're going from, say, CLProximityImmediate to CLProximityNear on the same token,
	// that's why we're checking if they're in the same range and equal
	if ([self isEqualToBeacon:otherBeacon]
		&& self.isInRange
		&& otherBeacon.isInRange ){
		return YES;
	}
	
	return NO;
}

- (BOOL) isInRange
{
	if (self.proximity == CLProximityImmediate
		 || self.proximity == CLProximityNear
		 || self.proximity == CLProximityFar
		) {
		return YES;
	}
	
	return NO;
}
@end
