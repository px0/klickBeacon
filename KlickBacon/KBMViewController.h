//
//  KBMViewController.h
//  KlickBacon
//
//  Created by Maximilian Gerlach on 3/29/2014.
//  Copyright (c) 2014 Klick. All rights reserved.
//

#import <UIKit/UIKit.h>
@import CoreLocation;

@interface KBMViewController : UIViewController <CLLocationManagerDelegate, UIWebViewDelegate, UIGestureRecognizerDelegate>
@property (weak, nonatomic) IBOutlet UITextView *textview;
@property (weak, nonatomic) IBOutlet UIWebView *webview;

@end
