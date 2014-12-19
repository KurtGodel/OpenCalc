//
//  MathSubtraction.m
//  Calculator
//
//  Created by Thomas Redding on 9/29/14.
//  Copyright (c) 2014 Thomas Redding. All rights reserved.
//

#import "MathSubtraction.h"

@implementation MathSubtraction

- (MathObject*)func: (NSArray*) input {
    if([input count] != 2) {
        return NULL;
    }
    if([input[0] objectType] == MATHNUMBER && [input[1] objectType] == MATHNUMBER) {
        double a = [input[0] getDouble:0];
        double b = [input[0] getDouble:1];
        double c = [input[1] getDouble:0];
        double d = [input[1] getDouble:1];
        MathNumber *answer = [[MathNumber alloc] init];
        [answer setDouble:0 newValue: a-c];
        [answer setDouble:1 newValue: b-d];
        return answer;
    }
    else {
        return NULL;
    }
}

@end