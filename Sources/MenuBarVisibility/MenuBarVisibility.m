// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint
// Adapted from Hidden Bar (https://github.com/dwarvesf/hidden), MIT License,
// Copyright (c) 2019 Dwarves Foundation.

#import "include/MenuBarVisibility.h"

#import <dlfcn.h>
#import <objc/message.h>

static NSString *const MenuBarVisibilityErrorDomain = @"MenuBarVisibility";

static NSError *MenuBarVisibilityError(NSString *reason) {
    return [NSError errorWithDomain:MenuBarVisibilityErrorDomain
                               code:1
                           userInfo:@{NSLocalizedDescriptionKey: reason}];
}

// MenuBarClientCore is the private framework behind macOS 27's assessment
// (exam lockdown) mode, which can restrict the menu bar to an allow-list. It
// is resolved at runtime so a macOS release that changes or removes it turns
// into "unavailable" rather than a launch failure. Names are spelled out on
// purpose.
static NSString *const MBVFrameworkPath = @"/System/Library/PrivateFrameworks/MenuBarClientCore.framework/MenuBarClientCore";
static NSString *const MBVConfigurationClassName = @"MBAssessmentModeConfiguration";
static NSString *const MBVAssertionClassName = @"MBAssessmentModeAssertion";

static SEL MBVConfigurationInit(void) { return @selector(initWithAllowedSystemItems:allowedBundleIdentifiers:); }
static SEL MBVActivate(void) { return @selector(activateWithConfiguration:completionHandler:); }
static SEL MBVInvalidate(void) { return @selector(invalidate); }

BOOL MenuBarVisibilityIsAvailable(void) {
    if (!dlopen(MBVFrameworkPath.fileSystemRepresentation, RTLD_NOW | RTLD_LOCAL)) {
        return NO;
    }
    Class configuration = NSClassFromString(MBVConfigurationClassName);
    Class assertion = NSClassFromString(MBVAssertionClassName);
    return configuration && assertion
        && [configuration instancesRespondToSelector:MBVConfigurationInit()]
        && [assertion instancesRespondToSelector:MBVActivate()]
        && [assertion instancesRespondToSelector:MBVInvalidate()];
}

void MenuBarVisibilityActivate(NSArray<NSNumber *> *allowedSystemItems,
                               NSArray<NSString *> *allowedBundleIdentifiers,
                               void (^completion)(id _Nullable assertion, NSError * _Nullable error)) {
    void (^finish)(id, NSError *) = ^(id assertion, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{ completion(assertion, error); });
    };
    if (!MenuBarVisibilityIsAvailable()) {
        finish(nil, MenuBarVisibilityError(@"MenuBarClientCore is unavailable on this macOS"));
        return;
    }
    @try {
        // Both lists must be NSArrays: the framework indexes into them, and an
        // NSSet raises -objectAtIndex: unrecognized.
        id configuration = ((id (*)(id, SEL, NSArray *, NSArray *))objc_msgSend)(
            [NSClassFromString(MBVConfigurationClassName) alloc], MBVConfigurationInit(),
            [allowedSystemItems copy], [allowedBundleIdentifiers copy]);
        id assertion = [[NSClassFromString(MBVAssertionClassName) alloc] init];
        if (!configuration || !assertion) {
            finish(nil, MenuBarVisibilityError(@"Could not create the visibility configuration"));
            return;
        }
        ((void (*)(id, SEL, id, void (^)(NSError *)))objc_msgSend)(
            assertion, MBVActivate(), configuration, ^(NSError *error) {
                finish(error ? nil : assertion, error);
            });
    } @catch (NSException *exception) {
        finish(nil, MenuBarVisibilityError([NSString stringWithFormat:@"%@: %@", exception.name, exception.reason]));
    }
}

void MenuBarVisibilityInvalidate(id assertion) {
    @try {
        if ([assertion respondsToSelector:MBVInvalidate()]) {
            ((void (*)(id, SEL))objc_msgSend)(assertion, MBVInvalidate());
        }
    } @catch (NSException *exception) {
        NSLog(@"MenuBarVisibility: invalidate raised %@: %@", exception.name, exception.reason);
    }
}
