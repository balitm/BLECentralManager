//
//  Log.h
//  Pods
//
//  Created by Balázs Kilvády on 6/13/16.
//
//

#ifndef Log_h
#define Log_h

#ifdef DEBUG
    #define DLog(s, ...) \
        NSLog(@"<%@:%d> %@", \
            [[NSString stringWithUTF8String:__FILE__] lastPathComponent], \
            __LINE__, \
            [NSString stringWithFormat:(s), ##__VA_ARGS__])
#else
    #define DLog(s, ...)
#endif

#endif /* Log_h */
