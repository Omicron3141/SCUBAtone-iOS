//
//  AppDelegate.h
//  SCUBATone
//
//  Created by Jonah Rubin on 8/3/13.
//  Copyright (c) 2013 #scubahack. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ViewController.h"

@class ToneGeneratorViewController;

@interface AppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    ViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet ViewController *viewController;

@end

