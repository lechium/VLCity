#import "DownloadManager.h"

@interface DownloadManager ()

@property (strong, nonatomic) NSOperationQueue      *operationQueue;
@property (nonatomic, strong)                       NSMutableArray *operations;

@end

@implementation DownloadManager

+ (NSString *)downloadFolder
{
    //HBLogDebug(@"main bundle path: %@", [[NSBundle mainBundle] resourcePath]);
    NSString *dlF = @"/var/mobile/Library/Caches/sharedCaches";
    if (![FM fileExistsAtPath:dlF])
    {
        NSError *error = nil;
        [FM createDirectoryAtPath:dlF withIntermediateDirectories:true attributes:nil error:&error];
        HBLogDebug(@"Romulator error: %@", error);
    }
    return dlF;
}

- (void)removeDownloadFromQueue:(NSDictionary *)downloadInfo
{
    for (DownloadOperation *operation in [self operations])
    {
        if ([[operation name] isEqualToString:downloadInfo[@"title"]])
        {
            HBLogDebug(@"found operation, cancel it!");
            [operation cancel];
        }
    }
}

- (void)processDownloadArray
{
    
}

- (void)addDownloadsToQueue:(NSArray *)downloadInfos completed:(DownloadsCompletedBlock)completionBlock
{
    _operationArray = [[NSMutableArray alloc] initWithArray:downloadInfos];
    _finishedDownloads = [NSMutableArray new];
    self.operationQueue.maxConcurrentOperationCount = 1;
    
    for (NSDictionary *downloadInfo in downloadInfos)
    {
        __block DownloadOperation *downloadOp = [[DownloadOperation alloc] initWithInfo:downloadInfo completed:^(NSString *downloadedFile) {
            
            HBLogDebug(@"download completed: %@", downloadedFile);
            [[self operations] removeObject:downloadOp];
            [_operationArray removeObject:downloadInfo];
            [_finishedDownloads addObject:downloadedFile];
            if (_operationArray.count == 0)
            {
                HBLogDebug(@"all downloads completed!");
                completionBlock(_finishedDownloads);
            }
            //     [self playCompleteSound];
            
        }];
        [[self operations] addObject:downloadOp];
        
        [self.operationQueue addOperation:downloadOp];
        if ([downloadOp isExecuting])
        {
        } else {
            [downloadOp main];
        }
    }
    
   
}

//add a download to our NSOperationQueue


- (void)addDownloadToQueue:(NSDictionary *)downloadInfo
{
    DownloadOperation *downloadOp = [[DownloadOperation alloc] initWithInfo:downloadInfo completed:^(NSString *downloadedFile) {
        
        if (downloadedFile == nil)
        {
            HBLogDebug(@"no downloaded file, either cancelled or failed!");
            return;
        }
        
        HBLogDebug(@"installing: %@", downloadedFile);
        
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"installPackage" object:nil userInfo:@{@"downloadedFile": downloadedFile}];
        
        HBLogDebug(@"download completed!");
        [[self operations] removeObject:downloadOp];
   //     [self playCompleteSound];
        
    }];
    [[self operations] addObject:downloadOp];
    
    [self.operationQueue addOperation:downloadOp];
    if ([downloadOp isExecuting])
    {
    } else {
        [downloadOp main];
    }
}



//standard tri-tone completion sound

- (void)playCompleteSound
{
    return;
   // NSString *thePath = @"/Applications/yourTube.app/complete.aif";
    NSString *thePath = [[NSBundle mainBundle] pathForResource:@"complete" ofType:@"aif"];
    SystemSoundID soundID;
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath: thePath], &soundID);
    AudioServicesPlaySystemSound (soundID);
}

+ (id)sharedInstance {
    
    static dispatch_once_t onceToken;
    static DownloadManager *shared;
    if (!shared){
        dispatch_once(&onceToken, ^{
            shared = [DownloadManager new];
            shared.operationQueue = [NSOperationQueue mainQueue];
            shared.operationQueue.name = @"Connection Queue";
            shared.operations = [NSMutableArray new];
        });
    }
    
    return shared;
    
}

@end
