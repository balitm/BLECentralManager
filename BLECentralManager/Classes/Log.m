//
//  Log.m
//  Pods
//
//  Created by Balázs Kilvády on 6/13/16.
//
//

#import <Foundation/Foundation.h>
#include "Log.h"

void DLog(NSString *s, ...) {
#ifdef DEBUG
    va_list argp;

    va_start(argp, s);
    NSLog(@"<%@:%d> %@", \
          [[NSString stringWithUTF8String:__FILE__] lastPathComponent], \
          __LINE__, \
          [[NSString alloc] initWithFormat:(s) arguments: argp]);
#endif
}
