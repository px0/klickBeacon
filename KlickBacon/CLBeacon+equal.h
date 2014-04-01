//
//  CLBeacon+equal.h
//  KlickBacon
//
//  Created by Max Gerlach on 2014-04-01.
//  Copyright (c) 2014 Klick. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

@interface CLBeacon (equal)
- (BOOL) isEqualToBeacon: (CLBeacon *)otherBeacon;
- (BOOL) isEqualAndSameDistanceToBeacon: (CLBeacon *)otherBeacon;

@end
