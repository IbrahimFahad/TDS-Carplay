//
//  CPTemplateApplicationScene+Swizzle.m
//  TDS Video
//

#import "CPTemplateApplicationScene.h"
#import <objc/runtime.h>

static void swizzleIfExists(Class cls, NSString *originalName, SEL swizzledSel) {
    SEL originalSel = NSSelectorFromString(originalName);
    Method originalMethod = class_getInstanceMethod(cls, originalSel);
    Method swizzledMethod = class_getInstanceMethod(cls, swizzledSel);
    if (!swizzledMethod) return;
    if (originalMethod) {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    } else {
        class_addMethod(cls, originalSel,
                        method_getImplementation(swizzledMethod),
                        method_getTypeEncoding(swizzledMethod));
    }
}

@implementation CPTemplateApplicationScene (Swizzle)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class cls = [self class];
        // iOS 18 and earlier
        swizzleIfExists(cls, @"_shouldCreateCarWindow", @selector(xyz_shouldCreateCarWindow));
        // iOS 26 candidates
        swizzleIfExists(cls, @"_canCreateCarPlayWindow", @selector(xyz_shouldCreateCarWindow));
        swizzleIfExists(cls, @"_isCarPlayWindowAllowed", @selector(xyz_shouldCreateCarWindow));
        swizzleIfExists(cls, @"_shouldPresentCarPlayWindow", @selector(xyz_shouldCreateCarWindow));
        swizzleIfExists(cls, @"_carPlayWindowAuthorized", @selector(xyz_shouldCreateCarWindow));
    });
}

- (BOOL)xyz_shouldCreateCarWindow {
    return YES;
}

@end


@implementation CPInterfaceController (Bypass)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SEL original = @selector(clientPushedIllegalTemplateOfClass:);
        SEL swizzled = @selector(bypass_clientPushedIllegalTemplateOfClass:);
        Method originalMethod = class_getInstanceMethod(self, original);
        Method swizzledMethod = class_getInstanceMethod(self, swizzled);
        if (originalMethod && swizzledMethod) {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}

- (void)bypass_clientPushedIllegalTemplateOfClass:(Class)cls {
    NSLog(@"Bypassing illegal template restriction");
}

@end


@implementation CPWindow (Bypass)

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];
    if (!view) {
        return self.rootViewController.view;
    }
    return view;
}

@end

@implementation CPWindow (Fix)

- (BOOL)canBecomeFirstResponder { return YES; }
- (BOOL)canResignFirstResponder { return NO; }

- (void)didMoveToSuperview {
    [super didMoveToSuperview];
    [self becomeFirstResponder];
}

@end
