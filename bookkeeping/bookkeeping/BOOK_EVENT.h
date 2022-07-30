/**
 * 记账事件
 * @author 郑业强 2018-12-17 创建文件
 */

#ifndef BOOK_EVENT_h
#define BOOK_EVENT_h

#define BOOK_CLICK_NAVIGATION @"BOOK_CLICK_NAVIGATION"  // 点击导航栏
#define BOOK_CLICK_ITEM @"BOOK_CLICK_ITEM"              // 点击 Item
#define BOOK_ITEM_SELECT @"BOOK_ITEM_SELECT"            // Item 选中

// 通知
#define NOTIFICATION_BOOK_ADD       @"NOTIFICATION_BOOK_ADD"          // 记账完成
#define NOTIFICATION_BOOK_DELETE    @"NOTIFICATION_BOOK_DELETE"       // 记账删除
#define NOTIFICATION_BOOK_UPDATE    @"NOTIFICATION_BOOK_UPDATE"       // 记账修改
#define SYNCED_DATA_COMPLETE        @"SYNCED_DATA_COMPLETE"           // 同步完成
#define NOTIFICATION_BOOK_UPDATE_HOME    @"NOTIFICATION_BOOK_UPDATE_HOME" // 更新首页数据

// ================== home ======================================
#define HOME_TABLE_PULL     @"HOME_TABLE_PULL"      // 下拉
#define HOME_TABLE_UP       @"HOME_TABLE_UP"        // 上拉
#define HOME_MONTH_CLICK    @"HOME_MONTH_CLICK"     // 点击月份
#define HOME_CELL_REMOVE    @"HOME_CELL_REMOVE"     // 删除
#define HOME_CELL_CLICK     @"HOME_CELL_CLICK"      // 点击
#define HOME_PAY_CLICK      @"HOME_PAY_CLICK"       // 支出点击
#define HOME_INCOME_CLICK   @"HOME_INCOME_CLICK"    // 收入点击

// ================== search ======================================
#define SEARCH_CELL_REMOVE    @"SEARCH_CELL_REMOVE"     // 删除
#define SEARCH_CELL_CLICK     @"SEARCH_CELL_CLICK"      // 点击
#define SEARCH_TEXT_INPUT     @"SEARCH_TEXT_INPUT"      // 文字输入
#define SEARCH_BACK           @"SEARCH_BACK"            // 返回

// ================== category ======================================
#define ACA_CLICK_ITEM @"ACA_CLICK_ITEM"    // 点击item
#define CATEGORY_BTN_CLICK   @"CATEGORY_BTN_CLICK"        // 添加分类
#define CATEGORY_LONG_GESTURE @"CATEGORY_LONG_GESTURE"    // 长按手势
#define CATEGORY_ACTION_CLICK @"CATEGORY_ACTION_CLICK"    // 删除/添加
#define CATEGORY_ACTION_DELETE_CLICK @"CATEGORY_ACTION_DELETE_CLICK"    // 删除
#define CATEGORY_ACTION_INSERT_CLICK @"CATEGORY_ACTION_INSERT_CLICK"    // 添加
#define CATEGORY_SEG_CHANGE @"CATEGORY_SEG_CHANGE"        // 更改seg

// ================== mine ======================================
#define MINE_DID_SCROLL             @"MINE_DID_SCROLL"           // scroll 滚动
#define MINE_CELL_CLICK             @"MINE_CELL_CLICK"           // cell 点击
#define MINE_HEADER_ICON_CLICK      @"MINE_HEADER_ICON_CLICK"    // 头像点击
#define MINE_HEADER_DAY_CLICK       @"MINE_HEADER_DAY_CLICK"     // 总天数点击
#define MINE_HEADER_NUMBER_CLICK    @"MINE_HEADER_NUMBER_CLICK"  // 总笔数点击
#define MINE_FACE_ID_CLICK          @"MINE_FACE_ID_CLICK"        // FaceID 开关
#define MINE_TOKEN_EXPIRED          @"MINE_TOKEN_EXPIRED"        // token 过期

// ================== timing ======================================
#define TIMING_CELL_DELETE @"TIMING_CELL_DELETE"    // 删除cell

// ================== info ======================================
#define INFO_CELL_CLICK @"INFO_CELL_CLICK"      // 点击cell
#define INFO_FOOTER_CLICK @"INFO_FOOTER_CLICK"  // 点击尾视图

// ================== chart ======================================
#define CHART_CHART_TOUCH_BEGIN  @"CHART_CHART_TOUCH_BEGIN"   // 点击图表
#define CHART_CHART_TOUCH_END    @"CHART_CHART_TOUCH_END"     // 结束图表
#define CHART_CHART_TOUCH_CANNEL @"CHART_CHART_TOUCH_CANNEL"  // 取消点击图表
#define CHART_TABLE_CLICK        @"CHART_TABLE_CLICK"         // 点击列表

// ================== detail ======================================
#define BD_BOTTOM_CLICK     @"BD_BOTTOM_CLICK"  // 点击按钮

// ================== login ======================================
#define USER_LOGIN_COMPLETE    @"USER_LOGIN_COMPLETE"     // 登录完成
#define BIND_PHONE_COMPLETE    @"BIND_PHONE_COMPLETE"     // 绑定手机
#define USER_LOGOUT_COMPLETE   @"USER_LOGOUT_COMPLETE"    // 退出登录

#endif
