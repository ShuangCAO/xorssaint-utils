// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint
// Adapted from Hidden Bar (https://github.com/dwarvesf/hidden), MIT License,
// Copyright (c) 2019 Dwarves Foundation.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// The only boundary to macOS 27's private MenuBarClientCore framework.
// Objective-C so that exceptions a changed private API raises can be caught
// instead of crashing the app.

// Whether the framework, both classes and every selector used by the shim
// resolve on this system.
BOOL MenuBarVisibilityIsAvailable(void);

// Keeps only the given system items and apps visible; macOS hides every other
// status item and reflows the bar. The completion runs on the main queue with
// the assertion to hold (hiding lasts until it is invalidated or this process
// exits) or with an error.
void MenuBarVisibilityActivate(NSArray<NSNumber *> *allowedSystemItems,
                               NSArray<NSString *> *allowedBundleIdentifiers,
                               void (^completion)(id _Nullable assertion, NSError * _Nullable error));

// Releases a previously returned assertion. Passing nil is a no-op.
void MenuBarVisibilityInvalidate(id assertion);

NS_ASSUME_NONNULL_END
