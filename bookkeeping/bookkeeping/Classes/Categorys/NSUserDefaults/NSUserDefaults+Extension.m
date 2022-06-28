/**
 * 存储管理
 * @author 郑业强 2019-01-12 创建文件
 */

#import "NSUserDefaults+Extension.h"

static NSMutableArray<BKCModel *> *categoryModelList;

@implementation NSUserDefaults (Extension)


// 取值
+ (id)objectForKey:(NSString *)key {
    NSError *error = nil;
    NSUserDefaults *sharedData = [[NSUserDefaults alloc] initWithSuiteName:@"group.xpf.widget"];
    id obj = [sharedData objectForKey:key];
    //obj = [NSKeyedUnarchiver unarchiveObjectWithData:obj];
    NSKeyedUnarchiver* unarchiver = [[NSKeyedUnarchiver alloc] initForReadingFromData:obj error:&error];
    unarchiver.requiresSecureCoding = NO;
    obj = [unarchiver decodeTopLevelObjectForKey:NSKeyedArchiveRootObjectKey error:&error];
    return obj;
}

// 存值
+ (void)setObject:(id)obj forKey:(NSString *)key {
    NSError *error = nil;
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:obj requiringSecureCoding:NO error:&error];
    NSUserDefaults *sharedData = [[NSUserDefaults alloc] initWithSuiteName:@"group.xpf.widget"];
    [sharedData setObject:data forKey:key];
    [sharedData synchronize];
}

// 删除记账
+ (void)removeBookModel:(BookDetailModel *)model {
    NSMutableArray<BookDetailModel *> *bookArr = [NSUserDefaults objectForKey:All_BOOK_LIST];
    for (int i= 0; i<bookArr.count; i++) {
        BookDetailModel *subModel = bookArr[i];
        if (subModel.bookId == model.bookId) {
            [bookArr removeObjectAtIndex:i];
            break;
        }
    }
    [NSUserDefaults setObject:bookArr forKey:All_BOOK_LIST];
}

// 添加记账
+ (void)insertBookModel:(BookDetailModel *)model {
    NSMutableArray *bookArr = [NSUserDefaults objectForKey:All_BOOK_LIST];
    [bookArr addObject:model];
    [NSUserDefaults setObject:bookArr forKey:All_BOOK_LIST];
}

+ (void)saveAllBookList:(NSMutableArray *)array {
    [NSUserDefaults setObject:array forKey:All_BOOK_LIST];
}

+ (NSMutableArray<BookDetailModel *> *)getAllBookList {
    NSMutableArray<BookDetailModel *> *models = [NSUserDefaults objectForKey:All_BOOK_LIST];
    return models;
}

+ (void)saveMonthModelList:(NSInteger)year month:(NSInteger)month array:(NSMutableArray *)array {
    // 拼接key: 年 + 月 + BOOK_DETAIL, 例：202206_BOOK_DETAIL
    NSString *key = [NSString stringWithFormat:@"%ld%ld_BOOK_DETAIL", year, month];
    [NSUserDefaults setObject:array forKey:key];
}

+ (NSMutableArray<BookMonthModel *> *)getMonthModelList:(NSInteger)year month:(NSInteger)month {
    NSString *key = [NSString stringWithFormat:@"%ld%ld_BOOK_DETAIL", year, month];
    NSMutableArray<BookMonthModel *> *models = [NSUserDefaults objectForKey:key];
    return models;
}

// 修改记账
+ (void)replaceBookModel:(BookDetailModel *)model {
    NSMutableArray *bookArr = [NSUserDefaults objectForKey:All_BOOK_LIST];
    for (int i= 0; i<bookArr.count; i++) {
        BookDetailModel *subModel = bookArr[i];
        if (subModel.bookId == model.bookId) {
            [bookArr replaceObjectAtIndex:i withObject:model];
            break;
        }
    }
    [NSUserDefaults setObject:bookArr forKey:All_BOOK_LIST];
}

