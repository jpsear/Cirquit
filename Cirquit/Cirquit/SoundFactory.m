//
//  SoundFactory.m
//  AVFoundation Recorder
//
//  Created by Jon Lord on 01/03/2015.
//  Copyright (c) 2015 Gene De Lisa. All rights reserved.
//

#import "SoundFactory.h"

@implementation SoundFactory




- (NSString*)convertSoundToString:(NSString*)soundFileName {

    NSString *path = [[NSBundle mainBundle] pathForResource:soundFileName ofType:@"m4a"];
    NSError *error = nil;
    NSData *data = [NSData dataWithContentsOfFile:path options:NSDataReadingUncached error:&error];
    
    NSString *str = [data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    
    return str;
}
- (void)convertStringToSound:(NSString*)soundString givingItTheFileName:(NSString*)soundFileName {

    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = [dirPaths objectAtIndex:0];
    NSString *exportFile = [docsDir stringByAppendingString:soundFileName];

    NSData *data = [[NSData alloc]initWithBase64EncodedString:soundString options:NSDataBase64DecodingIgnoreUnknownCharacters];
    
    NSError *error = nil;

    [data writeToFile:exportFile options:NSDataWritingAtomic error:&error ];

}


- (void)mergeMySoundFile:(NSURL*)mySoundFileName withFriendsSoundFile:(NSURL*)friendsSoundFileName toCreateSoundFileNamed:(NSURL*)mergedSoundFileName {
    
    NSMutableArray *audioMixParams = [[NSMutableArray alloc] initWithObjects:nil];
    [self saveRecordingWithAudioMixParams:audioMixParams combiningMySoundFile:mySoundFileName withFriendsSoundFile:friendsSoundFileName andExportingToPath:mergedSoundFileName];
}

- (IBAction)saveRecordingWithAudioMixParams:(NSMutableArray*)audioMixParams combiningMySoundFile:(NSURL*)mySoundFileName withFriendsSoundFile:(NSURL*)friendsSoundFileName andExportingToPath:(NSURL*)exportURL
{
    AVMutableComposition *composition = [AVMutableComposition composition];
    audioMixParams = [[NSMutableArray alloc] initWithObjects:nil];
    
    //IMPLEMENT FOLLOWING CODE WHEN WANT TO MERGE ANOTHER AUDIO FILE
    //Add Audio Tracks to Composition
    [self setUpAndAddAudioAtPath:mySoundFileName toComposition:composition usingAudioMixParams:audioMixParams];
    [self setUpAndAddAudioAtPath:friendsSoundFileName toComposition:composition usingAudioMixParams:audioMixParams];
    
    AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
    audioMix.inputParameters = [NSArray arrayWithArray:audioMixParams];
    
    //If you need to query what formats you can export to, here's a way to find out
    NSLog (@"compatible presets for songAsset: %@",
           [AVAssetExportSession exportPresetsCompatibleWithAsset:composition]);
    
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc]
                                      initWithAsset: composition
                                      presetName: AVAssetExportPresetAppleM4A];
    exporter.audioMix = audioMix;
    exporter.outputFileType = @"com.apple.m4a-audio";
    exporter.outputURL = exportURL;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:[exportURL path]]) {
        NSError *error;
        if ([fileManager removeItemAtPath:[exportURL path] error:&error] == NO) {
            NSLog(@"removeItemAtPath %@ error:%@", [exportURL path], error);
        }
    }
    
    // do the export
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        int exportStatus = exporter.status;
        NSError *exportError = exporter.error;
        
        NSLog(@"%d", exportStatus);
        switch (exportStatus) {
            case AVAssetExportSessionStatusFailed:
                NSLog (@"AVAssetExportSessionStatusFailed");
                break;
            case AVAssetExportSessionStatusCompleted: NSLog (@"AVAssetExportSessionStatusCompleted");
                break;
            case AVAssetExportSessionStatusUnknown: NSLog (@"AVAssetExportSessionStatusUnknown"); break;
            case AVAssetExportSessionStatusExporting: NSLog (@"AVAssetExportSessionStatusExporting"); break;
            case AVAssetExportSessionStatusCancelled: NSLog (@"AVAssetExportSessionStatusCancelled"); break;
            case AVAssetExportSessionStatusWaiting: NSLog (@"AVAssetExportSessionStatusWaiting"); break;
            default:  NSLog (@"didn't get export status"); break;
        }
    }];
}


- (void) setUpAndAddAudioAtPath:(NSURL*)assetURL toComposition:(AVMutableComposition *)composition usingAudioMixParams:(NSMutableArray*)audioMixParams
{
    AVURLAsset *songAsset = [AVURLAsset URLAssetWithURL:assetURL options:nil];
    
    AVMutableCompositionTrack *track = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    AVAssetTrack *sourceAudioTrack = [[songAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
    
    NSError *error = nil;
    BOOL ok = NO;
    
    CMTime startTime = CMTimeMakeWithSeconds(0, 1);
    CMTime trackDuration = songAsset.duration;
    //CMTime longestTime = CMTimeMake(848896, 44100); //(19.24 seconds)
    CMTimeRange tRange = CMTimeRangeMake(startTime, trackDuration);
    
    //Set Volume
    AVMutableAudioMixInputParameters *trackMix = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:track];
    [trackMix setVolume:0.8f atTime:startTime];
    [audioMixParams addObject:trackMix];
    
    //Insert audio into track
    ok = [track insertTimeRange:tRange ofTrack:sourceAudioTrack atTime:CMTimeMake(0, 44100) error:&error];
}




@end
