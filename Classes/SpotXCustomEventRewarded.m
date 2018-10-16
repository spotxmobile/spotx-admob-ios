//
//  SpotXCustomEventRewarded.m
//  SpotX-AdMob-Plugin
//

#import "SpotXCustomEventRewarded.h"

/// Constant for our Error Domain.
static NSString *const customEventErrorDomain = @"tv.spotx.SpotXCustomEventRewarded";


@interface SpotXCustomEventRewarded ()

// Connector from Google Mobile Ads SDK to receive reward-based video ad configurations.
@property(nonatomic, weak, nullable) id<GADMRewardBasedVideoAdNetworkConnector> rewardBasedVideoAdConnector;

@property(nonatomic, strong, nonnull) SpotXInterstitialAdPlayer* interstitial;
@property(nonatomic, copy, nullable) NSString *apiKey;
@property(nonatomic, copy, nonnull) NSString *channelId;
@property(nonatomic, strong, nullable) NSDictionary* paramDict;
@property(nonatomic, strong, nullable) NSDictionary* customDict;
@property(nonatomic, strong, nullable) NSDictionary* playbackOptionDict;

@property(nonatomic) BOOL giveReward;
@property(nonatomic, copy, nullable) NSString *rewardType;
@property(nonatomic) NSDecimalNumber *rewardAmount;

@end


@implementation SpotXCustomEventRewarded

+ (NSString *)adapterVersion {
  return [SpotX version];
}

+ (Class<GADAdNetworkExtras>)networkExtrasClass {
  // We don't have any defined extras
  return nil;
}

- (instancetype)initWithRewardBasedVideoAdNetworkConnector:(id)connector {
  if (!connector) {
    return nil;
  }
  
  self = [super init];
  if (self) {
    self.rewardBasedVideoAdConnector = connector;
  }
  return self;
}

- (void)setUp {
  id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = self.rewardBasedVideoAdConnector;
  id<GADMRewardBasedVideoAdNetworkAdapter> strongAdapter = self;
  [strongConnector adapterDidSetUpRewardBasedVideoAd:strongAdapter];
}

