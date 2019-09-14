

#import "VLCity.h"
#import <TVSettingsKit/TSKTextInputSettingItem.h>
#import <MobileCoreServices/LSApplicationWorkspace.h>
#import <MobileCoreServices/LSApplicationProxy.h>

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <spawn.h>
#include <sys/wait.h>

#include <string.h>
#include <math.h>
#include <sys/stat.h>
#include <sys/param.h>

#import "DownloadManager.h"


@interface LSApplicationProxy (More)
+(id)applicationProxyForIdentifier:(id)arg1;
-(BOOL)isContainerized;
-(NSURL *)dataContainerURL;
@end

@interface LSApplicationWorkspace (More)

-(id)allInstalledApplications;
-(BOOL)openApplicationWithBundleID:(id)arg1;

@end

@interface VLCAirDropReceiverViewController()

@property (nonatomic, strong) UIProgressView *progressView;

@end

@implementation VLCAirDropReceiverViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
     CGRect viewBounds = self.view.bounds;
    self.progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(200, viewBounds.size.height - 150, self.view.bounds.size.width-400, 30)];
    [[self view] addSubview:self.progressView];
    self.progressView.hidden = true;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateProgressFromNotification:) name:@"updateProgress" object:nil];
    
}

- (void)viewWillDisappear:(BOOL)animated
{
 
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewWillDisappear:animated];
    
}

- (void)updateProgressFromNotification:(NSNotification *)n {
    
    
    float progress = [n.userInfo[@"progress"] floatValue];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.progressView setHidden:false];
        self.progressView.progress = progress;
        if (progress >= 1.0){
            [self.progressView setHidden:true];
        }
    });
    
    
    
}

- (void)viewDidLayoutSubviews {
    
    HBLogDebug(@"viewDidLayoutSubviews");
    [super viewDidLayoutSubviews];
    HBLogDebug(@"subviews: %@", self.view.subviews);
}


@end

@interface VLCity() {
    
    BOOL _vlcFound;
}
@property (nonatomic, strong) NSString *importsPath;
@property (nonatomic, strong) NSString *defaultBundleID;
@end

@implementation VLCity

