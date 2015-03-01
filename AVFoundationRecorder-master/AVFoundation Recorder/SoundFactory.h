//
//  SoundFactory.h
//  AVFoundation Recorder
//
//  Created by Jon Lord on 01/03/2015.
//  Copyright (c) 2015 Gene De Lisa. All rights reserved.
//

#import <Foundation/Foundation.h>
@import AVFoundation;

@interface SoundFactory : NSObject

- (NSString*)convertSoundToString:(NSString*)soundFileName;
- (void)convertStringToSound:(NSString*)soundString givingItTheFileName:(NSString*)soundFileName;

- (void)mergeMySoundFile:(NSString*)mySoundFileName withFriendsSoundFile:(NSString*)friendsSoundFileName toCreateSoundFileNamed:(NSString*)mergedSoundFileName;

@end