- (void)requestRewardBasedVideoAd {
  // The String "parameter" here is actually the value of the extern GADCustomEventParametersServer coming
  // from the Google AdMob Framework, but we can't use it because they didn't create the Framework properly :(
  NSString *serverParameter = [self.rewardBasedVideoAdConnector.credentials objectForKey:@"parameter"];
  
  // The passed down serverParameter should be a JSON blob that tells us all of our
  // ad-specific values.
  NSError *error = nil;
  NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:[serverParameter dataUsingEncoding:NSUTF8StringEncoding] options:(NSJSONReadingOptions)0 error:&error];
  
  // Pull out the REQUIRED values from the JSON, and complain if they are missing
  NSString *channelId = jsonDict[@"channelid"];
  if (![channelId isKindOfClass:[NSString class]] || channelId.length == 0) {
    NSString *description = @"channelid not found within the serverParameter JSON";
    NSDictionary *userInfo = @{NSLocalizedDescriptionKey : description, NSLocalizedFailureReasonErrorKey : description};
    error = [NSError errorWithDomain:customEventErrorDomain code:0 userInfo:userInfo];
  } else {
    self.channelId = channelId;
  }
  
  NSDictionary *rewardDict = jsonDict[@"reward"];
  if (![rewardDict isKindOfClass:[NSDictionary class]] || rewardDict == nil) {
    NSString *description = @"reward not found within the serverParameter JSON";
    NSDictionary *userInfo = @{NSLocalizedDescriptionKey : description, NSLocalizedFailureReasonErrorKey : description};
    error = [NSError errorWithDomain:customEventErrorDomain code:0 userInfo:userInfo];
  } else {
    self.rewardType = rewardDict[@"type"];
    if (![self.rewardType isKindOfClass:[NSString class]] || self.rewardType.length == 0) {
      NSString *description = @"type not found within the reward JSON";
      NSDictionary *userInfo = @{NSLocalizedDescriptionKey : description, NSLocalizedFailureReasonErrorKey : description};
      error = [NSError errorWithDomain:customEventErrorDomain code:0 userInfo:userInfo];
    }
    
    self.rewardAmount = rewardDict[@"amount"];
    if (![self.rewardAmount isKindOfClass:[NSNumber class]]) {
      NSString *description = @"amount not found within the reward JSON";
      NSDictionary *userInfo = @{NSLocalizedDescriptionKey : description, NSLocalizedFailureReasonErrorKey : description};
      error = [NSError errorWithDomain:customEventErrorDomain code:0 userInfo:userInfo];
    }
  }
  
  // Pull out the OPTIONAL values from the JSON, and only complain if they are the wrong class
  NSString *apiKey = jsonDict[@"apikey"];
  if (apiKey != nil) {
    if (![apiKey isKindOfClass:[NSString class]]) {
      NSString *description = @"apikey found within the serverParameter JSON, but is not a String";
      NSDictionary *userInfo = @{NSLocalizedDescriptionKey : description, NSLocalizedFailureReasonErrorKey : description};
      error = [NSError errorWithDomain:customEventErrorDomain code:0 userInfo:userInfo];
    } else if (apiKey.length == 0) {
      self.apiKey = nil;
    } else {
      self.apiKey = apiKey;
    }
  } else {
    self.apiKey = nil;
  }
  
  NSDictionary *paramDict = jsonDict[@"param"];
  if (paramDict != nil && ![paramDict isKindOfClass:[NSDictionary class]]) {
    NSString *description = @"param found within the serverParameter JSON, but is not a dictionary";
    NSDictionary *userInfo = @{NSLocalizedDescriptionKey : description, NSLocalizedFailureReasonErrorKey : description};
    error = [NSError errorWithDomain:customEventErrorDomain code:0 userInfo:userInfo];
  } else {
    self.paramDict = paramDict;
  }
  
  NSDictionary *customDict = jsonDict[@"custom"];
  if (customDict != nil && ![customDict isKindOfClass:[NSDictionary class]]) {
    NSString *description = @"custom found within the serverParameter JSON, but is not a dictionary";
    NSDictionary *userInfo = @{NSLocalizedDescriptionKey : description, NSLocalizedFailureReasonErrorKey : description};
    error = [NSError errorWithDomain:customEventErrorDomain code:0 userInfo:userInfo];
  } else {
    self.customDict = customDict;
  }
  
  NSDictionary *playbackOptionDict = jsonDict[@"playback"];
  if (playbackOptionDict != nil && ![playbackOptionDict isKindOfClass:[NSDictionary class]]) {
    NSString *description = @"playback found within the serverParameter JSON, but is not a dictionary";
    NSDictionary *userInfo = @{NSLocalizedDescriptionKey : description, NSLocalizedFailureReasonErrorKey : description};
    error = [NSError errorWithDomain:customEventErrorDomain code:0 userInfo:userInfo];
  } else {
    self.playbackOptionDict = playbackOptionDict;
  }
  
  if (error) {
    // Couldn't parse the JSON, definitely an error that we need to fix in the configuration
    [self.rewardBasedVideoAdConnector adapter:self didFailToLoadRewardBasedVideoAdwithError:error];
    return;
  }
  
  self.interstitial = [[SpotXInterstitialAdPlayer alloc] init];
  self.interstitial.delegate = self;
  [SpotX debugMode:self.rewardBasedVideoAdConnector.testMode];
  [self.interstitial load];
}

- (void)presentRewardBasedVideoAdWithRootViewController:(UIViewController *)viewController {
  if (self.interstitial.adGroup.ads.count > 0) {
    [self.interstitial start];
  }
}

- (void)stopBeingDelegate {
  self.interstitial.delegate = nil;
}

#pragma mark - SpotXAdPlayerDelegate
- (SpotXAdRequest *_Nullable)requestForPlayer:(SpotXAdPlayer *_Nonnull)player {
  
  SpotXAdRequest * request = [[SpotXAdRequest alloc] initWithApiKey:self.apiKey];
  [request setChannel: self.channelId];
  
  for (NSString *key in self.paramDict) {
    id value = self.paramDict[key];
    if ([value isKindOfClass:[NSArray class]]) {
      [request setParam:key values:(NSArray*)value];
    } else if ([value isKindOfClass:[NSString class]]) {
      [request setParam:key value:(NSString*)value];
    } else {
      // Just ignore
      continue;
    }
  }
  
  for (NSString *key in self.customDict) {
    id value = self.customDict[key];
    if ([value isKindOfClass:[NSArray class]]) {
      [request setCustom:key values:(NSArray*)value];
    } else if ([value isKindOfClass:[NSString class]]) {
      [request setCustom:key value:(NSString*)value];
    } else {
      // Just ignore
      continue;
    }
  }
  
  for (NSString *key in self.playbackOptionDict) {
    id value = self.playbackOptionDict[key];
    if ([value isKindOfClass:[NSString class]]) {
      [request setPlaybackOption:key value:(NSString*)value];
    } else if ([value isKindOfClass:[NSNumber class]]) {
      [request setPlaybackOption:key boolValue:((NSNumber*)value).boolValue];
    } else {
      // Just ignore
      continue;
    }
  }
  
  return request;
}

