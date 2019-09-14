
#import <Foundation/Foundation.h>

#define FM [NSFileManager defaultManager]

@interface DownloadOperation: NSOperation <NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDownloadDelegate>

typedef void(^DownloadCompletedBlock)(NSString *downloadedFile);


@property (nonatomic, strong) NSDictionary *downloadInfo;
@property (nonatomic, strong) NSString *downloadLocation;
@property (strong, atomic) void (^ProgressBlock)(double percentComplete);
@property (strong, atomic) void (^FancyProgressBlock)(double percentComplete, NSString *status);
@property (strong, atomic) void (^CompletedBlock)(NSString *downloadedFile);
@property (readwrite, assign) NSInteger trackDuration;

- (id)initWithInfo:(NSDictionary *)downloadDictionary
         completed:(DownloadCompletedBlock)theBlock;

@end
