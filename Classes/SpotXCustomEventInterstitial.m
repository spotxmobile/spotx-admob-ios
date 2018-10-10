//
//  SpotXCustomEventInterstitial.m
//  SpotX-AdMob-Plugin
//

@import SpotX;
#import "SpotXCustomEventInterstitial.h"

/// Constant for our Error Domain.
static NSString *const customEventErrorDomain = @"tv.spotx.SpotXCustomEventInterstitial";

@interface SpotXCustomEventInterstitial () <SpotXAdPlayerDelegate>

@property(nonatomic, strong, nonnull) SpotXInterstitialAdPlayer* interstitial;
@property(nonatomic, copy, nullable) NSString *apiKey;
@property(nonatomic, copy, nonnull) NSString *channelId;
@property(nonatomic, strong, nullable) NSDictionary* paramDict;
@property(nonatomic, strong, nullable) NSDictionary* customDict;
@property(nonatomic, strong, nullable) NSDictionary* playbackOptionDict;

@end

@implementation SpotXCustomEventInterstitial
@synthesize delegate;

#pragma mark GADCustomEventInterstitial implementation

- (void)requestInterstitialAdWithParameter:(NSString *)serverParameter
                                     label:(NSString *)serverLabel
                                   request:(GADCustomEventRequest *)request {
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
    [self.delegate customEventInterstitial:self didFailAd:error];
    return;
  }
  
  self.interstitial = [[SpotXInterstitialAdPlayer alloc] init];
  self.interstitial.delegate = self;
  [SpotX debugMode:request.isTesting];
  [self.interstitial load];
}

/// Present the interstitial ad as a modal view using the provided view controller.
- (void)presentFromRootViewController:(UIViewController *)rootViewController {
  if (self.interstitial.adGroup.ads.count > 0) {
    [self.interstitial start];
  }
}

#pragma mark - SpotXAdPlayerDelegate methods

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
    if (error || group.ads.count == 0) {
      NSString *description = @"Unable to load ads to play";
      NSDictionary *userInfo = @{NSLocalizedDescriptionKey : description, NSLocalizedFailureReasonErrorKey : description, NSUnderlyingErrorKey : error};
      NSError *chainedError = [NSError errorWithDomain:customEventErrorDomain code:0 userInfo:userInfo];
      [self.delegate customEventInterstitial:self didFailAd:chainedError];
    } else {
      [self.delegate customEventInterstitialDidReceiveAd:self];
    }
  });
}

- (void)spotx:(SpotXAdPlayer *_Nonnull)player adGroupStart:(SpotXAdGroup *_Nonnull)group {
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.delegate customEventInterstitialWillPresent:self];
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
    [self.delegate customEventInterstitialWasClicked:self];
    [self.delegate customEventInterstitialWillLeaveApplication:self];
  });
}

- (void)spotx:(SpotXAdPlayer *_Nonnull)player adComplete:(SpotXAd *_Nonnull)ad {
  
}

- (void)spotx:(SpotXAdPlayer *_Nonnull)player adSkipped:(SpotXAd *_Nonnull)ad {
  
}

- (void)spotx:(SpotXAdPlayer *_Nonnull)player adUserClose:(SpotXAd *_Nonnull)ad {
  
}

- (void)spotx:(SpotXAdPlayer *_Nonnull)player adError:(SpotXAd *_Nullable)ad error:(NSError *_Nullable)error {
  dispatch_async(dispatch_get_main_queue(), ^{
    NSString *description = @"Error while attempting to play ads";
    NSDictionary *userInfo = @{NSLocalizedDescriptionKey : description, NSLocalizedFailureReasonErrorKey : description, NSUnderlyingErrorKey : error};
    NSError *chainedError = [NSError errorWithDomain:customEventErrorDomain code:0 userInfo:userInfo];
    [self.delegate customEventInterstitial:self didFailAd:chainedError];
  });
}

- (void)spotx:(SpotXAdPlayer *_Nonnull)player adGroupComplete:(SpotXAdGroup *_Nonnull)group {
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.delegate customEventInterstitialWillDismiss:self];
    [self.delegate customEventInterstitialDidDismiss:self];
  });
}

@end
