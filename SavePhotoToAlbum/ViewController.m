//
//  ViewController.m
//  SavePhotoToAlbum
//
//  Created by MrHuang on 17/7/2.
//  Copyright © 2017年 Mrhuang. All rights reserved.
//

#import "ViewController.h"
#import <Photos/Photos.h>
#import <SVProgressHUD.h>


@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (nonatomic ,strong) UIButton * SaveButton;

//创建App对应的自定义相册。
-(PHAssetCollection *)createdCollection;
//返回那张保存到相机胶卷的那张图片
-(PHFetchResult<PHAsset *> *)createdAssets;



@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    
}


#pragma mark - 创建对应的App名称相册

-(PHAssetCollection *)createdCollection{
    
    //拿到app名称
    
    NSString * title = [NSBundle mainBundle].infoDictionary[(NSString *)kCFBundleNameKey];

    //查找所有的相册
    
    PHFetchResult<PHAssetCollection *> *collections = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    
    //遍历所有查找到的相册
    for (PHAssetCollection *collection in collections) {
        
        //如果相册的名称 和app名称一样 则说明已经创建了相册
        if ([collection.localizedTitle isEqualToString:title]) {
            
            return collection;
            break;
        }
        
    }
    
    
    /**如果相册没被创建过则创建相册**/
    NSError *error = nil;
    __block NSString *collcetionID = nil;
    
    //创建一个自定义相册
    [[PHPhotoLibrary sharedPhotoLibrary]performChangesAndWait:^{
        //拿到占位相册的唯一标示
        collcetionID = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:title].placeholderForCreatedAssetCollection.localIdentifier;
        
    } error:&error];
    
    //根据唯一标示ID 来创建自定义相册
    return  [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[collcetionID] options:nil].firstObject;
    
    
    if (error) {
        
        [SVProgressHUD showErrorWithStatus:@"创建自定义相册失败!!!"];
        
        return nil;
    }
    
}


#pragma mark - 返回那张保存到相机胶卷的图片
-(PHFetchResult<PHAsset *> *)createdAssets{
    
    NSError *error = nil;
    __block NSString *AssetID = nil;
    //保存图片到相机胶卷
    
    [[PHPhotoLibrary sharedPhotoLibrary]performChangesAndWait:^{
        
        //拿到相册的占位图片对象的唯一标识符
        AssetID = [PHAssetChangeRequest creationRequestForAssetFromImage:self.imageView.image].placeholderForCreatedAsset.localIdentifier;
        
    } error:&error];
    
    if (error) return nil;
    //通过唯一标识符获取相片返回
    return [PHAsset fetchAssetsWithLocalIdentifiers:@[AssetID] options:nil];
}




- (IBAction)Save:(id)sender {
    
    //拿到相册之前的授权状态
    PHAuthorizationStatus * oldSatus = [PHPhotoLibrary authorizationStatus];
    
    //请求/检查访问权限：
    //如果用户还没做出选择，会自动弹框，用户对弹框做出选择之后才会调用block
    //如果之前已经做过选择，会直接执行block
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        NSLog(@"%@", [NSThread currentThread]);
        //UI刷新必须在主线程中
        dispatch_async(dispatch_get_main_queue(), ^{
            if (status == PHAuthorizationStatusDenied) { //用户拒绝当前访问相册
                if (oldSatus != PHAuthorizationStatusNotDetermined) {
                    [SVProgressHUD showErrorWithStatus:@"请到设置 -> 隐私 中打开访问权限"];
                }
            }else if (status == PHAuthorizationStatusAuthorized){//用户允许当前App访问相册
                [self SavePhotToAlbum];
            }else if (status == PHAuthorizationStatusRestricted){
                [SVProgressHUD showErrorWithStatus:@"因系统原因，无法访问相册！"];
            }
            
        });
        
        
    }];

}

-(void)SavePhotToAlbum{
    
    if (self.imageView.image == nil) {
        [SVProgressHUD showErrorWithStatus:@"图片没有加载完毕！"];
        return;
    }
    
    //获得相片
    PHFetchResult<PHAsset *> *AssetResult = self.createdAssets;
    if (AssetResult == nil) {
        [SVProgressHUD showErrorWithStatus:@"保存图片失败"];
        return;
    }
    
    
    //获得相册
    PHAssetCollection *CreatedCollection =  self.createdCollection;
    
    if (CreatedCollection == nil) {
        [SVProgressHUD showErrorWithStatus:@"创建或者获取相册失败！"];
        return;
    }
    
    
    //添加刚才保存的图片到[自定义相册]
    NSError * error = nil;
    [[PHPhotoLibrary sharedPhotoLibrary]performChangesAndWait:^{
        
        //拿到自定义相册
        PHAssetCollectionChangeRequest *request = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:CreatedCollection];
        
        //往自定义相册中添加照片
        //通过照片唯一标示符往自定义相册中添加照片
        [request insertAssets:AssetResult atIndexes:[NSIndexSet indexSetWithIndex:0]];
        //通过占位对象往自定义相册中添加照片
        //        [request insertAssets:@[placrholder] atIndexes:[NSIndexSet indexSetWithIndex:0]];
        
        
    } error:&error];
    
    if (error) {
        [SVProgressHUD showErrorWithStatus:@"保存图片失败！"];
    }else{
        [SVProgressHUD showSuccessWithStatus:@"保存图片成功！"];
    }
    
}


@end
