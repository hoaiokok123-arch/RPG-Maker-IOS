#import "ArchiveExtractor.h"

#if __has_include(<SSZipArchive/SSZipArchive.h>)
#import <SSZipArchive/SSZipArchive.h>
#endif

#if __has_include(<UnrarKit/URKArchive.h>)
#import <UnrarKit/URKArchive.h>
#elif __has_include(<UnrarKit/UnrarKit.h>)
#import <UnrarKit/UnrarKit.h>
#endif

@implementation ArchiveExtractor

+ (nullable NSString *)extractZipAtPath:(NSString *)archivePath
                          toDestination:(NSString *)destinationPath {
#if __has_include(<SSZipArchive/SSZipArchive.h>)
    NSError *error = nil;
    BOOL success = [SSZipArchive unzipFileAtPath:archivePath
                                   toDestination:destinationPath
                              preserveAttributes:YES
                                       overwrite:YES
                                        password:nil
                                           error:&error
                                        delegate:nil];
    return success ? nil : error.localizedDescription ?: @"ZIP extraction failed.";
#else
    return @"SSZipArchive framework is unavailable.";
#endif
}

+ (nullable NSString *)extractRARAtPath:(NSString *)archivePath
                          toDestination:(NSString *)destinationPath {
#if __has_include(<UnrarKit/URKArchive.h>) || __has_include(<UnrarKit/UnrarKit.h>)
    NSError *error = nil;
    URKArchive *archive = [[URKArchive alloc] initWithPath:archivePath error:&error];
    if (archive == nil) {
        return error.localizedDescription ?: @"RAR extraction failed.";
    }

    BOOL success = [archive extractFilesTo:destinationPath overwrite:YES error:&error];
    return success ? nil : error.localizedDescription ?: @"RAR extraction failed.";
#else
    return @"UnrarKit framework is unavailable.";
#endif
}

@end
