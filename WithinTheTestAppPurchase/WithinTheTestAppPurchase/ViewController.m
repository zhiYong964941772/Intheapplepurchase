//
//  ViewController.m
//  WithinTheTestAppPurchase
//
//  Created by zhiyong Lai on 2017/6/12.
//  Copyright © 2017年 zhiYong_lai. All rights reserved.
//

#import "ViewController.h"
@import StoreKit;//导入头文件
@interface ViewController ()<SKPaymentTransactionObserver,SKProductsRequestDelegate>//遵守代理
{
    
}
@end
#define payCode @"NOLai"
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];//设置当前视图为这个内购队列的观察者。
    }
- (void)requestPayCode:(nonnull NSString *)code{
    
    NSSet *codeSet = [NSSet setWithObject:code];//创建内购码集
    SKProductsRequest *request = [[SKProductsRequest alloc]initWithProductIdentifiers:codeSet];//创建内购请求
    request.delegate = self;
    [request start];
}
#pragma mark -- SKProductsRequestDelegate

/**
 获取产品信息

 @param request 产品信息请求
 @param response 返回的数据包
 */
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response{
    NSArray *productArr = response.products;
    if ([productArr count]==0) {
        NSLog(@"商品不存在");
        return;
    }
    NSLog(@"code == %@,产品付费数量 == %lu",response.invalidProductIdentifiers,(unsigned long)productArr.count);
    SKProduct *p = nil;//商品信息model
    for (SKProduct *pro in productArr) {
        p = ([pro.productIdentifier isEqualToString:payCode])?pro:nil;
    }
    SKPayment *pm = [SKPayment paymentWithProduct:p];//根据产品信息，返回一个新的支付指定的产品
    [[SKPaymentQueue defaultQueue] addPayment:pm];//添加一个付款请求队列
}
#pragma mark -- SKRequestDelegate
- (void)requestDidFinish:(SKRequest *)request{
    
}
- (void)request:(SKRequest *)request didFailWithError:(NSError *)error{
    NSLog(@"%@",error.domain);
}
#pragma mark -- SKPaymentTransactionObserver
//监听购买结果

/**
 监听购买结果

 @param queue 购买请求队列
 @param transactions 交易处理的数据
 注意：这里购买的账号必须要填写沙箱测试员的账号
 在使用前，要先去appstore注销原来的账号
 */
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions{
    for (SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchased: //交易完成
                [self purchaseOfValidation];// 发送到苹果服务器验证凭证

                [[SKPaymentQueue defaultQueue]finishTransaction:transaction];
                break;
            case SKPaymentTransactionStatePurchasing: //商品添加进列表
                
                break;
            case SKPaymentTransactionStateRestored: //购买过
                [self purchaseOfValidation];// 发送到苹果服务器验证凭证
                
                [[SKPaymentQueue defaultQueue]finishTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed: //交易失败
                
                [[SKPaymentQueue defaultQueue]finishTransaction:transaction];
                NSLog(@"购买失败");
                break;
                
            default:
                break;
        }
    }
}
//沙盒测试环境验证
#define SANDBOXPAY @"https://sandbox.itunes.apple.com/verifyReceipt"
//正式环境验证
#define AppStorePAY @"https://buy.itunes.apple.com/verifyReceipt"
// 验证购买
- (void)purchaseOfValidation {
    
    // 验证凭据，获取到苹果返回的交易凭据
    // appStoreReceiptURL iOS7.0增加的，购买交易完成后，会将凭据存放在该地址
    NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
    // 从沙盒中获取到购买凭据
    NSData *receiptData = [NSData dataWithContentsOfURL:receiptURL];
    // 发送网络POST请求，对购买凭据进行验证
    //测试验证地址:https://sandbox.itunes.apple.com/verifyReceipt
    //正式验证地址:https://buy.itunes.apple.com/verifyReceipt
    NSURL *url = [NSURL URLWithString:SANDBOXPAY];
    NSMutableURLRequest *urlRequest =
    [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10.0f];
    urlRequest.HTTPMethod = @"POST";
    NSString *encodeStr = [receiptData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
    NSString *payload = [NSString stringWithFormat:@"{\"receipt-data\" : \"%@\"}", encodeStr];
    NSData *payloadData = [payload dataUsingEncoding:NSUTF8StringEncoding];
    urlRequest.HTTPBody = payloadData;
    // 提交验证请求，并获得官方的验证JSON结果 iOS9后更改了另外的一个方法
    NSData *result = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:nil error:nil];
    NSURLSession *session = [NSURLSession sharedSession];
    [session dataTaskWithRequest:urlRequest];
    
    // 官方验证结果为空
    if (result == nil) {
        NSLog(@"验证失败");
        return;
    }
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:result options:NSJSONReadingAllowFragments error:nil];
    if (dict != nil) {
        // 比对字典中以下信息基本上可以保证数据安全
        // bundle_id , application_version , product_id , transaction_id
        NSLog(@"验证成功！购买的商品是：%@", @"_productName");
    }
    
}
#pragma mark -- 多个内购项目的时候，设置多几个按钮即可
- (IBAction)payBtn:(UIButton *)sender {
    //判断是否支持内购
    if ([SKPaymentQueue canMakePayments]) {
        [self requestPayCode:payCode];
    }else{
        NSLog(@"暂无权限");
    }

}
- (void)dealloc{
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];//移除观察者
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
