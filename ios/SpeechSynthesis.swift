import AVFoundation
import React

@objc(SpeechSynthesis)
class SpeechSynthesis: NSObject, AVSpeechSynthesizerDelegate {
  
  private var synthesizer = AVSpeechSynthesizer()
  private var onEndCallback: RCTResponseSenderBlock?
  
  // Store utterance properties
  private var utteranceText: String?
  private var utteranceRate: Float = AVSpeechUtteranceDefaultSpeechRate
  private var utterancePitchMultiplier: Float = 1.0
  private var utteranceVolume: Float = 1.0
  private var utteranceVoice: AVSpeechSynthesisVoice?
  
  // For createAudioFile
  private struct AudioFileCreation {
    var resolve: RCTPromiseResolveBlock?
    var reject: RCTPromiseRejectBlock?
    var completed: Bool
    var outputFile: AVAudioFile?
  }
  
  // For createAudioFile
  private var audioFileCreation: AudioFileCreation?
  
  enum SpeechSynthesisError: String {
    case noUtterance = "E_NO_UTTERANCE"
    case writeFailed = "E_WRITE_FAILED"
    case speechCancelled = "E_SPEECH_CANCELLED"
  }
  
  enum SpeechSynthesisErrorMessage: String {
    case noUtterance = "No text loaded to convert to audio file"
    case writeFailed = "Failed to write audio buffer"
    case speechCancelled = "Speech synthesis was cancelled"
  }
  
  
  override init() {
    super.init()
    setupAudioSession()
    self.synthesizer.delegate = self
  }
  
  /**
   * Sets up the audio session to allow sound mixing with other media playback.
   */
  private func setupAudioSession() {
    do {
      let audioSession = AVAudioSession.sharedInstance()
      try audioSession.setCategory(.playback, options: [.mixWithOthers, .duckOthers])
      try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    } catch {
      print("[SpeechSynthesis] Failed to set up audio session: \(error)")
    }
  }
  
  /**
   * Indicates whether the module requires main queue setup.
   * This is necessary for AVSpeechSynthesizer to operate on the main thread.
   */
  @objc
  static func requiresMainQueueSetup() -> Bool {
    return true
  }
  
  /**
   * Loads a text into the synthesizer without starting playback.
   *
   * - Parameters:
   *   - text: The text to load for speech synthesis.
   *   - rate: The speech rate; default is `AVSpeechUtteranceDefaultSpeechRate`.
   *   - pitchMultiplier: The pitch of the voice; default is `1.0`.
   *   - volume: The volume of the speech; default is `1.0`.
   *   - voiceLanguage: The language of the voice; default is `"en-US"`.
   *   - voiceIdentifier: Optional identifier for a specific voice.
   *   - callback: Callback providing the status of the load operation.
   */
  @objc
  func load(
    _ text: NSString,
    rate: Float = AVSpeechUtteranceDefaultSpeechRate,
    pitchMultiplier: Float = 1.0,
    volume: Float = 1.0,
    voiceLanguage: NSString = "en-US",
    voiceIdentifier: NSString?,
    withCallback callback: @escaping RCTResponseSenderBlock
  ) {
    self.utteranceText = text as String
    self.utteranceRate = rate
    self.utterancePitchMultiplier = pitchMultiplier
    self.utteranceVolume = volume
    
    if let voiceIdentifier = voiceIdentifier as String?,
       let specificVoice = AVSpeechSynthesisVoice(identifier: voiceIdentifier) {
      self.utteranceVoice = specificVoice
    } else if let voice = AVSpeechSynthesisVoice(language: voiceLanguage as String) {
      self.utteranceVoice = voice
    } else {
      self.utteranceVoice = nil
    }
    
    callback([["message": "Text loaded successfully"]])
  }
  
  /**
   * Starts speaking the currently loaded text.
   * If already speaking, stops the current speech before starting the new one.
   *
   * - Parameters:
   *   - debug: Optional debug information.
   *   - callback: Callback providing the status of the speech operation.
   */
  @objc
  func speak(
    _ debug: NSString?,
    withCallback callback: @escaping RCTResponseSenderBlock
  ) {
    guard let utteranceText = self.utteranceText else {
      callback([["error": SpeechSynthesisError.noUtterance.rawValue, "message": SpeechSynthesisErrorMessage.noUtterance.rawValue]])
      return
    }
    
    //            if synthesizer.isSpeaking {
    //                callback([["error": "E_ALREADY_SPEAKING", "message": "Speech synthesis is already in progress"]])
    //                return
    //            }
    
    // Create a new AVSpeechUtterance
    let utterance = AVSpeechUtterance(string: utteranceText)
    utterance.rate = self.utteranceRate
    utterance.pitchMultiplier = self.utterancePitchMultiplier
    utterance.volume = self.utteranceVolume
    utterance.voice = self.utteranceVoice
    
    self.onEndCallback = callback
    
    
    
    
    if synthesizer.isPaused {
      synthesizer.continueSpeaking()
    } else {
      if synthesizer.isSpeaking {
        synthesizer.stopSpeaking(at: .immediate)
      }
      synthesizer.speak(utterance)
    }
  }
  
