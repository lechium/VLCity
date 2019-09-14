#import "DownloadOperation.h"
#import "DownloadManager.h"

@interface DownloadOperation ()

@property (nonatomic) NSURLSession *session;
@property (nonatomic) NSURLSessionDownloadTask *downloadTask;
@end

//download operation class, handles file downloads.


@implementation DownloadOperation

@synthesize downloadInfo, downloadLocation, trackDuration;



- (BOOL)isAsynchronous
{
    return true;
}

- (id)initWithInfo:(NSDictionary *)downloadDictionary completed:(DownloadCompletedBlock)theBlock
{
    self = [super init];
    downloadInfo = downloadDictionary;
    self.name = downloadInfo[@"Name"];
    self.downloadLocation = [[DownloadManager downloadFolder] stringByAppendingPathComponent:[downloadDictionary[@"URL"] lastPathComponent]];
    if ([FM fileExistsAtPath:self.downloadLocation])
    {
        [FM removeItemAtPath:self.downloadLocation error:nil];
    }
    
    self.CompletedBlock = theBlock;
    
    return self;
}

- (void)cancel
{
    [super cancel];
    [[self downloadTask] cancel];
}

- (void)main
{
    [self start];
   
}




- (void)start
{
    self.session = [self backgroundSessionWithId:self.downloadInfo[@"URL"]];
    
    if (self.downloadTask)
    {
        return;
    }
    
    HBLogDebug(@"starting task...");
    /*
     Create a new download task using the URL session. Tasks start in the “suspended” state; to start a task you need to explicitly call -resume on a task after creating it.
     */
    NSURL *downloadURL = [NSURL URLWithString:downloadInfo[@"URL"]];
    NSURLRequest *request = [NSURLRequest requestWithURL:downloadURL];
    self.downloadTask = [self.session downloadTaskWithRequest:request];
    [self.downloadTask resume];
}


- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    /*
     Report progress on the task.
     If you created more than one task, you might keep references to them and report on them individually.
     */
    
    if (downloadTask == self.downloadTask)
    {
        double progress = (double)totalBytesWritten / (double)totalBytesExpectedToWrite;
        //HBLogDebug(@"DownloadTask: %@ progress: %lf", downloadTask, progress);
        [[NSNotificationCenter defaultCenter] postNotificationName:@"updateProgress" object:nil userInfo:@{@"progress": [NSNumber numberWithDouble:progress]}];
        dispatch_async(dispatch_get_main_queue(), ^{

            HBLogDebug(@"Breezy: progress: %f", progress);
            if (self.ProgressBlock){
                self.ProgressBlock(progress);
            }
            // self.progressView.progress = progress;
        });
    }
}


- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)downloadURL
{
    
    /*
     The download completed, you need to copy the file at targetPath before the end of this block.
     As an example, copy the file to the Documents directory of your app.
     */
    
    NSURL *destinationURL = [NSURL fileURLWithPath:[self downloadLocation]];
    NSError *errorCopy;
    
    // For the purposes of testing, remove any esisting file at the destination.
    [FM removeItemAtURL:destinationURL error:NULL];
    BOOL success = [FM copyItemAtURL:downloadURL toURL:destinationURL error:&errorCopy];
    
    if (success)
    {
        dispatch_async(dispatch_get_main_queue(), ^{

        });
    }
    else
    {
        /*
         In the general case, what you might do in the event of failure depends on the error and the specifics of your application.
         */
        HBLogDebug(@"Error during the copy: %@", [errorCopy localizedDescription]);
    }
}


- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    
    if (error == nil)
    {
        HBLogDebug(@"Task: %@ completed successfully", task);
        if (self.CompletedBlock != nil)
        {
            self.CompletedBlock(downloadLocation);
        }
    }
    else
    {
        HBLogDebug(@"Task: %@ completed with error: %@", task, [error localizedDescription]);
        if (self.CompletedBlock != nil)
        {
            self.CompletedBlock(downloadLocation);
        }
    }
    
    //double progress = (double)task.countOfBytesReceived / (double)task.countOfBytesExpectedToReceive;
    dispatch_async(dispatch_get_main_queue(), ^{
        //HBLogDebug(@"progress; %f", progress);
        //  self.progressView.progress = progress;
    });
    
    self.downloadTask = nil;
}


- (NSURLSession *)backgroundSessionWithId:(NSString *)sessionID
{
    /*
     Using disptach_once here ensures that multiple background sessions with the same identifier are not created in this instance of the application. If you want to support multiple background sessions within a single process, you should create each session with its own identifier.
     */
    static NSURLSession *session = nil;
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:sessionID];
    session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
    return session;
}




@end