+ (NSArray *)returnForProcess:(NSString *)call
{
    if (call==nil)
        return 0;
    char line[200];
    NSLog(@"running process: %@", call);
    FILE* fp = popen([call UTF8String], "r");
    NSMutableArray *lines = [[NSMutableArray alloc]init];
    if (fp)
    {
        while (fgets(line, sizeof line, fp))
        {
            NSString *s = [NSString stringWithCString:line encoding:NSUTF8StringEncoding];
            s = [s stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            [lines addObject:s];
        }
    }
    pclose(fp);
    return lines;
}

- (void)_findVLCPath {
    
    if (_vlcFound) return;
    
    NSFileManager *man = [NSFileManager defaultManager];
    NSString *appendPath = @"Library/Caches/Upload";
    
    //first try via the application proxy with hardcoded bundle id
    LSApplicationProxy *provProxy = [LSApplicationProxy applicationProxyForIdentifier:self.defaultBundleID];
    if (provProxy){
        NSLog(@"got im: %@, dataContainerURL: %@", provProxy, [provProxy dataContainerURL]);
        if ([provProxy isContainerized]){
            NSLog(@"is containerized!");
            self.importsPath = [[[provProxy dataContainerURL] path] stringByAppendingPathComponent:appendPath];
            NSLog(@"final path: %@", self.importsPath);
            if ([man fileExistsAtPath:self.importsPath]){
                _vlcFound = TRUE;
                return;
            } else {
                
                NSLog(@"this path wasnt found; %@",self.importsPath );
                NSDictionary *folderAttrs = @{NSFileGroupOwnerAccountName: @"staff",NSFileOwnerAccountName: @"mobile"};
                NSError *error = nil;
                [man createDirectoryAtPath:self.importsPath withIntermediateDirectories:YES attributes:folderAttrs error:&error];
                if (error){
                    NSLog(@"error: %@", error);
                } else {
                    return;
                }
            }
        }
    }
    LSApplicationWorkspace *workspace = [LSApplicationWorkspace defaultWorkspace];
    NSArray *installedApplications = [workspace allInstalledApplications];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"bundleExecutable contains[cd] %@ ", @"vlc"];
    NSArray *filteredResults = [installedApplications filteredArrayUsingPredicate:pred];
    if (filteredResults.count > 0){
        
        provProxy = filteredResults[0];
        self.defaultBundleID = [provProxy bundleIdentifier];
        NSLog(@"found new bundle id: %@", self.defaultBundleID);
        if ([provProxy isContainerized]){
            NSLog(@"is containerized!");
            self.importsPath = [[[provProxy dataContainerURL] path] stringByAppendingPathComponent:appendPath];
            NSLog(@"final path: %@", self.importsPath);
            if ([man fileExistsAtPath:self.importsPath]){
                _vlcFound = TRUE;
                return;
            } else {
                
                NSLog(@"this path wasnt found; %@",self.importsPath );
                
            }
        }
    }
    
    NSError *error = nil;
    NSString *commandString = [NSString stringWithFormat:@"find /var/mobile -path \"*Caches/%@\" | xargs dirname", self.defaultBundleID];
    NSString *provenanceCache = [[VLCity returnForProcess:commandString] componentsJoinedByString:@""];
    self.importsPath = [provenanceCache stringByAppendingPathComponent:@"Imports"];
    NSLog(@"final path: %@", self.importsPath);
    if (!provProxy.isContainerized){
        NSURL *dataContainerURL = [NSURL fileURLWithPath:[provenanceCache stringByDeletingLastPathComponent]];
        NSLog(@"self.dataContainerURL: %@", dataContainerURL);
        [provProxy setValue:dataContainerURL forKey:@"_boundDataContainerURL"];
        NSLog(@"self.dataContainerURL: %@", [provProxy dataContainerURL]);
    }
    if (self.importsPath && [man fileExistsAtPath:self.importsPath]){
        _vlcFound = TRUE;
        
    }
}



- (void)downloadURLManually:(NSURL *)url {
    
    NSString *title = [url lastPathComponent];
    NSString *path = [url absoluteString];
    NSDictionary *downloadDict = @{@"URL": path, @"Name": title};
    [self sendBulletinWithMessage:[NSString stringWithFormat:@"Downloading URL: %@", title] title:@"Starting URL download..."];

    [[DownloadManager sharedInstance] addDownloadsToQueue:@[downloadDict] completed:^(NSArray *downloadedFiles) {
        
        
    
        /*
         dispatch_async(dispatch_get_main_queue(), ^{
         
         });
         */
        HBLogDebug(@"VLCity: should install packages: %@", downloadedFiles);
        if (downloadedFiles.count > 0){
            
            [self sendBulletinWithMessage:[NSString stringWithFormat:@"Finished URL: %@ Successfully!", title] title:@"Download Completed!"];
            [self processPath:downloadedFiles[0]];
        }
        
        
    }];
}

- (void)sendBulletinWithMessage:(NSString *)message title:(NSString *)title {
    
    NSMutableDictionary *dict = [NSMutableDictionary new];
    dict[@"message"] = message;
    dict[@"title"] = title;
    dict[@"timeout"] = @2;
    
    NSString *imagePath = [[NSBundle bundleForClass:self.class] pathForResource:@"icon" ofType:@"jpg"];
    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
    NSData *imageData = UIImageJPEGRepresentation(image, 1.0);
    if (imageData){
        dict[@"imageData"] = imageData;
    }
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"com.nito.bulletinh4x/displayBulletin" object:nil userInfo:dict];
    
}

