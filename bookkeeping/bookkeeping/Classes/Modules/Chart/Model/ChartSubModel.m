/**
 * 子时间范围
 * @author 郑业强 2018-12-29 创建文件
 */

#import "ChartSubModel.h"

@implementation ChartSubModel

+ (instancetype)init {
    ChartSubModel *model = [[ChartSubModel alloc] init];
    model.year = -1;
    model.month = -1;
    model.day = -1;
    model.week = -1;
    return model;
}

- (NSString *)detail {
    NSDate *date = [NSDate date];
    
    // 周
    if (_selectIndex == 0) {
        date = [date offsetDays:-[date weekday] + 1];
        if ([date year] == _year && [date month] == _month && [date day] == _day) {
            return @"本周";
        } else if ([date year] == _year) {
            return [NSString stringWithFormat:@"%02ld周", _week];
        } else {
            // 判断如果是今年的第一周，则不显示年份
            // 请帮我修复 bug, 本来今年的第一周显示的是：“01周”，但是显示的是：“2023年01周”
//            if (_week == 1) {
//                return [NSString stringWithFormat:@"%02ld周", _week];
//            }
            return [NSString stringWithFormat:@"%ld年%02ld周", _year, _week];
        }
    }
    // 月
    else if (_selectIndex == 1) {
        if ([date month] == _month && [date year] == _year) {
            return @"本月";
        } else if ([date year] == _year) {
            return [NSString stringWithFormat:@"%02ld月", _month];
        } else {
            return [NSString stringWithFormat:@"%ld年%02ld月", _year, _month];
        }
    }
    // 年
    else if (_selectIndex == 2) {
        if ([date year] == _year) {
            return @"今年";
        } else {
            return [NSString stringWithFormat:@"%ld年", _year];
        }
    }
    return @"";
}

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[ChartSubModel class]]) {
        ChartSubModel *model = (ChartSubModel *)object;
        if (_year == model.year && _month == model.month && _day == model.day) {
            return true;
        }
        return false;
    }
    return false;
}

@end