// 修改本地记账
+ (void)updateBookModel:(BookDetailModel *)model {
    NSString *key = [NSString stringWithFormat:@"%ld%ld_BOOK_DETAIL", model.year, model.month];
    NSMutableArray<BookMonthModel *> *models = [NSUserDefaults objectForKey:key];
    [models removeAllObjects];
    [NSUserDefaults setObject:models forKey:key];
}

// 删除本地记账
+ (void)deleteBookModel:(BookDetailModel *)model {
    NSString *key = [NSString stringWithFormat:@"%ld%ld_BOOK_DETAIL", model.year, model.month];
    NSMutableArray<BookMonthModel *> *models = [NSUserDefaults objectForKey:key];
    [models removeAllObjects];
    [NSUserDefaults setObject:models forKey:key];
}

// 添加分类
+ (void)insertCategoryModel:(BKCModel *)model is_income:(BOOL)is_income {
    if (is_income == 0) {
        NSMutableArray *sysHasArr = [NSUserDefaults objectForKey:PIN_CATE_SYS_HAS_PAY];
        NSMutableArray *sysRemoveArr = [NSUserDefaults objectForKey:PIN_CATE_SYS_REMOVE_PAY];
        NSMutableArray *sysHasSyncedArr = [NSUserDefaults objectForKey:PIN_CATE_SYS_Has_PAY_SYNCED];
        NSMutableArray *sysRemoveSyncedArr = [NSUserDefaults objectForKey:PIN_CATE_SYS_REMOVE_PAY_SYNCED];
        
        [sysHasArr addObject:model];
        if ([sysRemoveSyncedArr containsObject:model]) {
            [sysRemoveSyncedArr removeObject:model];
        } else {
            [sysHasSyncedArr addObject:model];
        }
        [sysRemoveArr removeObject:model];
        
        [NSUserDefaults setObject:sysHasArr forKey:PIN_CATE_SYS_HAS_PAY];
        [NSUserDefaults setObject:sysRemoveArr forKey:PIN_CATE_SYS_REMOVE_PAY];
        [NSUserDefaults setObject:sysHasSyncedArr forKey:PIN_CATE_SYS_Has_PAY_SYNCED];
        [NSUserDefaults setObject:sysRemoveSyncedArr forKey:PIN_CATE_SYS_REMOVE_PAY_SYNCED];
    } else if (is_income == 1) {
        NSMutableArray *sysHasArr = [NSUserDefaults objectForKey:PIN_CATE_SYS_HAS_INCOME];
        NSMutableArray *sysRemoveArr = [NSUserDefaults objectForKey:PIN_CATE_SYS_REMOVE_INCOME];
        NSMutableArray *sysHasSyncedArr = [NSUserDefaults objectForKey:PIN_CATE_SYS_Has_INCOME_SYNCED];
        NSMutableArray *sysRemoveSyncedArr = [NSUserDefaults objectForKey:PIN_CATE_SYS_REMOVE_INCOME_SYNCED];
        
        [sysHasArr addObject:model];
        if ([sysRemoveSyncedArr containsObject:model]) {
            [sysRemoveSyncedArr removeObject:model];
        } else {
            [sysHasSyncedArr addObject:model];
        }
        [sysRemoveArr removeObject:model];
        
        [NSUserDefaults setObject:sysHasArr forKey:PIN_CATE_SYS_HAS_INCOME];
        [NSUserDefaults setObject:sysRemoveArr forKey:PIN_CATE_SYS_REMOVE_INCOME];
        [NSUserDefaults setObject:sysHasSyncedArr forKey:PIN_CATE_SYS_Has_INCOME_SYNCED];
        [NSUserDefaults setObject:sysRemoveSyncedArr forKey:PIN_CATE_SYS_REMOVE_INCOME_SYNCED];
    }
}

