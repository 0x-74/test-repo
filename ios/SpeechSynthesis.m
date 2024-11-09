#import <Foundation/Foundation.h>
#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(SpeechSynthesis, NSObject)

// Load a text into the synthesizer without starting playback
RCT_EXTERN_METHOD(load:(NSString *)text
                  rate:(float)rate
                  pitchMultiplier:(float)pitchMultiplier
                  volume:(float)volume
                  voiceLanguage:(NSString *)voiceLanguage
                  voiceIdentifier:(NSString *)voiceIdentifier
                  withCallback:(RCTResponseSenderBlock)callback)

// Start speaking the loaded text
RCT_EXTERN_METHOD(speak:(NSString *)debug
                  withCallback:(RCTResponseSenderBlock)callback)

// Stop the synthesizer from speaking immediately if active
RCT_EXTERN_METHOD(stop:(NSString *)debug
                  withCallback:(RCTResponseSenderBlock)callback)

// Pause the speech if the synthesizer is currently speaking
RCT_EXTERN_METHOD(pause:(NSString *)debug
                  withCallback:(RCTResponseSenderBlock)callback)

// List all available voices
RCT_EXTERN_METHOD(listAllVoices:(NSString *)debug
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

// Request permission for Personal Voice
RCT_EXTERN_METHOD(requestPersonalVoicePermission:(NSString *)debug
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

// List all Personal Voices available on the device
RCT_EXTERN_METHOD(listPersonalVoices:(NSString *)debug
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

// List Siri Voices based on language code and gender
RCT_EXTERN_METHOD(listSiriVoices:(NSString *)debug
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

// Get the current language code for the synthesizer
RCT_EXTERN_METHOD(getCurrentLanguageCode:(NSString *)debug
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

// Get the current language code for the synthesizer
RCT_EXTERN_METHOD(createAudioFile:(NSString *)filePath
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

@end
