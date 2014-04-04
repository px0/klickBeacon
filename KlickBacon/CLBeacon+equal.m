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

- (NSDictionary *) toDictionary
{

		NSMutableDictionary* object = [NSMutableDictionary dictionary];
		if ([self.proximityUUID UUIDString]) object[@"uuid"] = [self.proximityUUID UUIDString];
		if (self.major) object[@"major"] = @([self.major unsignedIntValue]);
		if (self.minor) object[@"minor"] = @([self.minor unsignedIntValue]);
		if (self.accuracy) object[@"accuracy"] = @(self.accuracy);
		if (self.proximity) object[@"proximity"] = @(self.proximity);
		if (self.rssi) object[@"rssi"] = @(self.rssi);

	return object;
}

- (NSString *) toJSON
{
	NSDictionary *dict = [self toDictionary];
//	NSData *dictDataRepresentation = [NSKeyedArchiver archivedDataWithRootObject:dict];
    NSError *error;
	NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict
													   options:NSJSONWritingPrettyPrinted
														 error:&error];
	
	if (! jsonData) {
        NSLog(@"error: %@", error.localizedDescription);
        return @"{}";
	} else {
        return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
	}
}
@end
