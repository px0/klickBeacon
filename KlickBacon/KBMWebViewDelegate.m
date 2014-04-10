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

-(instancetype)initWithProxy:(id<UIWebViewDelegate>)delegate {
    self = [super init];
    if(self) {
        self.webviewIsReady = NO;
        self.delegate = delegate;
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
    
    if(self.delegate) [self.delegate webView:webView didFailLoadWithError:error];
	NSLog(@"%@", [error description]);
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
	[SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeBlack];
    
    if(self.delegate) [self.delegate webViewDidStartLoad:webView];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
	[SVProgressHUD dismiss];
	self.webviewIsReady = true;
    if(self.delegate) [self.delegate webViewDidFinishLoad:webView];
}

@end
