//
//  ExportController.m
//  bookkeeping
//
//  Created by PengfeiXin on 2022/7/7.
//  Copyright © 2022 kk. All rights reserved.
//

#import "ExportController.h"
#import <Masonry/Masonry.h>

@interface ExportController ()

@end

@implementation ExportController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.hbd_barHidden = NO;
    self.hbd_barTintColor = kColor_Main_Color;
    [self setNavTitle:@"导出数据"];
    
    [self setupUI];
}

- (void)setupUI {
    // 创建导出按钮
    UIButton *exportButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [exportButton setTitle:@"点击导出数据到文件" forState:UIControlStateNormal];
    [exportButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [exportButton setBackgroundColor:kColor_Main_Color];
    [exportButton.layer setCornerRadius:5.0];
    [exportButton addTarget:self action:@selector(exportToCSV) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:exportButton];
    
    // 设置布局
    [exportButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.centerY.equalTo(self.view);
        make.width.equalTo(@200);
        make.height.equalTo(@44);
    }];
}

- (void)exportToCSV {
    // 1. 获取所有记账数据
    NSMutableArray<BookDetailModel *> *allRecords = [NSUserDefaults getAllBookList];
    
    // 2. 创建CSV内容头部
    NSMutableString *csvString = [NSMutableString stringWithString:@"日期,类别,金额,收支类型,备注\n"];
    
    // 3. 将数据转换为CSV格式
    for (BookDetailModel *model in allRecords) {
        NSString *date = [NSDate stringWithDate:model.date format:@"yyyy-MM-dd"];
        
        // 通过categoryId获取类别
        BKCModel *categoryModel = [NSUserDefaults getCategoryModel:model.categoryId];
        NSString *category = categoryModel.name;
        
        // 根据金额值判断是收入还是支出
        NSString *amount;
        NSString *type;
        
        if (model.categoryId >= 33) {
            amount = [NSString stringWithFormat:@"%.2f", model.price];
            type = @"收入";
        } else {
            amount = [NSString stringWithFormat:@"%.2f", model.price];
            type = @"支出";
        }
        
        NSString *remark = model.mark ?: @"";
        
        // 处理备注中的逗号，用引号包裹防止CSV解析错误
        if ([remark containsString:@","]) {
            remark = [NSString stringWithFormat:@"\"%@\"", remark];
        }
        
        [csvString appendFormat:@"%@,%@,%@,%@,%@\n", date, category, amount, type, remark];
    }
    
    // 4. 保存文件到Documents目录
    NSString *docPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *fileName = [NSString stringWithFormat:@"记账导出_%@.csv", [self getCurrentTimeString]];
    NSString *filePath = [docPath stringByAppendingPathComponent:fileName];
    
    // 创建UTF-8 BOM头
    NSMutableData *csvData = [NSMutableData data];
    // 添加UTF-8 BOM标记 (0xEF 0xBB 0xBF)
    uint8_t bomHeader[] = {0xEF, 0xBB, 0xBF};
    [csvData appendBytes:bomHeader length:sizeof(bomHeader)];
    
    // 将字符串转换为数据并添加到BOM头后面
    NSData *stringData = [csvString dataUsingEncoding:NSUTF8StringEncoding];
    [csvData appendData:stringData];
    
    // 写入文件
    NSError *error = nil;
    BOOL success = [csvData writeToFile:filePath options:NSDataWritingAtomic error:&error];
    
    if (!success) {
        [self showTextHUD:@"导出失败" delay:1.5f];
        return;
    }
    
    // 5. 分享文件
    [self shareFileAtPath:filePath];
}

// 获取当前时间字符串，用于文件名
- (NSString *)getCurrentTimeString {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyyMMdd_HHmmss"];
    return [formatter stringFromDate:[NSDate date]];
}

// 分享文件
- (void)shareFileAtPath:(NSString *)filePath {
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] 
                                           initWithActivityItems:@[fileURL] 
                                           applicationActivities:nil];
    
    [self presentViewController:activityVC animated:YES completion:nil];
}

@end
