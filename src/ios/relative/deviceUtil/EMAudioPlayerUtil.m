//
//  EMAudioPlayerUtil.m
//  ChatDemo-UI2.0
//
//  Created by dujiepeng on 5/8/15.
//  Copyright (c) 2015 dujiepeng. All rights reserved.
//

#import "EMAudioPlayerUtil.h"
#import "EMError.h"
#import <AVFoundation/AVFoundation.h>
static EMAudioPlayerUtil *audioPlayerUtil = nil;

@interface EMAudioPlayerUtil () <AVAudioPlayerDelegate> {
    AVAudioPlayer *_player;
    void (^playFinish)(NSError *error);
}

@end

@implementation EMAudioPlayerUtil

#pragma mark - public
+ (BOOL)isPlaying{
    return [[EMAudioPlayerUtil sharedInstance] isPlaying];
}

+ (NSString *)playingFilePath{
    return [[EMAudioPlayerUtil sharedInstance] playingFilePath];
}

+ (void)asyncPlayingWithPath:(NSString *)aFilePath
                  completion:(void(^)(NSError *error))completon{
    [[EMAudioPlayerUtil sharedInstance] asyncPlayingWithPath:aFilePath
                                                  completion:completon];
}

+ (void)stopCurrentPlaying{
    [[EMAudioPlayerUtil sharedInstance] stopCurrentPlaying];
}


#pragma mark - private
+ (EMAudioPlayerUtil *)sharedInstance{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        audioPlayerUtil = [[self alloc] init];
    });
    
    return audioPlayerUtil;
}

// 当前是否正在播放
- (BOOL)isPlaying
{
    return !!_player;
}

// 得到当前播放音频路径
- (NSString *)playingFilePath
{
    NSString *path = nil;
    if (_player && _player.isPlaying) {
        path = _player.url.path;
    }
    
    return path;
}

- (void)asyncPlayingWithPath:(NSString *)aFilePath
                  completion:(void(^)(NSError *error))completon{
    playFinish = completon;
    NSError *error = nil;
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:aFilePath]) {
        error = [NSError errorWithDomain:@"File path not exist"
                                    code:EMErrorAttachmentNotFound
                                userInfo:nil];
        if (playFinish) {
            playFinish(error);
        }
        playFinish = nil;
        
        return;
    }
    
    NSURL *wavUrl = [[NSURL alloc] initFileURLWithPath:aFilePath];
    _player = [[AVAudioPlayer alloc] initWithContentsOfURL:wavUrl error:&error];
    if (error || !_player) {
        _player = nil;
        error = [NSError errorWithDomain:@"Failed to initialize AVAudioPlayer"
                                    code:EMErrorInitFailure
                                userInfo:nil];
        if (playFinish) {
            playFinish(error);
        }
        playFinish = nil;
        return;
    }
    
    _player.delegate = self;
    [_player prepareToPlay];
    [_player play];
}

// 停止当前播放
- (void)stopCurrentPlaying{
    if(_player){
        _player.delegate = nil;
        [_player stop];
        _player = nil;
    }
    if (playFinish) {
        playFinish = nil;
    }
}

- (void)dealloc{
    if (_player) {
        _player.delegate = nil;
        [_player stop];
        _player = nil;
    }
    playFinish = nil;
}

#pragma mark - AVAudioPlayerDelegate
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player
                       successfully:(BOOL)flag{
    if (playFinish) {
        playFinish(nil);
    }
    if (_player) {
        _player.delegate = nil;
        _player = nil;
    }
    playFinish = nil;
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player
                                 error:(NSError *)error{
    if (playFinish) {
        NSError *error = [NSError errorWithDomain:@"Play failure"
                                             code:EMErrorFailure
                                         userInfo:nil];
        playFinish(error);
    }
    if (_player) {
        _player.delegate = nil;
        _player = nil;
    }
}

@end
