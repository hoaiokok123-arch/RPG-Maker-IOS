#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ArchiveExtractor : NSObject

+ (nullable NSString *)extractZipAtPath:(NSString *)archivePath
                          toDestination:(NSString *)destinationPath
    NS_SWIFT_NAME(extractZip(atPath:toDestination:));

+ (nullable NSString *)extractRARAtPath:(NSString *)archivePath
                          toDestination:(NSString *)destinationPath
    NS_SWIFT_NAME(extractRAR(atPath:toDestination:));

@end

NS_ASSUME_NONNULL_END
