
#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "DownloadOperation.h"


@interface DownloadManager : NSObject
{
    NSMutableArray *_operationArray;
    NSMutableArray *_finishedDownloads;
}
typedef void(^DownloadsCompletedBlock)(NSArray *downloadedFiles);


@property (strong, atomic) void (^CompletedBlock)(NSArray *downloadedFiles);

+ (id)downloadFolder;
+ (id)sharedInstance;
- (void)processDownloadArray;
- (void)removeDownloadFromQueue:(NSDictionary *)downloadInfo;
- (void)addDownloadToQueue:(NSDictionary *)downloadInfo;
- (void)addDownloadsToQueue:(NSArray *)downloadInfos
                  completed:(DownloadsCompletedBlock)completionBlock;

@end
