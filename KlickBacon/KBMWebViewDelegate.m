//
//  KBMWebViewDelegate.m
//  KlickBacon
//
//  Created by Max Gerlach on 2014-04-03.
//  Copyright (c) 2014 Klick. All rights reserved.
//

#import "KBMWebViewDelegate.h"
#import "SVProgressHud.h"

@implementation KBMWebViewDelegate

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.webviewIsReady = NO;
    }
    return self;
}

#pragma mark - webview delegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
	NSLog(@"%@", request);
	return YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [SVProgressHUD showErrorWithStatus: [error localizedDescription]];
    
	[webView performSelector:@selector(reload) withObject:nil afterDelay:1.0];
	
	NSLog(@"%@", [error description]);
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
	[SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeBlack];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
	[SVProgressHUD dismiss];
	self.webviewIsReady = true;
	
	[[NSNotificationCenter defaultCenter]
	 postNotificationName:@"refresh"
	 object:self];}

@end
