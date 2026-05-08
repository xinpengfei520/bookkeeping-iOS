//
//  KKWeakify.h
//  bookkeeping
//
//  ReactiveObjC's @weakify(x) / @strongify(x) replacement. Single-arg only —
//  we don't need RAC's metamacro multi-arg variant. Used identically:
//
//      @weakify(self)
//      btn.action = ^{
//          @strongify(self)
//          [self doStuff];
//      };
//
//  The trailing `autoreleasepool {}` after the leading `@` is a keywordify
//  trick to make `@weakify(...)` parse as a statement (so it can be used
//  freely inline without requiring explicit braces around it).
//

#ifndef KKWeakify_h
#define KKWeakify_h

#define weakify(VAR) \
    autoreleasepool {} \
    __weak typeof(VAR) VAR##_weak_ = (VAR);

#define strongify(VAR) \
    autoreleasepool {} \
    _Pragma("clang diagnostic push") \
    _Pragma("clang diagnostic ignored \"-Wshadow\"") \
    __strong typeof(VAR) VAR = VAR##_weak_; \
    _Pragma("clang diagnostic pop")

#endif /* KKWeakify_h */
