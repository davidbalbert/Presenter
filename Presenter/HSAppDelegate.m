//
//  HSAppDelegate.m
//  Presenter
//
//  Created by David Albert on 3/13/14.
//  Copyright (c) 2014 Hacker School. All rights reserved.
//

#import "HSAppDelegate.h"

@implementation HSAppDelegate

@synthesize infoLabel;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    CGDisplayRegisterReconfigurationCallback(displaysChangedCallback, (__bridge void *)self);
    [self updateDisplayList];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    CGDisplayRemoveReconfigurationCallback(displaysChangedCallback, (__bridge void *)self);
}

- (void)updateDisplayList
{
    CGError error = CGDisplayNoErr;
    CGDirectDisplayID *displays;
    uint32_t count;
    
    error = CGGetOnlineDisplayList(0, NULL, &count);
    
    if (error) {
        [infoLabel setStringValue:@"Uh oh..."];
        return;
    }
    
    displays = malloc(count * sizeof(CGDirectDisplayID));
    
    if (!displays) {
        [infoLabel setStringValue:@"Uh oh..."];
        return;
    }
    
    if (CGGetOnlineDisplayList(count, displays, &count) == 0) {
        NSString *displayInfo = @"Displays:\n\n";
        
        for (uint32_t i = 0; i < count; i++) {
            NSString *s = [NSString stringWithFormat:@"%d. %@\n", i + 1, displayNameFromCGDisplayID(displays[i])];
            displayInfo = [displayInfo stringByAppendingString:s];
        }
        
        [infoLabel setStringValue:displayInfo];
    } else {
        [infoLabel setStringValue:@"Uh oh..."];
    }
    
    free(displays);
}

@end

static void displaysChangedCallback(CGDirectDisplayID display, CGDisplayChangeSummaryFlags flags, void *userInfo)
{
    HSAppDelegate *appDelegate = (__bridge HSAppDelegate *)userInfo;
    [appDelegate updateDisplayList];
}

static NSString *displayNameFromCGDisplayID(CGDirectDisplayID displayID)
{
    io_service_t serv = IOServicePortFromCGDisplayID(displayID);
    NSDictionary *deviceInfo = CFBridgingRelease(IODisplayCreateInfoDictionary(serv, kIODisplayOnlyPreferredName));
    
    IOObjectRelease(serv);
    
    NSDictionary *localizedNames = deviceInfo[[NSString stringWithUTF8String:kDisplayProductName]];
    
    if ([localizedNames count] > 0) {
    	return [localizedNames objectForKey:[[localizedNames allKeys] objectAtIndex:0]];
    } else {
        return nil;
    }
}

// From glfw: https://raw.github.com/mhenr18/glfw/master/src/cocoa_monitor.m
// Returns the io_service_t corresponding to a CG display ID, or 0 on failure.
// The io_service_t should be released with IOObjectRelease when not needed.
//
static io_service_t IOServicePortFromCGDisplayID(CGDirectDisplayID displayID)
{
    io_iterator_t iter;
    io_service_t serv, servicePort = 0;
    
    CFMutableDictionaryRef matching = IOServiceMatching("IODisplayConnect");
    
    // releases matching for us
    kern_return_t err = IOServiceGetMatchingServices(kIOMasterPortDefault,
                                                     matching,
                                                     &iter);
    if (err)
    {
        return 0;
    }
    
    while ((serv = IOIteratorNext(iter)) != 0)
    {
        CFDictionaryRef info;
        CFIndex vendorID, productID;
        CFNumberRef vendorIDRef, productIDRef;
        Boolean success;
        
        info = IODisplayCreateInfoDictionary(serv,
                                             kIODisplayOnlyPreferredName);
        
        vendorIDRef = CFDictionaryGetValue(info,
                                           CFSTR(kDisplayVendorID));
        productIDRef = CFDictionaryGetValue(info,
                                            CFSTR(kDisplayProductID));
        
        success = CFNumberGetValue(vendorIDRef, kCFNumberCFIndexType,
                                   &vendorID);
        success &= CFNumberGetValue(productIDRef, kCFNumberCFIndexType,
                                    &productID);
        
        if (!success)
        {
            CFRelease(info);
            continue;
        }
        
        if (CGDisplayVendorNumber(displayID) != vendorID ||
            CGDisplayModelNumber(displayID) != productID)
        {
            CFRelease(info);
            continue;
        }
        
        // we're a match
        servicePort = serv;
        CFRelease(info);
        break;
    }
    
    IOObjectRelease(iter);
    return servicePort;
}
