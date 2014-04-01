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
		&& (self.minor.intValue == otherBeacon.minor.intValue))
	{
		return YES;
	}
	
	return NO;
}

- (BOOL) isEqualAndSameDistanceToBeacon: (CLBeacon *)otherBeacon
{
	if ([self isEqualToBeacon:otherBeacon]
		&& (self.proximity == otherBeacon.proximity)) {
		return YES;
	}
	
	return NO;
}
@end
