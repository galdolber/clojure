//
//  ReplClient.m
//  mpos
//
//  Created by Gal Dolber on 4/12/14.
//  Copyright (c) 2014 zuldi. All rights reserved.
//

#import "ReplClient.h"
#import "clojure/lang/RemoteRepl.h"
#import "clojure/lang/RT.h"
#import "clojure/lang/AFn.h"
#import "clojure/lang/PersistentHashMap.h"
#import "clojure/lang/Var.h"
#import "clojure/lang/Atom.h"
#import "NSSocketImpl.h"
#import "clojure/core_keyword.h"
#import "clojure/core_pr_str.h"
#import "clojure/core_vector.h"
#import "clojure/core_vec.h"
#import "clojure/core_assoc.h"
#import "clojure/core_dissoc.h"
#import "java/util/UUID.h"

static NSSocketImpl *nssocket;
static ClojureLangAtom *responses;
static int callremotes = 0;
static volatile id pendingcall = nil;

@implementation ReplClient

+(void)initialize {
    responses = [[ClojureLangAtom alloc] initWithId:[ClojureLangPersistentHashMap EMPTY]];
}

+(void) processCall2:(id)msg {
    @try {
        id i = [ClojureLangRT firstWithId:msg];
        id s = [ClojureLangRT secondWithId:msg];
        id args = [ClojureLangRT thirdWithId:msg];
        id r = [(ClojureLangAFn*)s applyToWithClojureLangISeq:[ClojureLangRT seqWithId:args]];
        [nssocket println:[[Clojurecore_pr_str VAR] invokeWithId:[[Clojurecore_vector VAR] invokeWithId:i withId:r]]];
    }
    @catch (NSException *exception) {
        NSLog(@"%@ %@", exception, [exception callStackSymbols]);
    }
}

+(void) processCall:(id)msg {
    if ([NSThread isMainThread]) {
        [ReplClient processCall2:msg];
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [ReplClient processCall2:msg];
        });
    }
}

+(void) connect: (NSString*) host port:(NSString*) port {
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        nssocket = [[NSSocketImpl alloc] initWithHost:host withPort:port];
        [ClojureLangRemoteRepl setConnectedWithBoolean:YES];
        while (true) {
            id msg = [ClojureLangRT readStringWithNSString:[nssocket read]];
            if ([ClojureLangRT countFromWithId:msg] == 2) {
                id i = [ClojureLangRT firstWithId:msg];
                id s = [ClojureLangRT secondWithId:msg];
                [responses swapWithClojureLangIFn:[Clojurecore_assoc VAR] withId:i withId:s];
            } else {
                if (callremotes == 0) {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        [ReplClient processCall:msg];
                    });
                } else {
                    pendingcall = msg;
                }
            }
        }
    });
}

+(id) callRemote:(id)sel args:(id)args {
    callremotes++;
    args = [[Clojurecore_vec VAR] invokeWithId:args];
    id i = [[JavaUtilUUID randomUUID] description];
    [nssocket println:[[Clojurecore_pr_str VAR] invokeWithId:[[Clojurecore_vector VAR] invokeWithId:i withId:sel withId:args]]];
    while (true) {
        if ([ClojureLangRT containsWithId:[responses deref] withId:i]) {
            id v = [ClojureLangRT getWithId:[responses deref] withId:i];
            [responses swapWithClojureLangIFn:[Clojurecore_dissoc VAR] withId:i];
            callremotes--;
            return v;
        } else {
            usleep(10000);
            if (pendingcall != nil) {
                id work = pendingcall;
                pendingcall = nil;
                [ReplClient processCall:work];
            }
        }
    }
}

@end