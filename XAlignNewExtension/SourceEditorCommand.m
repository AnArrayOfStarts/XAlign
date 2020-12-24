//
//  SourceEditorCommand.m
//  XAlignNewExtension
//
//  Created by 李晓龙 on 2020/12/23.
//

#import "SourceEditorCommand.h"
//#import "XAlignNewPattern.h"
//#import "XAlignNewPattern.h"
#import "NSString+XAlign.h"
#import "PatternManager.h"


@implementation SourceEditorCommand

- (void)performCommandWithInvocation:(XCSourceEditorCommandInvocation *)invocation completionHandler:(void (^)(NSError * _Nullable nilOrError))completionHandler
{
    // Implement your command here, invoking the completion handler when done. Pass it nil on success, and an NSError on failure.
    
    if ([invocation.commandIdentifier hasSuffix:@"SourceEditorCommand"])
    {
        [[self class] autoAlign:invocation];
    }
    
    completionHandler(nil);
}

+ (void)autoAlign:(XCSourceEditorCommandInvocation *)invocation
{
    
    NSMutableArray * selections = [NSMutableArray array];
    
    for ( XCSourceTextRange *range in invocation.buffer.selections )
    {
        for ( NSInteger i = range.start.line; i < range.end.line ; i++)
        {
            [selections addObject:invocation.buffer.lines[i]];
        }
    }
    

    NSString * selectedString = [selections componentsJoinedByString:@""];
    NSArray * patternGroup = [PatternManager patternGroupMatchWithString:selectedString];
    
    
    if ( !patternGroup )
        return;
    
    NSString * alignedString = [selectedString stringByAligningWithPatterns:patternGroup];
    
    NSArray * result = [alignedString componentsSeparatedByString:@"\n"];

    for ( XCSourceTextRange *range in invocation.buffer.selections )
    {
        for ( NSInteger i = range.start.line, j=0; i < range.end.line ; i++, j++ )
        {
            invocation.buffer.lines[i] = result[j];
        }
    }
}


@end
