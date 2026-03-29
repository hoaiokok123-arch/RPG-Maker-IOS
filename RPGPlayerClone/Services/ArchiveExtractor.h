#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ArchiveExtractor : NSObject

+ (BOOL)extractZipAtPath:(NSString *)archivePath
          toDestination:(NSString *)destinationPath
                  error:(NSError * _Nullable * _Nullable)error;

+ (BOOL)extractRARAtPath:(NSString *)archivePath
          toDestination:(NSString *)destinationPath
                  error:(NSError * _Nullable * _Nullable)error;

@end

NS_ASSUME_NONNULL_END
