//
//  NSArray+json.m
//  KlickBacon
//
//  Created by Max Gerlach on 2014-04-04.
//  Copyright (c) 2014 Klick. All rights reserved.
//

#import "NSArray+json.h"

@implementation NSArray (json)
-(NSString*) toJSON {
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self
                                                       options:(NSJSONWritingOptions)NSJSONWritingPrettyPrinted
                                                         error:&error];
	
    if (! jsonData) {
        NSLog(@"bv_jsonStringWithPrettyPrint: error: %@", error.localizedDescription);
        return @"[]";
    } else {
        return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
}
@end