- (void)processPath:(NSString *)path  {
    
    HBLogDebug(@"VLCity PROCESSPATH: %@", path);
    //NSString *path = [url path];
    NSString *fileName = path.lastPathComponent;
    NSError *error = nil;
    NSFileManager *man = [NSFileManager defaultManager];
    
    [self _findVLCPath];
    
    if (_vlcFound){
        
        // if ([[[fileName pathExtension] lowercaseString] isEqualToString:@"nes"]){
        NSString *importsFile = [self.importsPath stringByAppendingPathComponent:fileName];
        HBLogDebug(@"importing file: %@", importsFile);
        if ([man moveItemAtPath:path toPath:importsFile error:nil]){
            
            NSString *message = [NSString stringWithFormat:@"Imported '%@' successfully!",fileName];
            NSString *title = @"Import Successful";
            [self sendBulletinWithMessage:message title:title];
            
        }
        // }
        
    }
    
}


- (void)openProvenance {
    
    LSApplicationWorkspace *ws = [LSApplicationWorkspace defaultWorkspace];
    [ws openApplicationWithBundleID:self.defaultBundleID];
    
}


- (void)showAirDropSharingSheet {
    
    NSLog(@"VLCity: main bundle: %@", [NSBundle bundleForClass:self.class]);
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(airDropReceived:) name:@"com.nito.AirDropper/airDropFileReceived" object:nil];
    VLCAirDropReceiverViewController *rec = [[VLCAirDropReceiverViewController alloc] init];
    [self presentViewController:rec animated: YES completion: nil];
    
    UILabel *ourLabel = [rec valueForKey:@"_instructionsLabel"];
    UIFont *ogFont = [ourLabel font];
    [ourLabel setText:@"Drop any VLC compatible video files to transfer them / download them into the 'Uploads' directory"];
    [ourLabel setFont:ogFont];
    
    [rec startAdvertising];
    
}

- (void)airDropReceived:(NSNotification *)n {
    
    NSDictionary *userInfo = [n userInfo];
    NSArray <NSString *>*items = userInfo[@"Items"];
    NSLog(@"VLCity: airdropped Items: %@", items);
    
    [items enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        [self processPath:obj];
        
    }];
    
    NSArray <NSString *> *urls = userInfo[@"URLS"];
    
    [urls enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        [self downloadURLManually:[NSURL URLWithString:obj]];
        
    }];
    
}

- (void)viewWillAppear:(BOOL)animated {
    
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self name:@"com.nito.AirDropper/airDropFileReceived" object:nil];
    [super viewWillAppear:animated];
    NSLog(@"VLCity viewWillAppear");
    [self _findVLCPath];
    
}

- (id)loadSettingGroups {

    
    _vlcFound = FALSE;
    self.defaultBundleID = @"org.videolan.vlc-ios";
    
    id facade = [[NSClassFromString(@"TVSettingsPreferenceFacade") alloc] initWithDomain:@"com.nito.VLCity" notifyChanges:TRUE];
    
    NSMutableArray *_backingArray = [NSMutableArray new];
    TSKSettingItem *actionItem = [TSKSettingItem actionItemWithTitle:@"Start AirDrop Server" description:@"Turn on AirDrop to receive roms for importing into VLC" representedObject:facade keyPath:@"" target:self action:@selector(showAirDropSharingSheet)];
    TSKSettingItem *openItem = [TSKSettingItem actionItemWithTitle:@"Open VLC" description:@"A Shortcut to open Provenance" representedObject:facade keyPath:@"" target:self action:@selector(openProvenance)];
    TSKSettingGroup *group = [TSKSettingGroup groupWithTitle:nil settingItems:@[actionItem, openItem]];
    [_backingArray addObject:group];
    [self setValue:_backingArray forKey:@"_settingGroups"];
    
    return _backingArray;
    
}

-(id)previewForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    TSKPreviewViewController *item = [super previewForItemAtIndexPath:indexPath];
    TSKSettingGroup *currentGroup = self.settingGroups[indexPath.section];
    TSKSettingItem *currentItem = currentGroup.settingItems[indexPath.row];
    NSString *imagePath = [[NSBundle bundleForClass:self.class] pathForResource:@"icon" ofType:@"jpg"];
    UIImage *icon = [UIImage imageWithContentsOfFile:imagePath];
    if (icon != nil) {
        TSKVibrantImageView *imageView = [[TSKVibrantImageView alloc] initWithImage:icon];
        [item setContentView:imageView];
    }
    
    return item;
    
}


@end