// 删除分类
+ (void)removeCategoryModel:(BKCModel *)model is_income:(BOOL)is_income {
    // 系统原有
    if (model.is_system == true) {
        if (is_income == false) {
            NSMutableArray<BKCModel *> *sysHasArr = [NSUserDefaults objectForKey:PIN_CATE_SYS_HAS_PAY];
            NSMutableArray<BKCModel *> *sysRemoveArr = [NSUserDefaults objectForKey:PIN_CATE_SYS_REMOVE_PAY];
            NSMutableArray<BKCModel *> *sysHasSyncedArr = [NSUserDefaults objectForKey:PIN_CATE_SYS_Has_PAY_SYNCED];
            NSMutableArray<BKCModel *> *sysRemoveSyncedArr = [NSUserDefaults objectForKey:PIN_CATE_SYS_REMOVE_PAY_SYNCED];
            
            [sysRemoveArr addObject:model];
            if ([sysHasSyncedArr containsObject:model]) {
                [sysHasSyncedArr removeObject:model];
            } else {
                [sysRemoveSyncedArr addObject:model];
            }
            [sysHasArr removeObject:model];
            
            [NSUserDefaults setObject:sysHasArr forKey:PIN_CATE_SYS_HAS_PAY];
            [NSUserDefaults setObject:sysRemoveArr forKey:PIN_CATE_SYS_REMOVE_PAY];
            [NSUserDefaults setObject:sysHasSyncedArr forKey:PIN_CATE_SYS_Has_PAY_SYNCED];
            [NSUserDefaults setObject:sysRemoveSyncedArr forKey:PIN_CATE_SYS_REMOVE_PAY_SYNCED];
            
            
            NSString *preStr = [NSString stringWithFormat:@"cmodel.Id != %ld", model.Id];
            NSMutableArray<BookDetailModel *> *book = [NSUserDefaults objectForKey:PIN_BOOK];
            NSMutableArray<BookDetailModel *> *book_synced = [NSUserDefaults objectForKey:PIN_BOOK_SYNCED];
            book = [NSMutableArray kk_filteredArrayUsingPredicate:preStr array:book];
            book_synced = [NSMutableArray kk_filteredArrayUsingPredicate:preStr array:book_synced];
            [NSUserDefaults setObject:book forKey:PIN_BOOK];
            [NSUserDefaults setObject:book forKey:PIN_BOOK_SYNCED];
            
        }
        else if (is_income == true) {
            NSMutableArray<BKCModel *> *sysHasArr = [NSUserDefaults objectForKey:PIN_CATE_SYS_HAS_INCOME];
            NSMutableArray<BKCModel *> *sysRemoveArr = [NSUserDefaults objectForKey:PIN_CATE_SYS_REMOVE_INCOME];
            NSMutableArray<BKCModel *> *sysHasSyncedArr = [NSUserDefaults objectForKey:PIN_CATE_SYS_Has_INCOME_SYNCED];
            NSMutableArray<BKCModel *> *sysRemoveSyncedArr = [NSUserDefaults objectForKey:PIN_CATE_SYS_REMOVE_INCOME_SYNCED];
            
            [sysRemoveArr addObject:model];
            if ([sysHasSyncedArr containsObject:model]) {
                [sysHasSyncedArr removeObject:model];
            } else {
                [sysRemoveSyncedArr addObject:model];
            }
            [sysHasArr removeObject:model];
            
            [NSUserDefaults setObject:sysHasArr forKey:PIN_CATE_SYS_HAS_INCOME];
            [NSUserDefaults setObject:sysRemoveArr forKey:PIN_CATE_SYS_REMOVE_INCOME];
            [NSUserDefaults setObject:sysHasSyncedArr forKey:PIN_CATE_SYS_Has_INCOME_SYNCED];
            [NSUserDefaults setObject:sysRemoveSyncedArr forKey:PIN_CATE_SYS_REMOVE_INCOME_SYNCED];
            
            
            NSString *preStr = [NSString stringWithFormat:@"cmodel.Id != %ld", model.Id];
            NSMutableArray<BookDetailModel *> *book = [NSUserDefaults objectForKey:PIN_BOOK];
            NSMutableArray<BookDetailModel *> *book_synced = [NSUserDefaults objectForKey:PIN_BOOK_SYNCED];
            book = [NSMutableArray kk_filteredArrayUsingPredicate:preStr array:book];
            book_synced = [NSMutableArray kk_filteredArrayUsingPredicate:preStr array:book_synced];
            [NSUserDefaults setObject:book forKey:PIN_BOOK];
            [NSUserDefaults setObject:book forKey:PIN_BOOK_SYNCED];
        }
    }
    // 自定义
    else {
        if (is_income == false) {
            NSMutableArray *cusHasPayArr = [NSUserDefaults objectForKey:PIN_CATE_CUS_HAS_PAY];
            NSMutableArray *cusHasPaySyncedArr = [NSUserDefaults objectForKey:PIN_CATE_CUS_HAS_PAY_SYNCED];
            NSMutableArray *cusRemovePaySyncedArr = [NSUserDefaults objectForKey:PIN_CATE_CUS_REMOVE_PAY_SYNCED];
            [cusHasPayArr removeObject:model];
            if ([cusHasPaySyncedArr containsObject:model]) {
                [cusHasPaySyncedArr removeObject:model];
            } else {
                [cusRemovePaySyncedArr addObject:model];
            }
            [NSUserDefaults setObject:cusHasPayArr forKey:PIN_CATE_CUS_HAS_PAY];
            [NSUserDefaults setObject:cusHasPaySyncedArr forKey:PIN_CATE_CUS_HAS_PAY_SYNCED];
            [NSUserDefaults setObject:cusRemovePaySyncedArr forKey:PIN_CATE_CUS_REMOVE_PAY_SYNCED];
            
            
            NSString *preStr = [NSString stringWithFormat:@"cmodel.Id != %ld", model.Id];
            NSMutableArray<BookDetailModel *> *book = [NSUserDefaults objectForKey:PIN_BOOK];
            NSMutableArray<BookDetailModel *> *book_synced = [NSUserDefaults objectForKey:PIN_BOOK_SYNCED];
            book = [NSMutableArray kk_filteredArrayUsingPredicate:preStr array:book];
            book_synced = [NSMutableArray kk_filteredArrayUsingPredicate:preStr array:book_synced];
            [NSUserDefaults setObject:book forKey:PIN_BOOK];
            [NSUserDefaults setObject:book forKey:PIN_BOOK_SYNCED];
            
            
            
        } else if (is_income == true) {
            NSMutableArray *cusHasIcomeEArr = [NSUserDefaults objectForKey:PIN_CATE_CUS_HAS_INCOME];
            NSMutableArray *cusHasIncomeSyncedArr = [NSUserDefaults objectForKey:PIN_CATE_CUS_HAS_INCOME_SYNCED];
            NSMutableArray *cusRemoveIncomeSyncedArr = [NSUserDefaults objectForKey:PIN_CATE_CUS_REMOVE_INCOME_SYNCED];
            [cusHasIcomeEArr removeObject:model];
            if ([cusHasIncomeSyncedArr containsObject:model]) {
                [cusHasIncomeSyncedArr removeObject:model];
            } else {
                [cusRemoveIncomeSyncedArr addObject:model];
            }
            [NSUserDefaults setObject:cusHasIcomeEArr forKey:PIN_CATE_CUS_HAS_INCOME];
            [NSUserDefaults setObject:cusHasIncomeSyncedArr forKey:PIN_CATE_CUS_HAS_INCOME_SYNCED];
            [NSUserDefaults setObject:cusRemoveIncomeSyncedArr forKey:PIN_CATE_CUS_REMOVE_INCOME_SYNCED];
            
            
            NSString *preStr = [NSString stringWithFormat:@"cmodel.Id != %ld", model.Id];
            NSMutableArray<BookDetailModel *> *book = [NSUserDefaults objectForKey:PIN_BOOK];
            NSMutableArray<BookDetailModel *> *book_synced = [NSUserDefaults objectForKey:PIN_BOOK_SYNCED];
            book = [NSMutableArray kk_filteredArrayUsingPredicate:preStr array:book];
            book_synced = [NSMutableArray kk_filteredArrayUsingPredicate:preStr array:book_synced];
            [NSUserDefaults setObject:book forKey:PIN_BOOK];
            [NSUserDefaults setObject:book forKey:PIN_BOOK_SYNCED];
        }
    }
    
    
    // 删除同类别信息
    NSMutableArray<BookDetailModel *> *arrm = [NSUserDefaults objectForKey:PIN_BOOK];
    NSString *preStr = [NSString stringWithFormat:@"cmodel.Id == %ld", model.Id];
    arrm = [NSMutableArray kk_filteredArrayUsingPredicate:preStr array:arrm];
    [NSUserDefaults setObject:arrm forKey:PIN_BOOK];
}

