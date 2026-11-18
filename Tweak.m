#import <UIKit/UIKit.h>
#import "Snapshot.h"

@interface MTRViewer : UIViewController
@end
@implementation MTRViewer {
    UITextView *_input;
    UITextView *_output;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Thinking Rules Snapshot";
    self.view.backgroundColor = UIColor.systemBackgroundColor;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(close)];
    UILabel *hint = [UILabel new];
    hint.numberOfLines = 0;
    hint.text = @"Paste minis-config get thinkingrules JSON below. This is a read-only snapshot, not live settings.";
    _input = [UITextView new];
    _input.font = [UIFont monospacedSystemFontOfSize:14 weight:UIFontWeightRegular];
    _input.backgroundColor = UIColor.secondarySystemBackgroundColor;
    _input.autocorrectionType = UITextAutocorrectionTypeNo;
    _input.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _input.smartQuotesType = UITextSmartQuotesTypeNo;
    _input.accessibilityLabel = @"Snapshot JSON input";
    UIButton *load = [UIButton buttonWithType:UIButtonTypeSystem];
    [load setTitle:@"Import Snapshot" forState:UIControlStateNormal];
    [load addTarget:self action:@selector(load) forControlEvents:UIControlEventTouchUpInside];
    _output = [UITextView new];
    _output.editable = NO;
    _output.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    _output.accessibilityLabel = @"Snapshot results";
    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[hint, _input, load, _output]];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 8;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:stack];
    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [stack.topAnchor constraintEqualToAnchor:safe.topAnchor constant:8],
        [stack.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor constant:-8],
        [stack.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:12],
        [stack.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-12],
        [_input.heightAnchor constraintEqualToConstant:88],
        [load.heightAnchor constraintEqualToConstant:44]
    ]];
}
- (void)close { [self dismissViewControllerAnimated:YES completion:nil]; }
- (void)load {
    [_input resignFirstResponder];
    NSString *diagnostic = nil;
    NSArray *providers = MTRParse([_input.text dataUsingEncoding:NSUTF8StringEncoding], &diagnostic);
    _output.text = providers ? MTRRender(providers) : diagnostic;
    [_output setContentOffset:CGPointZero animated:NO];
    if (providers) _input.text = @"";
}
@end

@interface MTREntry : NSObject
@end
@implementation MTREntry
- (void)open:(UITapGestureRecognizer *)gesture {
    UIWindow *window = (UIWindow *)gesture.view;
    if (!window.isKeyWindow || window.windowScene.activationState != UISceneActivationStateForegroundActive) return;
    UIViewController *root = window.rootViewController;
    if (!root.viewIfLoaded.window || root.presentedViewController) return;
    MTRViewer *viewer = [MTRViewer new];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:viewer];
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    [root presentViewController:nav animated:YES completion:nil];
}
- (void)attach:(UIWindow *)window {
    if (!window.rootViewController || window.windowLevel != UIWindowLevelNormal) return;
    for (UIGestureRecognizer *gesture in window.gestureRecognizers)
        if ([gesture.name isEqualToString:@"com.knight914.ministhinkingrules.open"]) return;
    UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(open:)];
    gesture.name = @"com.knight914.ministhinkingrules.open";
    gesture.numberOfTouchesRequired = 3;
    gesture.numberOfTapsRequired = 2;
    gesture.cancelsTouchesInView = NO;
    gesture.delaysTouchesBegan = NO;
    gesture.delaysTouchesEnded = NO;
    [window addGestureRecognizer:gesture];
}
@end

__attribute__((constructor)) static void MTRStart(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSBundle *bundle = NSBundle.mainBundle;
        if (![bundle.bundleIdentifier isEqualToString:@"com.aztut.app"]) return;
        NSString *version = [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        if (![version isEqualToString:@"1.14"] && ![version isEqualToString:@"1.14.0"]) return;
        MTREntry *entry = [MTREntry new];
        NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
        [center addObserverForName:UIWindowDidBecomeKeyNotification object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *note) {
            if ([note.object isKindOfClass:UIWindow.class]) [entry attach:note.object];
        }];
        [center addObserverForName:UISceneDidActivateNotification object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *note) {
            if ([note.object isKindOfClass:UIWindowScene.class])
                for (UIWindow *window in [(UIWindowScene *)note.object windows]) if (window.isKeyWindow) [entry attach:window];
        }];
        for (UIScene *scene in UIApplication.sharedApplication.connectedScenes)
            if ([scene isKindOfClass:UIWindowScene.class])
                for (UIWindow *window in [(UIWindowScene *)scene windows]) if (window.isKeyWindow) [entry attach:window];
    });
}
