//
//  KBMWebViewViewController.h
//  KlickBacon
//
//  Created by Maximilian Gerlach on 3/30/2014.
//  Copyright (c) 2014 Klick. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KBMWebViewViewController : UIViewController <UIWebViewDelegate>
@property (weak, nonatomic) IBOutlet UIWebView *webview;
@property (strong, nonatomic) NSURL *url;
- (void)dismissViewController;

@end
