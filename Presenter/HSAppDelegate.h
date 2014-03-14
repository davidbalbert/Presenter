//
//  HSAppDelegate.h
//  Presenter
//
//  Created by David Albert on 3/13/14.
//  Copyright (c) 2014 Hacker School. All rights reserved.
//

#import <Cocoa/Cocoa.h>

static void displaysChangedCallback(CGDirectDisplayID display, CGDisplayChangeSummaryFlags flags, void *userInfo);

static NSString *displayNameFromCGDisplayID(CGDirectDisplayID displayID);
static io_service_t IOServicePortFromCGDisplayID(CGDirectDisplayID displayID);

@interface HSAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSTextField *infoLabel;

@end
