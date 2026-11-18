#import <Foundation/Foundation.h>

// Returns nil and a payload-free diagnostic on failure.
NSArray *MTRParse(NSData *data, NSString **diagnostic);
NSString *MTRRender(NSArray *providers);
