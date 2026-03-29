#import "ArchiveExtractor.h"

#if __has_include(<SSZipArchive/SSZipArchive.h>)
#import <SSZipArchive/SSZipArchive.h>
#endif

#if __has_include(<UnrarKit/URKArchive.h>)
#import <UnrarKit/URKArchive.h>
#elif __has_include(<UnrarKit/UnrarKit.h>)
#import <UnrarKit/UnrarKit.h>
#endif

static NSString *const ArchiveExtractorErrorDomain = @"RPGPlayerClone.ArchiveExtractor";

@implementation ArchiveExtractor

+ (BOOL)extractZipAtPath:(NSString *)archivePath
          toDestination:(NSString *)destinationPath
                  error:(NSError * _Nullable * _Nullable)error {
#if __has_include(<SSZipArchive/SSZipArchive.h>)
    return [SSZipArchive unzipFileAtPath:archivePath
                           toDestination:destinationPath
                      preserveAttributes:YES
                               overwrite:YES
                                password:nil
                                   error:error
                                delegate:nil];
#else
    if (error != NULL) {
        *error = [NSError errorWithDomain:ArchiveExtractorErrorDomain
                                     code:1001
                                 userInfo:@{
                                     NSLocalizedDescriptionKey: @"SSZipArchive framework is unavailable."
                                 }];
    }
    return NO;
#endif
}

+ (BOOL)extractRARAtPath:(NSString *)archivePath
          toDestination:(NSString *)destinationPath
                  error:(NSError * _Nullable * _Nullable)error {
#if __has_include(<UnrarKit/URKArchive.h>) || __has_include(<UnrarKit/UnrarKit.h>)
    URKArchive *archive = [[URKArchive alloc] initWithPath:archivePath error:error];
    if (archive == nil) {
        return NO;
    }

    return [archive extractFilesTo:destinationPath overwrite:YES error:error];
#else
    if (error != NULL) {
        *error = [NSError errorWithDomain:ArchiveExtractorErrorDomain
                                     code:1002
                                 userInfo:@{
                                     NSLocalizedDescriptionKey: @"UnrarKit framework is unavailable."
                                 }];
    }
    return NO;
#endif
}

@end