  /**
   Stops the synthesizer from speaking immediately if it is currently speaking or paused.
   - Parameters:
   - debug: Optional text parameter (not used in the function).
   */
  @objc
  func stop(
    _ debug: NSString?,
    withCallback callback: @escaping RCTResponseSenderBlock
  ) {
    if synthesizer.isSpeaking || synthesizer.isPaused {
      synthesizer.stopSpeaking(at: .immediate)
      callback([["message": "Stopped successfully"]])
    } else {
      callback([["message": "Nothing was speaking to stop"]])
    }
  }
  
  /**
   * Pauses the speech if the synthesizer is currently speaking.
   *
   * - Parameters:
   *   - debug: Optional debug information.
   *   - callback: Callback providing the status of the pause operation.
   */
  @objc
  func pause(
    _ debug: NSString?,
    withCallback callback: @escaping RCTResponseSenderBlock
  ) {
    if synthesizer.isSpeaking {
      synthesizer.pauseSpeaking(at: .immediate)
      callback([["message": "Paused successfully"]])
    } else {
      callback([["message": "Nothing is currently speaking"]])
    }
  }
  
  private func formatVoiceArray(_ voices: [AVSpeechSynthesisVoice]) -> [[String: String]] {
    return voices.map {
      [
        "identifier": $0.identifier,
        "language": $0.language,
        "name": $0.name,
        "description": $0.description,
      ]
    }
  }
  
  /**
   Lists all available voices on the device, returning an array of dictionaries containing the identifier, language, and name of each voice.
   
   - Parameters:
   - debug: Optional text parameter (not used in the function).
   - resolver: A block to call if the function succeeds, returns an array of voice dictionaries.
   - rejecter: A block to call if the function fails.
   */
  @objc
  func listAllVoices(
    _ debug: NSString?,
    resolver resolve: @escaping RCTPromiseResolveBlock,
    rejecter reject: @escaping RCTPromiseRejectBlock
  ) {
    // ENHANCED: let voices = AVSpeechSynthesisVoice.speechVoices().filter { $0.quality == .enhanced }
    // PREMIUM:  let voices = AVSpeechSynthesisVoice.speechVoices().filter { $0.quality == .premium }
    // NOVELTY:  let voices = AVSpeechSynthesisVoice.speechVoices().filter { $0.voiceTraits.contains(.isNoveltyVoice) }
    // NOT NOVELTY let voices = AVSpeechSynthesisVoice.speechVoices().filter { !$0.voiceTraits.contains(.isNoveltyVoice) }
    // SIRI: let voices = AVSpeechSynthesisVoice.speechVoices().filter { $0.identifier.contains("siri")
    // PERSONAL: let voices = AVSpeechSynthesisVoice.speechVoices().filter { $0.voiceTraits.contains(.isPersonalVoice) }
    
    let voices = AVSpeechSynthesisVoice.speechVoices()
    resolve(formatVoiceArray(voices))
  }
  
  /**
   Requests permission to access Personal Voice on iOS 17 and above.
   
   - Parameters:
   - debug: Optional debug information for logging purposes.
   - resolve: Callback that returns a string indicating the authorization status ("authorized", "denied", "unsupported", "notDetermined" or "unknown").
   - reject: Callback in case of any errors.
   */
  @available(iOS 17.0, *)
  @objc
  func requestPersonalVoicePermission(
    _ debug: NSString?,
    resolver resolve: @escaping RCTPromiseResolveBlock,
    rejecter reject: @escaping RCTPromiseRejectBlock
  ) {
    
    AVSpeechSynthesizer.requestPersonalVoiceAuthorization { status in
      let statusString: String
      switch status {
      case .authorized: statusString = "authorized"
      case .denied: statusString = "denied"
      case .unsupported: statusString = "unsupported"
      case .notDetermined: statusString = "notDetermined"
      @unknown default: statusString = "unknown"
      }
      resolve(statusString)
    }
  }
  