// 获取分类
+ (NSMutableArray *)getCategoryModel {
    NSMutableArray<BKCModel *> *sysHasPayArr = [NSUserDefaults objectForKey:PIN_CATE_SYS_HAS_PAY];
    NSMutableArray<BKCModel *> *cusHasPayArr = [NSUserDefaults objectForKey:PIN_CATE_CUS_HAS_PAY];
    NSMutableArray<BKCModel *> *sysRemovePayArr = [NSUserDefaults objectForKey:PIN_CATE_SYS_REMOVE_PAY];
    
    CategoryListModel *model1 = [[CategoryListModel alloc] init];
    model1.is_income = 0;
    model1.remove = sysRemovePayArr;
    model1.insert = ({
        NSMutableArray *arrm = [NSMutableArray arrayWithArray:sysHasPayArr];
        [arrm addObjectsFromArray:cusHasPayArr];
        arrm;
    });

    NSMutableArray<BKCModel *> *sysHasIncomeArr = [NSUserDefaults objectForKey:PIN_CATE_SYS_HAS_INCOME];
    NSMutableArray<BKCModel *> *cusHasIcomeEArr = [NSUserDefaults objectForKey:PIN_CATE_CUS_HAS_INCOME];
    NSMutableArray<BKCModel *> *sysRemoveIncomeArr = [NSUserDefaults objectForKey:PIN_CATE_SYS_REMOVE_INCOME];

    CategoryListModel *model2 = [[CategoryListModel alloc] init];
    model2.is_income = 1;
    model2.remove = sysRemoveIncomeArr;
    model2.insert = ({
        NSMutableArray *arrm = [NSMutableArray arrayWithArray:sysHasIncomeArr];
        [arrm addObjectsFromArray:cusHasIcomeEArr];
        arrm;
    });

    return [NSMutableArray arrayWithArray:@[model1, model2]];
}

