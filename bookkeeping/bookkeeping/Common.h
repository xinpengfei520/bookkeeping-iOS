/**
 * 系统配置
 * @author 郑业强 2018-12-16 创建文件
 */

#ifndef Common_h
#define Common_h

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <UserNotifications/UserNotifications.h>

//================================= Third ===================================//
#import <JGProgressHUD/JGProgressHUD.h>
#import <MJExtension/MJExtension.h>
#import <SDCycleScrollView/SDCycleScrollView.h>
#import <ReactiveObjC/ReactiveObjC.h>
#import <MJRefresh/MJRefresh.h>
#import <MGSwipeTableCell/MGSwipeTableCell.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import <SDWebImage/UIButton+WebCache.h>
#import <pop/POP.h>
#import <BRPickerView/BRPickerView.h>
#import <ZLPhotoBrowser/ZLPhotoBrowser-Swift.h>


//================================= Event/Notification =================================//
#import "BOOK_EVENT.h"


//================================= Base =====================================//
#import "BaseView.h"
#import "BaseModel.h"
#import "BaseTableView.h"
#import "BaseTableCellProtocol.h"
#import "BaseCollectionCellProtocol.h"
#import "BaseViewController.h"
#import "BaseCollectionView.h"
#import "BaseTabBarController.h"
#import "BaseNavigationController.h"
#import "BaseTableCell.h"
#import "ASBaseViewController.h"

//================================= Category =================================//
#import "NSString+Extension.h"
#import "NSString+Encryption.h"
#import "NSObject+JGRuntime.h"
#import "NSAttributedString+Extension.h"
#import "NSAttributedString+Extension.h"
#import "NSDate+Extension.h"
#import "NSObject+NSCoding.h"
#import "NSUserDefaults+Extension.h"
#import "NSMutableArray+Extension.h"
#import "NSString+Calculation.h"
#import "UIFont+Extension.h"
#import "UIView+Extension.h"
#import "UIView+BlockGesture.h"
#import "UIViewController+JGProgressHUD.h"
#import "UIColor+HEX.h"
#import "UIButton+BarButtonItem.h"
#import "UIView+BorderLine.h"
#import "UIView+Visuals.h"
#import "UIImage+Extension.h"
#import "UIResponder+QFEventHandle.h"
#import "UIScrollView+Extension.h"
#import "UITableView+Extension.h"
#import "UITableViewCell+Extension.h"
#import "UITableViewHeaderFooterView+Extension.h"
#import "UIView+JGProgressHUD.h"
#import "UIWindow+JGProgressHUD.h"
#import "UIViewController+Extension.h"
#import "CALayer+Extension.h"
#import "UIView+SyncedData.h"
#import "UIViewController+HBD.h"

//================================= Util =====================================//
#import "Single.h"
#import "KKEmptyPch.h"
#import "UserInfo.h"
#import "CountDown.h"
#import "PINCache_Header.h"
#import "ScreenBlurry.h"


//================================= Network ==================================//
#import "NSString+API.h"
#import "APPResult.h"
#import "AFNManager.h"
#import "APPViewRequest.h"
#import "UIViewController+APPViewRequest.h"
#import "UIView+APPViewRequest.h"


//================================= Controller ===============================//
#import "HomeController.h"
#import "ChartController.h"
#import "BookController.h"
#import "MineController.h"
#import "LoginController.h"
#import "VerifyController.h"
#import "AssetsController.h"
#import "AboutController.h"
#import "CAController.h"
#import "ACAController.h"
#import "TimeRemindController.h"
#import "InfoController.h"
#import "BillController.h"
#import "WebViewController.h"
#import "FeedbackController.h"
#import "SiriController.h"
#import "ExportController.h"
#import "AutoBookController.h"
#import "BooksController.h"
#import "ShareController.h"
#import "BookDetailController.h"
#import "SearchViewController.h"
#import "PasswordController.h"

//================================= Model ===============================//
#import "MarkModel.h"

#endif
