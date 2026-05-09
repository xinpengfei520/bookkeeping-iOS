//
//  BookMonth-Bridging-Header.h
//  BookMonth (WidgetKit extension)
//
//  Exposes Objective-C model + helpers to Swift. The widget reuses the
//  main app's data layer (already compiled into this target's Sources)
//  rather than rewriting it in Swift.
//

#ifndef BookMonth_Bridging_Header_h
#define BookMonth_Bridging_Header_h

#import <UIKit/UIKit.h>

#import "BookDetailModel.h"
#import "BookMonthModel.h"
#import "BKCIncomeModel.h"
#import "NSUserDefaults+Extension.h"
#import "NSDate+Extension.h"
#import "NSMutableArray+Extension.h"
#import "KKI18n.h"

#endif /* BookMonth_Bridging_Header_h */
