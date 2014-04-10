//
//  KBMWebViewDelegate.h
//  KlickBacon
//
//  Created by Max Gerlach on 2014-04-03.
//  Copyright (c) 2014 Klick. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KBMWebViewDelegate : NSObject <UIWebViewDelegate>
@property BOOL webviewIsReady;
@property (weak, nonatomic) id<UIWebViewDelegate> delegate;
@end
