//
//  CuratorClient.m
//  CuratorScreenSaver
//
//  Created by Francis Chong on 2/13/14.
//  Copyright (c) 2014 Ignition Soft. All rights reserved.
//

#import "CuratorClient.h"
#import "CuratorImage.h"

#import "Bolts.h"
#import "ObjectiveSugar.h"
#import "NSDateFormatter+JSONDateFormatter.h"

static NSString * const CuratorClientAPIBaseURLString = @"http://curator.im/api/";

@implementation CuratorClient

+ (instancetype)sharedClient {
    static CuratorClient *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[CuratorClient alloc] initWithBaseURL:[NSURL URLWithString:CuratorClientAPIBaseURLString]];
    });
    return _sharedClient;
}

-(instancetype) init{
    return [super initWithBaseURL:[NSURL URLWithString:CuratorClientAPIBaseURLString]];
}

-(void) streamWithBlock:(void (^)(NSArray *, NSError *))block {
    if (!self.token) {
        [NSException raise:NSInconsistentArchiveException format:@"token not set for CuratorClient!"];
    }

    [self GET:@"stream"
   parameters:@{@"token": self.token}
      success:^(NSURLSessionDataTask *task, id JSON) {
          NSDateFormatter* formatter = [NSDateFormatter sharedDateFormatterForJSON];
          NSArray *imagesFromResponse = [JSON valueForKeyPath:@"results"];
          if (imagesFromResponse) {
              NSArray* images = [[imagesFromResponse map:^id(NSDictionary* object) {
                  NSString* name = object[@"name"];
                  NSString* url = object[@"image"];
                  NSString* createdAtString = object[@"created_at"];
                  NSString* heightString = object[@"height"];
                  NSString* widthString = object[@"width"];
                  NSDate* createdAt = [formatter dateFromString:createdAtString];
                  return [CuratorImage imageWithName:name
                                      imageURLString:url
                                           createdAt:createdAt
                                              height:[heightString floatValue]
                                               width:[widthString floatValue]];
              }] select:^BOOL(CuratorImage* image) {
                  // only return valus with image and height or width > 400
                  return image.name && image.height > 400 && image.width > 400;
              }];
              [source setResult:images];
          }
      } failure:^(NSURLSessionDataTask *task, NSError *error) {
          [source setError:error];
      }];
    return source.task;
}

      }];
}

@end