  /**
   Lists all Personal Voices available on the device on iOS 17 and above.
   
   - Parameters:
   - debug: Optional debug information for logging purposes.
   - resolve: Callback that returns an array of voice identifiers if Personal Voices are available, or a message if none are found.
   - reject: Callback in case of any errors.
   */
  @available(iOS 17.0, *)
  @objc
  func listPersonalVoices(
    _ debug: NSString?,
    resolver resolve: @escaping RCTPromiseResolveBlock,
    rejecter reject: @escaping RCTPromiseRejectBlock) {
      let voices = AVSpeechSynthesisVoice.speechVoices().filter { $0.voiceTraits.contains(.isPersonalVoice) }
      if voices.isEmpty {
        print("[SpeechSynthesis] No Personal Voices available.")
      }
      resolve(formatVoiceArray(voices))
    }
  
  
  /**
   Lists Siri Voices based on the provided language code and gender.
   
   - Parameters:
   - debug: Optional debug information for logging purposes.
   - languageCode: Optional language code to filter Siri voices (e.g., "en-US").
   - gender: Optional gender to filter Siri voices ("male" or "female").
   - resolve: Callback that returns an array of Siri voice identifiers that match the criteria or a message if none are available.
   - reject: Callback in case of any errors.
   */
  @objc
  func listSiriVoices(
    _ debug: NSString?,
    resolver resolve: @escaping RCTPromiseResolveBlock,
    rejecter reject: @escaping RCTPromiseRejectBlock) {
      let voices = AVSpeechSynthesisVoice.speechVoices().filter { $0.identifier.contains("siri")
      }
      if voices.isEmpty {
        print("[SpeechSynthesis] No Siri Voices available.")
      }
      resolve(formatVoiceArray(voices))
    }
  
  /**
   * Gets the current language code set on the device.
   *
   * - Parameters:
   *   - debug: Optional debug information.
   *   - resolve: Callback returning the current language code.
   */
  @objc
  func getCurrentLanguageCode(
    _ debug: NSString?,
    resolver resolve: @escaping RCTPromiseResolveBlock,
    rejecter reject: @escaping RCTPromiseRejectBlock) {
      resolve(AVSpeechSynthesisVoice.currentLanguageCode())
    }
  
  /**
   * Creates an audio file from the pre-loaded utterance and saves it to the specified path.
   *
   * - Parameters:
   *   - filePath: The file path where the .caf audio file will be saved.
   *   - resolve: A block that returns `true` if the file is created successfully, `false` otherwise.
   *   - reject: A block to call if an error occurs during file creation.
   */
  @objc
  func createAudioFile(
    _ filePath: NSString,
    resolver resolve: @escaping RCTPromiseResolveBlock,
    rejecter reject: @escaping RCTPromiseRejectBlock
  ) {
    guard let utteranceText = self.utteranceText else {
      reject(SpeechSynthesisError.noUtterance.rawValue, SpeechSynthesisErrorMessage.noUtterance.rawValue, nil)
      return
    }
    
    //            if synthesizer.isSpeaking {
    //                reject("E_ALREADY_SPEAKING", "Speech synthesis is already in progress", nil)
    //                return
    //            }
    
    // Create a new AVSpeechUtterance
    let utterance = AVSpeechUtterance(string: utteranceText)
    utterance.rate = self.utteranceRate
    utterance.pitchMultiplier = self.utterancePitchMultiplier
    utterance.volume = self.utteranceVolume
    utterance.voice = self.utteranceVoice
    
    audioFileCreation = AudioFileCreation(resolve: resolve, reject: reject, completed: false, outputFile: nil)
    
    let audioFilePath = URL(fileURLWithPath: filePath as String)
    
    synthesizer.write(utterance) { [weak self] (buffer: AVAudioBuffer) in
      guard let self = self else { return }
      if let pcmBuffer = buffer as? AVAudioPCMBuffer {
        do {
          if self.audioFileCreation?.outputFile == nil {
            self.audioFileCreation?.outputFile = try AVAudioFile(forWriting: audioFilePath, settings: pcmBuffer.format.settings)
          }
          try self.audioFileCreation?.outputFile?.write(from: pcmBuffer)
        } catch {
          if self.audioFileCreation?.completed == false {
            self.audioFileCreation?.completed = true
            self.synthesizer.stopSpeaking(at: .immediate)
            self.audioFileCreation?.reject?(SpeechSynthesisError.writeFailed.rawValue, SpeechSynthesisErrorMessage.writeFailed.rawValue, error)
            self.audioFileCreation = nil
          }
        }
      }
    }
  }
  
  /**
   * Delegate method called when the synthesizer finishes speaking.
   */
  
  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
    // Handle createAudioFile completion
    if let audioFileCreation = self.audioFileCreation, !audioFileCreation.completed {
      audioFileCreation.resolve?(true)
      self.audioFileCreation = nil
    }
    
    // Handle speak() completion
    if let callback = onEndCallback {
      callback([["success": true, "message": "[SpeechSynthesis] Speech finished successfully"]])
      onEndCallback = nil
    }
  }
  
  /**
   * Delegate method called if speech synthesis is interrupted or fails.
   */
  
  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
    // Handle createAudioFile interruption
    if let audioFileCreation = self.audioFileCreation, !audioFileCreation.completed {
      audioFileCreation.reject?(SpeechSynthesisError.speechCancelled.rawValue, SpeechSynthesisErrorMessage.speechCancelled.rawValue, nil)
      self.audioFileCreation = nil
    }
    
    // Handle speak() interruption
    if let callback = onEndCallback {
      callback([["success": false, "message": "[SpeechSynthesis] Speech interrupted"]])
      onEndCallback = nil
    }
  }
}