+ (NSMutableArray<BKCModel *> *) getCategoryModelList{
    if (categoryModelList) {
        return categoryModelList;
    }
    // 分类：从 SC.plist 文件中读取默认的分类数据
    NSString *systemCatePath = [[NSBundle mainBundle] pathForResource:@"SC" ofType:@"plist"];
    NSDictionary *systemCateDic = [NSDictionary dictionaryWithContentsOfFile:systemCatePath];
    // 支出分类
    NSMutableArray *pay = [NSMutableArray arrayWithArray:systemCateDic[@"pay"]];
    // 收入分类
    NSMutableArray *income = [NSMutableArray arrayWithArray:systemCateDic[@"income"]];
    // 合并
    [pay addObjectsFromArray:income];
    // 字典数组转模型数组
    categoryModelList = [BKCModel mj_objectArrayWithKeyValuesArray:pay];
    
    return categoryModelList;
}

+ (BKCModel *) getCategoryModel:(NSInteger)categoryId{
    NSMutableArray<BKCModel *> *categoryList = [NSUserDefaults getCategoryModelList];
    BKCModel *categoryModel;
    for (BKCModel *model in categoryList) {
        if (model.Id == categoryId) {
            categoryModel = model;
            break;
        }
    }
    return categoryModel;
}

+ (void)load {
    BOOL isFirst = [NSUserDefaults objectForKey:PIN_FIRST_RUN];
    // 第一次运行
    if (!isFirst) {
        // 分类：从 SC.plist 文件中读取默认的分类数据
        NSString *systemCatePath = [[NSBundle mainBundle] pathForResource:@"SC" ofType:@"plist"];
        NSDictionary *systemCateDic = [NSDictionary dictionaryWithContentsOfFile:systemCatePath];
        // 支出分类
        NSMutableArray *pay = [NSMutableArray arrayWithArray:systemCateDic[@"pay"]];
        // 收入分类
        NSMutableArray *income = [NSMutableArray arrayWithArray:systemCateDic[@"income"]];
        
        pay = [BKCModel mj_objectArrayWithKeyValuesArray:pay];
        income = [BKCModel mj_objectArrayWithKeyValuesArray:income];
        
        // 支出
        [NSUserDefaults setObject:pay forKey:PIN_CATE_SYS_HAS_PAY];
        [NSUserDefaults setObject:[NSMutableArray array] forKey:PIN_CATE_SYS_REMOVE_PAY];
        [NSUserDefaults setObject:[NSMutableArray array] forKey:PIN_CATE_CUS_HAS_PAY];
        [NSUserDefaults setObject:[NSMutableArray array] forKey:PIN_CATE_SYS_Has_PAY_SYNCED];
        [NSUserDefaults setObject:[NSMutableArray array] forKey:PIN_CATE_SYS_REMOVE_PAY_SYNCED];
        [NSUserDefaults setObject:[NSMutableArray array] forKey:PIN_CATE_CUS_HAS_PAY_SYNCED];
        [NSUserDefaults setObject:[NSMutableArray array] forKey:PIN_CATE_CUS_REMOVE_PAY_SYNCED];
        
        // 收入
        [NSUserDefaults setObject:income forKey:PIN_CATE_SYS_HAS_INCOME];
        [NSUserDefaults setObject:[NSMutableArray array] forKey:PIN_CATE_SYS_REMOVE_INCOME];
        [NSUserDefaults setObject:[NSMutableArray array] forKey:PIN_CATE_CUS_HAS_INCOME];
        [NSUserDefaults setObject:[NSMutableArray array] forKey:PIN_CATE_SYS_Has_INCOME_SYNCED];
        [NSUserDefaults setObject:[NSMutableArray array] forKey:PIN_CATE_SYS_REMOVE_INCOME_SYNCED];
        [NSUserDefaults setObject:[NSMutableArray array] forKey:PIN_CATE_CUS_HAS_INCOME_SYNCED];
        [NSUserDefaults setObject:[NSMutableArray array] forKey:PIN_CATE_CUS_REMOVE_INCOME_SYNCED];
        
        // 添加类别 从 ACA.plist 文件中读取默认的分类数据
        NSString *acaPath = [[NSBundle mainBundle] pathForResource:@"ACA" ofType:@"plist"];
        NSMutableArray *acaArr = [NSMutableArray arrayWithContentsOfFile:acaPath];
        acaArr = [ACAListModel mj_objectArrayWithKeyValuesArray:acaArr];
        [NSUserDefaults setObject:acaArr forKey:PIN_ACA_CATE];
        
        // 记账
        [NSUserDefaults setObject:[NSMutableArray array] forKey:PIN_BOOK];
        [NSUserDefaults setObject:[NSMutableArray array] forKey:PIN_BOOK_SYNCED];
        
        // FaceID
        [NSUserDefaults setObject:@(0) forKey:PIN_SETTING_FACE_ID];
        // 定时提醒
        [NSUserDefaults setObject:[NSMutableArray array] forKey:PIN_TIMING];
        // 第一次运行
        [NSUserDefaults setObject:@(1) forKey:PIN_FIRST_RUN];
    }
}


@end