- (void)spotx:(SpotXAdPlayer *_Nonnull)player didLoadAds:(SpotXAdGroup *_Nullable)group error:(NSError *_Nullable)error {
  dispatch_async(dispatch_get_main_queue(), ^{
    id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = self.rewardBasedVideoAdConnector;
    if (error == nil && self.interstitial.adGroup.ads.count > 0) {
      [strongConnector adapterDidReceiveRewardBasedVideoAd:self];
    } else {
      NSString *description = @"Failed to load ad";
      NSDictionary *userInfo = @{NSLocalizedDescriptionKey : description, NSLocalizedFailureReasonErrorKey : description, NSUnderlyingErrorKey : error};
      NSError *chainedError = [NSError errorWithDomain:customEventErrorDomain code:0 userInfo:userInfo];
      [strongConnector adapter:self didFailToLoadRewardBasedVideoAdwithError:chainedError];
    }
  });
}

- (void)spotx:(SpotXAdPlayer *_Nonnull)player adGroupStart:(SpotXAdGroup *_Nonnull)group {
  self.giveReward = YES;
  dispatch_async(dispatch_get_main_queue(), ^{
    id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = self.rewardBasedVideoAdConnector;
    id<GADMRewardBasedVideoAdNetworkAdapter> strongAdapter = self;
    [strongConnector adapterDidOpenRewardBasedVideoAd:strongAdapter];
    [strongConnector adapterDidStartPlayingRewardBasedVideoAd:strongAdapter];
  });
}

- (void)spotx:(SpotXAdPlayer *_Nonnull)player adStart:(SpotXAd *_Nonnull)ad {
  
}

- (void)spotx:(SpotXAdPlayer *_Nonnull)player adPlaying:(SpotXAd *_Nonnull)ad {
  
}

- (void)spotx:(SpotXAdPlayer *_Nonnull)player adPaused:(SpotXAd *_Nonnull)ad {
  
}

- (void)spotx:(SpotXAdPlayer *_Nonnull)player adTimeUpdate:(SpotXAd *_Nonnull)ad timeElapsed:(double)seconds {
  
}

- (void)spotx:(SpotXAdPlayer *_Nonnull)player adClicked:(SpotXAd *_Nonnull)ad {
  dispatch_async(dispatch_get_main_queue(), ^{
    id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = self.rewardBasedVideoAdConnector;
    id<GADMRewardBasedVideoAdNetworkAdapter> strongAdapter = self;
    [strongConnector adapterDidGetAdClick:strongAdapter];
    [strongConnector adapterWillLeaveApplication:strongAdapter];
  });
}

- (void)spotx:(SpotXAdPlayer *_Nonnull)player adComplete:(SpotXAd *_Nonnull)ad {
  
}

- (void)spotx:(SpotXAdPlayer *_Nonnull)player adSkipped:(SpotXAd *_Nonnull)ad {
  self.giveReward = NO;
}

- (void)spotx:(SpotXAdPlayer *_Nonnull)player adUserClose:(SpotXAd *_Nonnull)ad {
  self.giveReward = NO;
}

- (void)spotx:(SpotXAdPlayer *_Nonnull)player adError:(SpotXAd *_Nullable)ad error:(NSError *_Nullable)error {
  dispatch_async(dispatch_get_main_queue(), ^{
    NSString *description = @"Error while attempting to play ads";
    NSDictionary *userInfo = @{NSLocalizedDescriptionKey : description, NSLocalizedFailureReasonErrorKey : description, NSUnderlyingErrorKey : error};
    NSError *chainedError = [NSError errorWithDomain:customEventErrorDomain code:0 userInfo:userInfo];
    [self.rewardBasedVideoAdConnector adapter:self didFailToLoadRewardBasedVideoAdwithError:chainedError];
  });
}

- (void)spotx:(SpotXAdPlayer *_Nonnull)player adGroupComplete:(SpotXAdGroup *_Nonnull)group {
  dispatch_async(dispatch_get_main_queue(), ^{
    id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = self.rewardBasedVideoAdConnector;
    id<GADMRewardBasedVideoAdNetworkAdapter> strongAdapter = self;
    [strongConnector adapterDidCloseRewardBasedVideoAd:strongAdapter];
    
    // If the user watched the full video, give reward
    if (self.giveReward) {
      GADAdReward *reward = [[GADAdReward alloc] initWithRewardType:self.rewardType rewardAmount:self.rewardAmount];
      [strongConnector adapter:strongAdapter didRewardUserWithReward:reward];
    }
  });
}

@end
