#import "Snapshot.h"
#include <stdlib.h>
#include <stdio.h>

static void Check(BOOL result, const char *message) {
    if (!result) { fprintf(stderr, "FAIL: %s\n", message); exit(1); }
}
static NSArray *Parse(NSString *s, NSString **error) {
    return MTRParse([s dataUsingEncoding:NSUTF8StringEncoding], error);
}
int main(void) {
    @autoreleasepool {
        NSString *error = nil;
        NSString *body = @"[{\"provider\":\"Demo\",\"provider_id\":\"p\",\"custom\":[{\"label\":\"Higher\",\"scope\":\"all\"},{\"label\":\"Lower\",\"scope\":\"test-*\"}],\"builtin\":[{\"label\":\"Fallback\",\"scope\":\"all\"}]}]";
        NSArray *raw = Parse(body, &error);
        Check(raw.count == 1 && !error, "raw summary");
        NSData *wrapped = [NSJSONSerialization dataWithJSONObject:@{@"ok": @YES, @"value": body} options:0 error:NULL];
        Check([MTRParse(wrapped, &error) isEqual:raw], "wrapped summary");
        NSString *text = MTRRender(raw);
        NSRange a = [text rangeOfString:@"1. Higher"], b = [text rangeOfString:@"2. Lower"], c = [text rangeOfString:@"1. Fallback"];
        Check(a.location < b.location && b.location < c.location && c.location != NSNotFound, "preserve rule priority and sections");
        Check([MTRRender(Parse(@"[]", &error)) containsString:@"No providers"], "empty state");
        for (NSString *bad in @[@"", @"{", @"[null]", @"[{\"provider\":\"p\",\"provider_id\":\"p\",\"custom\":[],\"builtin\":[0]}]", @"{\"ok\":1,\"value\":\"[]\"}", @"{\"ok\":false,\"value\":\"[]\"}", @"{\"ok\":true,\"value\":[]}", @"{\"ok\":true,\"value\":\"{}\"}"]) {
            Check(Parse(bad, &error) == nil && error.length, "reject invalid snapshot");
        }
        Check(MTRParse([NSMutableData dataWithLength:512 * 1024 + 1], &error) == nil && error.length, "reject oversized snapshot");
        puts("Native snapshot tests passed");
    }
    return 0;
}
