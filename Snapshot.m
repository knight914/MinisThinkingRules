#import "Snapshot.h"
#import <CoreFoundation/CoreFoundation.h>

static BOOL Is(id value, Class type) { return [value isKindOfClass:type]; }

NSArray *MTRParse(NSData *data, NSString **diagnostic) {
    if (diagnostic) *diagnostic = nil;
    NSString *problem = nil;
    id root = nil;
    if (!data.length || data.length > 512 * 1024) {
        problem = @"Paste nonempty JSON of at most 512 KiB.";
    } else {
        root = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        if (Is(root, NSDictionary.class)) {
            id ok = root[@"ok"], value = root[@"value"];
            if (!ok || CFGetTypeID((__bridge CFTypeRef)ok) != CFBooleanGetTypeID() || ![ok boolValue] || !Is(value, NSString.class)) {
                problem = @"Expected a successful minis-config response with a JSON string value.";
            } else {
                NSData *inner = [value dataUsingEncoding:NSUTF8StringEncoding];
                root = inner.length ? [NSJSONSerialization JSONObjectWithData:inner options:0 error:nil] : nil;
            }
        }
        if (!problem && !Is(root, NSArray.class)) problem = @"Expected a JSON array of providers.";
    }
    if (!problem) {
        for (id provider in root) {
            if (!Is(provider, NSDictionary.class) || !Is(provider[@"provider"], NSString.class) || !Is(provider[@"provider_id"], NSString.class)) {
                problem = @"Invalid provider entry."; break;
            }
            for (NSString *kind in @[@"custom", @"builtin"]) {
                id rules = provider[kind];
                if (!Is(rules, NSArray.class)) { problem = @"Missing custom or builtin rule array."; break; }
                for (id rule in rules) {
                    if (!Is(rule, NSDictionary.class) || !Is(rule[@"label"], NSString.class) || !Is(rule[@"scope"], NSString.class)) {
                        problem = @"Invalid rule: expected a label and scope."; break;
                    }
                }
                if (problem) break;
            }
            if (problem) break;
        }
    }
    if (diagnostic) *diagnostic = problem;
    return problem ? nil : root;
}

NSString *MTRRender(NSArray *providers) {
    if (!providers.count) return @"No providers with rules in this snapshot.";
    NSMutableString *text = [NSMutableString string];
    for (NSDictionary *provider in providers) {
        [text appendFormat:@"%@\nProvider ID: %@\n", provider[@"provider"], provider[@"provider_id"]];
        for (NSString *kind in @[@"custom", @"builtin"]) {
            NSArray *rules = provider[kind];
            [text appendFormat:@"\n%@ (%lu)\n", [kind isEqual:@"custom"] ? @"Custom (in priority order)" : @"Built-in fallbacks", (unsigned long)rules.count];
            NSUInteger index = 0;
            for (NSDictionary *rule in rules) {
                NSData *json = [NSJSONSerialization dataWithJSONObject:rule options:NSJSONWritingPrettyPrinted | NSJSONWritingSortedKeys error:nil];
                NSString *detail = [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
                [text appendFormat:@"%lu. %@ — %@\n%@\n", (unsigned long)++index, rule[@"label"], rule[@"scope"], detail ?: @"(details unavailable)"];
            }
        }
        [text appendString:@"\n────────────────\n\n"];
    }
    return text;
}
