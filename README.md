## bookkeeping-iOS
[![Current Release](https://img.shields.io/github/release/378056350/bookkeeping-iOS.svg?style=flat-square)](https://github.com/378056350/bookkeeping-iOS/releases)
![License](https://img.shields.io/github/license/378056350/bookkeeping-iOS.svg?style=flat-square)
![Platform](https://img.shields.io/badge/platform-iOS-red.svg?style=flat-square)



### 一. 运行方式

```
1. 终端中 cd ./bookkeeping 目录下
2. 执行 pod install
3. 运行 bookkeeping.xcworkspace
```

### 二. 效果展示

| ![记账](https://github.com/378056350/bookkeeping-iOS/blob/master/gif/0.gif?raw=true) | ![图表](https://github.com/378056350/bookkeeping-iOS/blob/master/gif/1.gif?raw=true) | ![图表](https://github.com/378056350/bookkeeping-iOS/blob/master/gif/2.gif?raw=true) | ![图表](https://github.com/378056350/bookkeeping-iOS/blob/master/gif/3.gif?raw=true) |
| :--------------------------------------: | :--------------------------------------: | :--------------------------------------: | :--------------------------------------: |
|            记账            |            图表            |            增删类别            |            账单            |
| ![记账](https://github.com/378056350/bookkeeping-iOS/blob/master/gif/4.gif?raw=true) | ![图表](https://github.com/378056350/bookkeeping-iOS/blob/master/gif/5.gif?raw=true) | ![图表](https://github.com/378056350/bookkeeping-iOS/blob/master/gif/6.gif?raw=true) | ![图表](https://github.com/378056350/bookkeeping-iOS/blob/master/gif/7.gif?raw=true) |
|            小组件            |            修改账单            |            删除账单            |            添加类别            |






### 三.已完成功能
- [x] 离线缓存、远程同步数据
- [x] 添加、删除记账类别
- [x] 通过图表统计周、月、年的记账信息
- [x] 小组件weiget 记账、查看当月账单
- [x] 开启、关闭明细详情
- [x] 登录、修改个人信息
- [x] 记账计算器实现


### 四.修复上一版问题
- [x] 修复删除本地记账信息过多的问题（删一条把好几条都删了）
- [x] 修复第一次显示图表无效
- [x] 添加同步数据功能
- [x] 分类图标挪至本地


### 五.TODO
- [ ] 优化首页同步数据，分页加载，先获取当月数据显示在页面上，然后在后台请求剩余的数据，一次请求所有，会导致请求变慢，影响用户体验；
- [ ] 优化分享页面 UI；
- [ ] 数据传输接口加密、验签；
- [ ] 集成卡顿检测、内存泄漏检测工具并处理；
- [ ] 记账时是否可以增加一个虚拟ID字段，唯一键值，修改时通过这个虚拟字段，例如，增加时间戳毫秒数字段；
- [ ] 定时提醒界面参考系统的闹钟，提醒内容可以输入，可以设置更多参数；
- [ ] 定时记账记账当天自动添加记账并弹窗提醒，显示知道了、去转账按钮；
- [ ] 登陆页显示隐私协议和用户政策；
- [ ] 首页滑动联动效果，向上滑动隐藏头部，及记账按钮，并将时间显示在标题栏，向下滑动则效果相反；
- [ ] 测试并处理弱网环境、服务器异常时，新增记账、修改记账、删除记账的处理；
- [ ] 搜索展示历史搜索关键词按频次排序；
- [ ] 上拉下拉滚动到第一条位置；
- [ ] 图表页面增加饼状图；
- [ ] 打卡日历统计效果实现；
- [ ] 实现侧边栏滑动及震动效果；
- [ ] 分类图表颜色问题；
- [ ] 夜间模式；
- [ ] 多语言支持；

产品功能描述：

提醒功能，比如每月固定交房租，推送提醒，公众号提醒，短信提醒做补充，如果在App内部则弹窗对话框提醒，按钮有稍后提醒和去转账，去转账则跳转到微信或者支付宝App中，当用户再打开或者回到App中时，询问用户是否转账完成，如果点击完成则自动添加一条记账记录，如果否就不添加，从设置出的提醒中自动解析出记账日期，记账金额和记账类型和备注等信息，解析通过关键字去匹配，不断优化和训练的匹配度；



AI 账单分析，可以通过分析每天吃的食物，蔬菜和水果来分析是否健康，并给出一些建议；

4、通过分析数据做用户画像，比如分析出来你是宝妈，就给宝妈一些饮食建议；5、图片记账功能，通过拍照识别食物，和大概的热量，可以分为两类，一种是标准包装的物品，可以通过扫描条形码识别出来，另一种是非标准的食物，这种就需要靠模型来识别了；还可以从照片中读出位置信息或者时间信息，可以判断出来是午饭还是晚饭；

6、Siri 语音记账，创建iOS 捷径；

7、导出功能，导出Excel表格，导出PDF图标并作为附件发送到邮箱；

8、数据安全问题，传输过程加密；

9、创建一个提醒，目标；

### 六.更多
* 如果您发现了bug 请尽可能详细地描述系统版本、手机型号和复现步骤等信息 提一个issue.
* 如果您有什么好的建议也可以提issue，请各位大佬多提建议.
