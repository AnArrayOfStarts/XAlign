//
//  patternManager.m
//  XAlignNewExtension
//
//  Created by 李晓龙 on 2020/12/23.
//

#define kPatterns                          @"patterns"
#define kPatternID                         @"id"
#define kPatternType                       @"type"
#define kPatternPosition                   @"position"
#define kPatternHeadMode                   @"headMode"
#define kPatternTailMode                   @"tailMode"
#define kPatternMatchMode                  @"matchMode"
#define kPatternIsOptional                 @"isOptional"
#define kPatternString                     @"string"
#define kPatternControl                    @"control"
#define kPatternControlString              @"string"
#define kPatternControlFoundString         @"foundString"
#define kPatternControlFormat              @"format"
#define kPatternControlNotFoundFormat      @"notFoundFormat"
#define kPatternControlNeedTrim            @"needTrim"
#define kPatternControlNeedFormat          @"needFormat"
#define kPatternControlNeedFormatWhenFound @"needFormatWhenFound"
#define kPatternControlNeedPadding         @"needPadding"
#define kPatternControlPaddingString       @"paddingString"
#define kPatternControlIsMatchPadding      @"isMatchPadding"

#import "PatternManager.h"
#import "NSString+XAlign.h"

@interface PatternManager ()
@property (nonatomic, strong) NSMutableDictionary * cache;
@end


@implementation PatternNew

+ (NSArray *)patterns{
    static NSArray * __items = nil;
    
    if ( __items == nil ){
        NSString * patternsBundlePath = [[NSBundle mainBundle] pathForResource:@"Patterns" ofType:@"bundle"];
        NSString * filePath = [[NSBundle bundleWithPath:patternsBundlePath] pathForResource:@"default" ofType:@"plist"];
        
        __items = [NSArray arrayWithContentsOfFile:filePath];
    }
    
    return __items;
}

- (NSString *)description{
    return self.string;
}

@end


@implementation PatternManager
+ (instancetype)sharedInstance
{
    static PatternManager * i = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        i = [[[self class] alloc] init];
    });
    return i;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        self.cache = [NSMutableDictionary new];
        self.specifiers = [NSMutableDictionary new];
    }
    return self;
}
#pragma mark - setup

+ (void)launch
{
    
    [self setupWithRawArray:[PatternNew patterns]];
}

+ (void)setupWithRawArray:(NSArray *)array
{
    
    [self setupSpecifiersWithRawArray:array];
}


+ (NSArray *)setupSpecifiersWithRawArray:(NSArray *)array
{
    if ( !array )
        return nil;
    
    
    for (NSDictionary * item in array )
    {
        
        NSString * spec = item[@"specifier"];
        
        if ( spec )
        {
            
            [PatternManager sharedInstance].specifiers[spec] = item;
            
        }
    }
    
    return nil;
}



+ (NSArray *)patternGroupMatchWithString:(NSString *)string
{
    NSDictionary * dict = [self rawPatternWithString:string];
    return [self patternGroupWithDictinary:dict];
}




+ (NSDictionary *)rawPatternWithString:(NSString *)string
{
    
    NSDictionary * specifiers = [PatternManager sharedInstance].specifiers;
    
    
    for ( NSString * spec in specifiers.allKeys )
    {
        
        
        if ( NSNotFound != [string rangeOfString:spec].location )
        {
            return specifiers[spec];
        }
    }
    
    return nil;
}

+ (NSArray *)patternGroupWithDictinary:(NSDictionary *)dictionary
{
    NSNumber * key = dictionary[kPatternID];
    
    if ( !key )
        return nil;
    
    NSMutableArray * patternGroup = [PatternManager sharedInstance].cache[key];
    
    if ( nil == patternGroup )
    {
        patternGroup = [NSMutableArray array];
        
        for ( NSDictionary * pattern in dictionary[kPatterns] )
        {
            NSString * string           = pattern[kPatternString];

            BOOL isOptional             = [pattern[kPatternIsOptional] intValue];
            XAlignPosition position     = [pattern[kPatternPosition] intValue];
            XAlignPaddingMode headMode  = [pattern[kPatternHeadMode] intValue];
            XAlignPaddingMode matchMode = [pattern[kPatternMatchMode] intValue];
            XAlignPaddingMode tailMode  = [pattern[kPatternTailMode] intValue];

            NSDictionary * control      = pattern[kPatternControl];
            BOOL needTrim               = [control[kPatternControlNeedTrim] boolValue];
            BOOL needFormat             = [control[kPatternControlNeedFormat] boolValue];
            BOOL needFormatWhenFound    = [control[kPatternControlNeedFormatWhenFound] boolValue];
            BOOL needPadding            = [control[kPatternControlNeedPadding] boolValue];
            BOOL isMatchPadding         = [control[kPatternControlIsMatchPadding] boolValue];
            NSString * controlString    = control[kPatternControlString];
            NSString * paddingString    = control[kPatternControlPaddingString];
            NSString * foundString      = control[kPatternControlFoundString];
            NSString * format           = control[kPatternControlFormat];
            NSString * notFoundFormat   = control[kPatternControlNotFoundFormat];

            PatternNew * p = [[PatternNew alloc] init];

            p.string    = string;
            p.headMode  = headMode;
            p.tailMode  = tailMode;
            p.matchMode = matchMode;
            p.position  = position;
            p.isOptional = isOptional;
            p.control   = ^ NSString * ( NSUInteger padding, NSString * match ){
                
                if ( needFormat || needPadding || needFormatWhenFound ){
                    NSString * result = match;

                    if ( needTrim )
                        result = result.xtrim;

                    if ( needFormatWhenFound )
                    {
                        if ( NSNotFound == [match rangeOfString:foundString].location )
                        {
                            if ( notFoundFormat )
                                result = [NSString stringWithFormat:notFoundFormat, result];
                        }
                        else
                        {
                            if ( format )
                                result = [NSString stringWithFormat:format, result];
                        }
                    }
                    else if ( needFormat )
                    {
                        result = [NSString stringWithFormat:format, result];
                    }

                    if ( needPadding )
                    {
                        if ( isMatchPadding ) {
                            result = [result stringByPaddingToLength:padding withString:paddingString startingAtIndex:0];
                        } else {
                            result = [controlString stringByPaddingToLength:padding withString:paddingString startingAtIndex:0];
                        }
                    }

                    return result;
                }

                return controlString;
            };
            
            [patternGroup addObject:p];
        }
        
        [PatternManager sharedInstance].cache[key] = patternGroup;
    }
    
    return patternGroup;
}

@end
