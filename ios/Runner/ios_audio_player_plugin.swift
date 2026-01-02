import Flutter
import UIKit
import AVFoundation
import MediaPlayer

public class IOSAudioPlayerPlugin: NSObject, FlutterPlugin {
    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var equalizer: AVAudioUnitEQ?
    private var timePitch: AVAudioUnitTimePitch?
    private var audioFiles: [AVAudioFile] = []
    internal var currentIndex: Int = 0
    internal var isPlaying: Bool = false
    internal var loopMode: String = "off"
    internal var isShuffleEnabled: Bool = false
    private var playbackSpeed: Float = 1.0
    private var originalAudioFiles: [AVAudioFile] = []  // Store original order
    private var isShuffled: Bool = false
    private var shuffleIndices: [Int] = []

    // Position tracking
    private var timer: Timer?
    private var positionInSamples: AVAudioFramePosition = 0
    private var seekPosition: AVAudioFramePosition = 0
    private var isSeeking: Bool = false
    private var lastNotifiedPosition: Int = -1
    private var lastNotifiedIndex: Int = -1
    private var isChangingTrack: Bool = false
    private var isSettingPlaylist: Bool = false // NEW: Prevent concurrent playlist changes
    private var currentlyScheduledIndex: Int = -1
    // Event sinks
    var eventSink: FlutterEventSink?
    var positionEventSink: FlutterEventSink?
    var durationEventSink: FlutterEventSink?
    var indexEventSink: FlutterEventSink?
    var shuffleEventSink: FlutterEventSink?
    var loopEventSink: FlutterEventSink?


    // Equalizer
    private let frequencies: [Float] = [60, 230, 910, 3600, 14000]
    private let numberOfBands = 5
    private var isEqualizerEnabled: Bool = false
    
    // Debug: Track scheduleCurrentFile calls
    private var scheduleCallCount: Int = 0

    // MARK: - Plugin Registration

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.example.music_app.ios_audio_player",
            binaryMessenger: registrar.messenger()
        )
        let instance = IOSAudioPlayerPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        instance.setupEventChannels(registrar: registrar)
    }

    private func setupEventChannels(registrar: FlutterPluginRegistrar) {
        FlutterEventChannel(
            name: "com.example.music_app.ios_audio_player/playing_stream",
            binaryMessenger: registrar.messenger()
        ).setStreamHandler(PlayingStreamHandler(plugin: self))

        FlutterEventChannel(
            name: "com.example.music_app.ios_audio_player/position_stream",
            binaryMessenger: registrar.messenger()
        ).setStreamHandler(PositionStreamHandler(plugin: self))

        FlutterEventChannel(
            name: "com.example.music_app.ios_audio_player/duration_stream",
            binaryMessenger: registrar.messenger()
        ).setStreamHandler(DurationStreamHandler(plugin: self))
        
        FlutterEventChannel(
            name: "com.example.music_app.ios_audio_player/index_stream",
            binaryMessenger: registrar.messenger()
        ).setStreamHandler(IndexStreamHandler(plugin: self))
    }

    // MARK: - Method Handler

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":
            initializePlayer(result: result)

        case "setPlaylist":
            guard let args = call.arguments as? [String: Any],
                  let filePaths = args["filePaths"] as? [String] else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                return
            }
            let startIndex = args["startIndex"] as? Int ?? 0
            let autoPlay = args["autoPlay"] as? Bool ?? true
            setPlaylist(filePaths: filePaths, startIndex: startIndex, autoPlay: autoPlay, result: result)

        case "play":
            play(result: result)

        case "pause":
            pause(result: result)

        case "stop":
            stop(result: result)

        case "seekToNext":
            seekToNext(result: result)

        case "seekToPrevious":
            seekToPrevious(result: result)

        case "seek":
            guard let args = call.arguments as? [String: Any],
                  let positionMs = args["position"] as? Int else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                return
            }
            let index = args["index"] as? Int
            seek(positionMs: positionMs, index: index, result: result)

        case "setSpeed":
            guard let args = call.arguments as? [String: Any],
                  let speed = args["speed"] as? Double else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                return
            }
            setSpeed(speed: Float(speed), result: result)

        case "setLoopMode":
            guard let args = call.arguments as? [String: Any],
                  let mode = args["mode"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                return
            }
            setLoopMode(mode: mode, result: result)

        case "setShuffleEnabled":
            guard let args = call.arguments as? [String: Any],
                  let enabled = args["enabled"] as? Bool else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                return
            }
            setShuffleEnabled(enabled: enabled, result: result)

        case "getCurrentIndex":
            result(currentIndex)

        case "isPlaying":
            result(isPlaying)

        case "getPosition":
            result(getCurrentPositionMs())

        case "getDuration":
            result(getCurrentDurationMs())

        // Equalizer methods
        case "eq_setEnabled":
            guard let args = call.arguments as? [String: Any],
                  let enabled = args["enabled"] as? Bool else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                return
            }
            setEqualizerEnabled(enabled: enabled, result: result)

        case "eq_setBandLevel":
            guard let args = call.arguments as? [String: Any],
                  let bandIndex = args["bandIndex"] as? Int,
                  let gain = args["gain"] as? Double else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                return
            }
            setEqualizerBandLevel(bandIndex: bandIndex, gain: Float(gain), result: result)

        case "eq_getBandLevels":
            getEqualizerBandLevels(result: result)

        case "eq_getFrequencies":
            result(frequencies.map { Double($0) })

        case "eq_setBassBoost":
            guard let args = call.arguments as? [String: Any],
                  let strength = args["strength"] as? Double else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                return
            }
            setBassBoost(strength: Float(strength), result: result)

        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    
    // MARK: - Shuffle Indices

    private func generateShuffleIndices() {
        shuffleIndices = Array(0..<audioFiles.count)
        shuffleIndices.shuffle()
        print("🔀 Shuffle indices generated: \(shuffleIndices)")
    }

    // MARK: - Player Initialization

    private func initializePlayer(result: @escaping FlutterResult) {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)

            audioEngine = AVAudioEngine()
            playerNode = AVAudioPlayerNode()
            equalizer = AVAudioUnitEQ(numberOfBands: numberOfBands)
            timePitch = AVAudioUnitTimePitch()

            guard let engine = audioEngine,
                  let node = playerNode,
                  let eq = equalizer,
                  let pitch = timePitch else {
                result(FlutterError(code: "INIT_FAILED", message: "Failed to create audio components", details: nil))
                return
            }

            engine.attach(node)
            engine.attach(eq)
            engine.attach(pitch)

            for i in 0..<numberOfBands {
                let band = eq.bands[i]
                band.frequency = frequencies[i]
                band.gain = 0.0
                band.bypass = false
                band.filterType = .parametric
                band.bandwidth = 0.5
            }

            eq.bypass = true

            let mixer = engine.mainMixerNode
            let format = node.outputFormat(forBus: 0)

            engine.connect(node, to: eq, format: format)
            engine.connect(eq, to: pitch, format: format)
            engine.connect(pitch, to: mixer, format: format)

            engine.prepare()
            try engine.start()

            setupRemoteTransportControls()

            print("✅ iOS Audio Player initialized")
            result(true)

        } catch {
            print("❌ Init error: \(error)")
            result(FlutterError(code: "INIT_ERROR", message: error.localizedDescription, details: nil))
        }
    }

    // MARK: - Playlist Management

    /* private func setPlaylist(filePaths: [String], startIndex: Int, autoPlay: Bool, result: @escaping FlutterResult) {
        audioFiles.removeAll()
         // FIX: Stop any currently playing audio before loading new playlist
        safeStopPlayerNode()
        // FIX: Reset position tracking to prevent old values from persisting
        positionInSamples = 0
        seekPosition = 0
        lastNotifiedPosition = -1
        // FIX: Reset the currently scheduled index to invalidate old completion handlers
        lastNotifiedIndex = -1
        currentlyScheduledIndex = -1
        isSettingPlaylist = true // ✅ Prevent concurrent calls

        do {
            print("📂 Loading \(filePaths.count) audio files...")
           for (index, path) in filePaths.enumerated() {
                       let file = try AVAudioFile(forReading: URL(fileURLWithPath: path))
                       audioFiles.append(file)
                       print("  [\(index)] Loaded: \(URL(fileURLWithPath: path).lastPathComponent)")
                   }

            currentIndex = max(0, min(startIndex, audioFiles.count - 1))
            print("✅ Loaded \(audioFiles.count) songs, starting at index \(currentIndex)")

            if !audioFiles.isEmpty {
                scheduleCurrentFile()
                
                // Emit initial index only once
                lastNotifiedIndex = currentIndex
                indexEventSink?(currentIndex)
                print("📍 Initial index emitted: \(currentIndex)")

             let duration = getCurrentDurationMs()
            print("📏 Current file duration: \(duration)ms")
            durationEventSink?(duration)
            print("✅ Playlist set with \(audioFiles.count) songs, starting at index \(currentIndex)")

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                                guard let self = self else { return }
                                self.isSettingPlaylist = false // ✅ Allow new calls
                                if autoPlay {
                                    print("▶️ autoPlay enabled, starting playback...")
                                    self.play(result: result)
                                } else {
                                    print("⏸️ autoPlay disabled, ready to play")
                                    result(true)
                                }
                            }
            } else {
            isSettingPlaylist = false
                result(true)
            }

        } catch {
        isSettingPlaylist = false
            print("❌ Playlist error: \(error)")
            result(FlutterError(code: "PLAYLIST_ERROR", message: error.localizedDescription, details: nil))
        }
    } */

   private func setPlaylist(filePaths: [String], startIndex: Int, autoPlay: Bool, result: @escaping FlutterResult) {
       audioFiles.removeAll()

       // Stop any currently playing audio before loading new playlist
       safeStopPlayerNode()

       // Reset position tracking
       positionInSamples = 0
       seekPosition = 0
       lastNotifiedPosition = -1
       lastNotifiedIndex = -1
       currentlyScheduledIndex = -1
       isSettingPlaylist = true

       do {
           print("📂 Loading \(filePaths.count) audio files...")
           for (index, path) in filePaths.enumerated() {
               let file = try AVAudioFile(forReading: URL(fileURLWithPath: path))
               audioFiles.append(file)
               print("  [\(index)] Loaded: \(URL(fileURLWithPath: path).lastPathComponent)")
           }

           currentIndex = max(0, min(startIndex, audioFiles.count - 1))
           print("✅ Loaded \(audioFiles.count) songs, starting at index \(currentIndex)")

           if !audioFiles.isEmpty {
               scheduleCurrentFile()

               // Emit initial index
               lastNotifiedIndex = currentIndex
               indexEventSink?(currentIndex)
               print("📍 Initial index emitted: \(currentIndex)")

               let duration = getCurrentDurationMs()
               print("📏 Current file duration: \(duration)ms")
               durationEventSink?(duration)

               // ✅ CRITICAL FIX: Start playback immediately if autoPlay is true
               // Don't use async delay - start playback synchronously
               isSettingPlaylist = false

               if autoPlay {
                   print("▶️ autoPlay enabled, starting playback immediately...")

                   // Ensure audio engine is running
                   guard let engine = audioEngine, let node = playerNode else {
                       result(FlutterError(code: "NOT_INITIALIZED", message: "Player not initialized", details: nil))
                       return
                   }

                   do {
                       if !engine.isRunning {
                           try engine.start()
                           print("✅ Audio engine started")
                       }

                       // Start playback immediately
                       node.play()
                       isPlaying = true
                       startPositionTimer()
                       notifyPlayingStateChanged()
                       updateNowPlayingInfo()

                       print("✅ Playback started successfully")
                       result(true)

                   } catch {
                       print("❌ Error starting playback: \(error)")
                       result(FlutterError(code: "PLAY_ERROR", message: error.localizedDescription, details: nil))
                   }
               } else {
                   print("⏸️ autoPlay disabled, ready to play")
                   result(true)
               }
           } else {
               isSettingPlaylist = false
               result(true)
           }

       } catch {
           isSettingPlaylist = false
           print("❌ Playlist error: \(error)")
           result(FlutterError(code: "PLAYLIST_ERROR", message: error.localizedDescription, details: nil))
       }
   }

    private func scheduleCurrentFile() {
        guard let node = playerNode,
              currentIndex >= 0 && currentIndex < audioFiles.count else {
            return
        }

        let file = audioFiles[currentIndex]
        
       print("📀 scheduleCurrentFile() for index \(currentIndex): \(file.url.lastPathComponent)")
        
        safeStopPlayerNode()

        positionInSamples = 0
        seekPosition = 0
        lastNotifiedPosition = -1

        // Capture current index to prevent stale completion handlers
          currentlyScheduledIndex = currentIndex
                let scheduledIndex = currentIndex
//         let scheduledIndex = currentIndex
        
        node.scheduleFile(file, at: nil) { [weak self] in
            DispatchQueue.main.async {
                guard let self = self else { return }
                print("🏁 Completion handler fired for scheduledIndex: \(scheduledIndex), current: \(self.currentIndex), isChangingTrack: \(self.isChangingTrack)")
                // Only handle completion if we're still on the same track
                if self.currentlyScheduledIndex == scheduledIndex && !self.isChangingTrack {
                    self.handlePlaybackCompleted()
                } else {
                    print("⚠️ Ignoring stale completion handler")
                }
            }
        }

        // Immediately notify position reset
        positionEventSink?(0)
        notifyDurationChanged()

        print("✅ Scheduled: \(file.url.lastPathComponent) at index \(currentIndex)")
    }

    private func safeStopPlayerNode() {
        guard let engine = audioEngine, let node = playerNode else { return }

        if !engine.isRunning {
            try? engine.start()
        }

        if node.isPlaying {
            node.stop()
        }
    }

    // MARK: - Playback Control

    private func play(result: @escaping FlutterResult) {
        guard let node = playerNode, let engine = audioEngine else {
            result(FlutterError(code: "NOT_INITIALIZED", message: "Player not initialized", details: nil))
            return
        }

        do {
            if !engine.isRunning {
                try engine.start()
                 print("Audio engine started")
            }

            if !isPlaying {
            // Ensure the player node is properly attached and ready
                        if !node.engine!.attachedNodes.contains(node) {
                            print("⚠️ Player node not attached, reattaching...")
                            engine.attach(node)
                        }
                node.play()
                isPlaying = true
                stopPositionTimer() // Stop any existing timer
                startPositionTimer()
                notifyPlayingStateChanged()
                updateNowPlayingInfo()
                 print("▶️ Playback started at index \(currentIndex)")
            }else {
                 print("⚠️ Already playing, ignoring play() call")
             }

            result(true)
        } catch {
            print("❌ Play error: \(error)")
            result(FlutterError(code: "PLAY_ERROR", message: error.localizedDescription, details: nil))
        }
    }

    private func pause(result: @escaping FlutterResult) {
        guard let node = playerNode else {
            result(FlutterError(code: "NOT_INITIALIZED", message: "Player not initialized", details: nil))
            return
        }

        if isPlaying {
            node.pause()
            isPlaying = false
            stopPositionTimer()
            notifyPlayingStateChanged()
            updateNowPlayingInfo()
        }

        result(true)
    }

    private func stop(result: @escaping FlutterResult) {
        safeStopPlayerNode()
        isPlaying = false
        positionInSamples = 0
        seekPosition = 0
        lastNotifiedPosition = -1
        currentlyScheduledIndex = -1
        stopPositionTimer()
        notifyPlayingStateChanged()
        notifyPositionChanged()
         print("⏹️ Playback stopped")
        result(true)
    }

    private func seek(positionMs: Int, index: Int?, result: @escaping FlutterResult) {
        guard let node = playerNode, let engine = audioEngine else {
            result(FlutterError(code: "NOT_INITIALIZED", message: "Player not initialized", details: nil))
            return
        }


        let wasPlaying = isPlaying
        isSeeking = true

        stopPositionTimer()
        safeStopPlayerNode()

        // Track change
        if let newIndex = index, newIndex != currentIndex {
             guard !audioFiles.isEmpty else {
            isSeeking = false
            result(false)
            return
        }

        // Prevent overlapping track changes
        isChangingTrack = true

        currentIndex = max(0, min(newIndex, audioFiles.count - 1))

            guard currentIndex >= 0 && currentIndex < audioFiles.count else {
                isSeeking = false
                isChangingTrack = false
                result(false)
                return
            }


            let file = audioFiles[currentIndex]
            let sampleRate = file.processingFormat.sampleRate
            let targetFrame = AVAudioFramePosition(Double(positionMs) / 1000.0 * sampleRate)
            let clampedFrame = max(0, min(targetFrame, file.length))

            positionInSamples = clampedFrame
            seekPosition = clampedFrame
            lastNotifiedPosition = -1

            if clampedFrame < file.length {
                let frameCount = AVAudioFrameCount(file.length - clampedFrame)
                node.scheduleSegment(file, startingFrame: clampedFrame, frameCount: frameCount, at: nil) { [weak self] in
                    DispatchQueue.main.async {
                        self?.handlePlaybackCompleted()
                    }
                }
            }

            notifyIndexChanged()
            positionEventSink?(positionMs)
            notifyDurationChanged()

//             if wasPlaying {
                do {
                    if !engine.isRunning {
                        try engine.start()
                    }
                  // Delay play slightly to ensure segment is ready (fixes iOS silent playback)
                              DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                                  guard let self = self else { return }
                                  node.play()
                                  self.isPlaying = true
                                  self.startPositionTimer()
                                  self.notifyPlayingStateChanged()
                              }
                } catch {
                    print("❌ Error resuming playback: \(error)")
                }
//             }

//             notifyPlayingStateChanged()
            updateNowPlayingInfo()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.isSeeking = false
                  self?.isChangingTrack = false
            }

            result(true)
            return
        }

        // Seek within track
        guard currentIndex >= 0 && currentIndex < audioFiles.count else {
            isSeeking = false
            result(false)
            return
        }

        let file = audioFiles[currentIndex]
        let sampleRate = file.processingFormat.sampleRate
        let targetFrame = AVAudioFramePosition(Double(positionMs) / 1000.0 * sampleRate)
        let clampedFrame = max(0, min(targetFrame, file.length))

        positionInSamples = clampedFrame
        seekPosition = clampedFrame
        lastNotifiedPosition = -1

        if clampedFrame < file.length {
            let frameCount = AVAudioFrameCount(file.length - clampedFrame)
            node.scheduleSegment(file, startingFrame: clampedFrame, frameCount: frameCount, at: nil) { [weak self] in
                DispatchQueue.main.async {
                    self?.handlePlaybackCompleted()
                }
            }
        }

        positionEventSink?(positionMs)

        if wasPlaying {
            do {
                if !engine.isRunning {
                    try engine.start()
                }
                // Delay play slightly to ensure segment is ready
                           DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                               guard let self = self else { return }
                               node.play()
                               self.isPlaying = true
                               self.startPositionTimer()
                               self.notifyPlayingStateChanged()
                           }
            } catch {
                print("❌ Error resuming playback: \(error)")
            }
        }

//         notifyPlayingStateChanged()
        updateNowPlayingInfo()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.isSeeking = false
        }

        result(true)
    }

    private func seekToNext(result: @escaping FlutterResult) {
        guard !audioFiles.isEmpty else {
            result(false)
            return
        }

        print("⏭️ seekToNext called - current: \(currentIndex), total: \(audioFiles.count)")
        
        // Set flag to prevent old completion handlers from firing
        isChangingTrack = true
        
        stopPositionTimer()
        safeStopPlayerNode()

        // Calculate and update index
            let newIndex: Int
            if isShuffleEnabled && !shuffleIndices.isEmpty {
                newIndex = shuffleIndices.randomElement() ?? ((currentIndex + 1) % audioFiles.count)
                print("🔀 Shuffle next: \(currentIndex) -> \(newIndex)")
            } else {
                newIndex = (currentIndex + 1) % audioFiles.count
                print("📍 Normal next: \(currentIndex) -> \(newIndex)")
            }
        
        print("⏭️ Moving from index \(currentIndex) to \(newIndex)")
        
        // Only notify if index actually changed
//         let indexChanged = newIndex != currentIndex
        currentIndex = newIndex
        
        positionInSamples = 0
        seekPosition = 0
        lastNotifiedPosition = -1

        scheduleCurrentFile()
        
        // Notify index change ONCE
        if currentIndex != lastNotifiedIndex {
            lastNotifiedIndex = currentIndex
            indexEventSink?(currentIndex)
            print("✅ Index changed to \(currentIndex), notified Flutter")
        }

        guard let node = playerNode, let engine = audioEngine else {
            isChangingTrack = false
            result(false)
            return
        }

        do {
            if !engine.isRunning {
                try engine.start()
            }
            node.play()
            isPlaying = true
            startPositionTimer()
            notifyPlayingStateChanged()
            updateNowPlayingInfo()
            
            // Clear flag after longer delay to prevent race condition
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.isChangingTrack = false
            }
            
            result(true)
        } catch {
            print("❌ Error playing next: \(error)")
            isChangingTrack = false
            result(false)
        }
    }

    private func seekToPrevious(result: @escaping FlutterResult) {
        guard !audioFiles.isEmpty else {
            result(false)
            return
        }

        print("⏮️ seekToPrevious called - current: \(currentIndex), total: \(audioFiles.count)")
        
        // Set flag to prevent old completion handlers from firing
        isChangingTrack = true
        
        stopPositionTimer()
        safeStopPlayerNode()

        // Calculate and update index
            let newIndex: Int
            if isShuffleEnabled && !shuffleIndices.isEmpty {
                newIndex = shuffleIndices.randomElement() ?? (currentIndex > 0 ? currentIndex - 1 : audioFiles.count - 1)
                print("🔀 Shuffle prev: \(currentIndex) -> \(newIndex)")
            } else {
                newIndex = currentIndex > 0 ? currentIndex - 1 : audioFiles.count - 1
                print("📍 Normal prev: \(currentIndex) -> \(newIndex)")
            }


        currentIndex = newIndex
        
        positionInSamples = 0
        seekPosition = 0
        lastNotifiedPosition = -1

        scheduleCurrentFile()
        
        // Notify index change ONCE
      if currentIndex != lastNotifiedIndex {
            lastNotifiedIndex = currentIndex
            indexEventSink?(currentIndex)
            print("✅ Index changed to \(currentIndex), notified Flutter")
        }

        guard let node = playerNode, let engine = audioEngine else {
            isChangingTrack = false
            result(false)
            return
        }

        do {
            if !engine.isRunning {
                try engine.start()
            }
            node.play()
            isPlaying = true
            startPositionTimer()
            notifyPlayingStateChanged()
            updateNowPlayingInfo()
            
            // Clear flag after longer delay to prevent race condition
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.isChangingTrack = false
            }
            
            result(true)
        } catch {
            print("❌ Error playing previous: \(error)")
            isChangingTrack = false
            result(false)
        }
    }

    // MARK: - Playback Settings

    private func setSpeed(speed: Float, result: @escaping FlutterResult) {
        guard let pitch = timePitch else {
            result(false)
            return
        }

        playbackSpeed = max(0.25, min(speed, 2.0))
        pitch.rate = playbackSpeed
        updateNowPlayingInfo()

        result(true)
    }

    private func setLoopMode(mode: String, result: @escaping FlutterResult) {
        loopMode = mode
        result(true)
    }

    private func setShuffleEnabled(enabled: Bool, result: @escaping FlutterResult) {
       isShuffleEnabled = enabled

           // ✅ IMPORTANT: Don't shuffle the audioFiles array
           // Just store the shuffle state - native code will handle shuffle order on next track

             if enabled {
                 generateShuffleIndices()
                 print("🔀 iOS Shuffle: ON - Next songs will play in random order")
             } else {
                shuffleIndices.removeAll()
                print("🔀 iOS Shuffle: OFF - Normal order")
             }
        result(true)
    }
    

    // MARK: - Position Tracking

    private func startPositionTimer() {
        stopPositionTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, !self.isSeeking else { return }
            self.updatePosition()
        }
         print("⏱️ Position timer started (100ms interval)")
    }

    private func stopPositionTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func updatePosition() {
        guard let node = playerNode,
              let nodeTime = node.lastRenderTime,
              let playerTime = node.playerTime(forNodeTime: nodeTime),
              currentIndex >= 0 && currentIndex < audioFiles.count else {
            return
        }

        let file = audioFiles[currentIndex]
        positionInSamples = min(seekPosition + playerTime.sampleTime, file.length)

        let currentPosMs = getCurrentPositionMs()

        if abs(currentPosMs - lastNotifiedPosition) > 50 {
            lastNotifiedPosition = currentPosMs
            notifyPositionChanged()
        }
    }

    internal func getCurrentPositionMs() -> Int {
        guard currentIndex >= 0 && currentIndex < audioFiles.count else {
            return 0
        }

        let file = audioFiles[currentIndex]
        let sampleRate = file.processingFormat.sampleRate
        return Int((Double(positionInSamples) / sampleRate) * 1000)
    }

    internal func getCurrentDurationMs() -> Int {
        guard currentIndex >= 0 && currentIndex < audioFiles.count else {
            return 0
        }

        let file = audioFiles[currentIndex]
        let sampleRate = file.processingFormat.sampleRate
        return Int((Double(file.length) / sampleRate) * 1000)
    }

    // MARK: - Playback Completion
    
    private func handlePlaybackCompleted() {
          guard !isSeeking && !isChangingTrack else {
                print("⚠️ Ignoring completion - isSeeking: \(isSeeking), isChangingTrack: \(isChangingTrack)")
                return
            }

            print("🏁 Playback completed for index \(currentIndex)")

            switch loopMode {
            case "one":
                // Repeat current song
                scheduleCurrentFile()
                if let node = playerNode {
                    node.play()
                    isPlaying = true
                    startPositionTimer()
                    notifyPlayingStateChanged()
                    updateNowPlayingInfo()
                }

            case "all":
                // Move to next song
                 let newIndex: Int
                if isShuffleEnabled && !shuffleIndices.isEmpty {
                    // ✅ Random next index for shuffle
               newIndex = shuffleIndices.randomElement() ?? ((currentIndex + 1) % audioFiles.count)

//                     currentIndex = Int.random(in: 0..<audioFiles.count)
                    print("🔀 Shuffle: Random next index = \(newIndex)")
                } else {
                    // ✅ Sequential next index
                    newIndex = (currentIndex + 1) % audioFiles.count
                    print("📍 Normal: Next index = \(newIndex)")
                }
                currentIndex = newIndex
                scheduleCurrentFile()

                // Notify index change
                if currentIndex != lastNotifiedIndex {
                    lastNotifiedIndex = currentIndex
                    indexEventSink?(currentIndex)
                }

                if let node = playerNode {
                    node.play()
                    isPlaying = true
                    startPositionTimer()
                    notifyPlayingStateChanged()
                    updateNowPlayingInfo()
                }

            default:
                // No loop mode
                if currentIndex < audioFiles.count - 1 {
                 let newIndex: Int
                    if isShuffleEnabled && !shuffleIndices.isEmpty {
                        // ✅ Random next index
                        newIndex = shuffleIndices.randomElement() ?? ((currentIndex + 1) % audioFiles.count)
                        print("🔀 Shuffle: Random next index = \(newIndex)")
                    } else {
                        // ✅ Sequential next index
                        newIndex = currentIndex + 1
                        print("📍 Normal: Next index = \(newIndex)")
                    }
                    currentIndex = newIndex
                    scheduleCurrentFile()

                    // Notify index change
                    if currentIndex != lastNotifiedIndex {
                        lastNotifiedIndex = currentIndex
                        indexEventSink?(currentIndex)
                    }

                    if let node = playerNode {
                        node.play()
                        isPlaying = true
                        startPositionTimer()
                        notifyPlayingStateChanged()
                        updateNowPlayingInfo()
                    }
                } else {
                    // Last song completed - pause
                    isPlaying = false
                    stopPositionTimer()
                    notifyPlayingStateChanged()
                    print("⏸️ Last song - Paused")
                }
            }
    }


//    private func handlePlaybackCompleted() {
//        guard !isSeeking && !isChangingTrack else {
//            print("⚠️ Ignoring completion - isSeeking: \(isSeeking), isChangingTrack: \(isChangingTrack)")
//            return
//        }
//        
//        print("🏁 Playback completed for index \(currentIndex)")
//
//        switch loopMode {
//        case "one":
//            scheduleCurrentFile()
//            if let node = playerNode {
//                node.play()
//                isPlaying = true
//                startPositionTimer()
//                notifyPlayingStateChanged()
//                updateNowPlayingInfo()
//            }
//
//        case "all":
//            currentIndex = (currentIndex + 1) % audioFiles.count
//            scheduleCurrentFile()
//            
//            // Notify index change
//            if currentIndex != lastNotifiedIndex {
//                lastNotifiedIndex = currentIndex
//                indexEventSink?(currentIndex)
//            }
//            
//            if let node = playerNode {
//                node.play()
//                isPlaying = true
//                startPositionTimer()
//                notifyPlayingStateChanged()
//                updateNowPlayingInfo()
//            }
//
//        default:
//            if currentIndex < audioFiles.count - 1 {
//                currentIndex += 1
//                scheduleCurrentFile()
//                
//                // Notify index change
//                if currentIndex != lastNotifiedIndex {
//                    lastNotifiedIndex = currentIndex
//                    indexEventSink?(currentIndex)
//                }
//                
//                if let node = playerNode {
//                    node.play()
//                    isPlaying = true
//                    startPositionTimer()
//                    notifyPlayingStateChanged()
//                    updateNowPlayingInfo()
//                }
//            } else {
//                isPlaying = false
//                stopPositionTimer()
//                notifyPlayingStateChanged()
//            }
//        }
//    }

    // MARK: - Equalizer Methods

    private func setEqualizerEnabled(enabled: Bool, result: @escaping FlutterResult) {
        guard let eq = equalizer else {
            result(false)
            return
        }

        isEqualizerEnabled = enabled
        eq.bypass = !enabled

        print("🎚 Equalizer: \(enabled ? "ON" : "OFF")")
        result(true)
    }

    private func setEqualizerBandLevel(bandIndex: Int, gain: Float, result: @escaping FlutterResult) {
        guard let eq = equalizer,
              bandIndex >= 0 && bandIndex < numberOfBands else {
            result(FlutterError(code: "INVALID_BAND", message: "Invalid band index", details: nil))
            return
        }

        let clampedGain = max(-15.0, min(15.0, gain))
        eq.bands[bandIndex].gain = clampedGain

      // Apply compression after setting band level
      applyDynamicRangeCompression()

        print("🎚 Band \(bandIndex) (\(Int(frequencies[bandIndex]))Hz): \(clampedGain)dB")
        result(true)
    }

    private func getEqualizerBandLevels(result: @escaping FlutterResult) {
        guard let eq = equalizer else {
            result([])
            return
        }

        let levels = eq.bands.map { Double($0.gain) }
        result(levels)
    }

    private func setBassBoost(strength: Float, result: @escaping FlutterResult) {
        guard let eq = equalizer else {
            result(false)
            return
        }

        let clampedStrength = max(0, min(strength, 1.0))
        // FIXED: Reduced bass gain for clarity (max +6dB instead of +10dB)
            let bassGain = clampedStrength * 6.0
        // let bassGain = clampedStrength * 10.0

        if numberOfBands >= 2 {
            eq.bands[0].gain = bassGain
            eq.bands[1].gain = bassGain * 0.7
              if numberOfBands >= 3 && clampedStrength > 0.5 {
                        // Subtle mid reduction only at high bass boost levels
                        eq.bands[2].gain = eq.bands[2].gain - (clampedStrength - 0.5) * 1.0
                    }
        }

        //  Apply compression after bass boost
             applyDynamicRangeCompression()
         print("🔊 Bass boost: \(Int(clampedStrength * 100))% (Gain: \(bassGain)dB)")
        result(true)
    }

    private func applyDynamicRangeCompression() {
        guard let eq = equalizer else { return }

        // Calculate total positive gain across all bands
        var totalPositiveGain: Float = 0
        for band in eq.bands {
            if band.gain > 0 {
                totalPositiveGain += band.gain
            }
        }

        // Define safe threshold (adjust based on testing)
        let threshold: Float = 18.0 // Max total positive gain before compression

        // If total exceeds threshold, apply soft limiting
        if totalPositiveGain > threshold {
            let compressionRatio = threshold / totalPositiveGain

            print("⚠️ Total gain: \(totalPositiveGain)dB exceeds threshold: \(threshold)dB")
            print("🎚 Applying compression with ratio: \(compressionRatio)")

            // Apply compression only to positive gains
            for band in eq.bands where band.gain > 0 {
                let originalGain = band.gain
                band.gain *= compressionRatio

                print("   Band \(eq.bands.firstIndex(of: band) ?? -1): \(originalGain)dB → \(band.gain)dB")
            }

            print("✅ Compression applied - audio safe from clipping")
        }
    }

    // MARK: - Event Notifications

    private func notifyPlayingStateChanged() {
        eventSink?(isPlaying)
    }

    private func notifyPositionChanged() {
        positionEventSink?(getCurrentPositionMs())
    }

    private func notifyDurationChanged() {
        durationEventSink?(getCurrentDurationMs())
    }
    
    private func notifyIndexChanged() {
        // Only emit if index actually changed
        if currentIndex != lastNotifiedIndex {
            lastNotifiedIndex = currentIndex
            indexEventSink?(currentIndex)
        }
    }

    // MARK: - Now Playing & Remote Control

    private func setupRemoteTransportControls() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.play(result: { _ in })
            return .success
        }

        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pause(result: { _ in })
            return .success
        }

        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.seekToNext(result: { _ in })
            return .success
        }

        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.seekToPrevious(result: { _ in })
            return .success
        }

        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self = self,
                  let positionEvent = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }

            let positionMs = Int(positionEvent.positionTime * 1000)
            self.seek(positionMs: positionMs, index: nil, result: { _ in })
            return .success
        }
    }

    private func updateNowPlayingInfo() {
        var info = [String: Any]()

        info[MPMediaItemPropertyPlaybackDuration] = Double(getCurrentDurationMs()) / 1000.0
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = Double(getCurrentPositionMs()) / 1000.0
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? Double(playbackSpeed) : 0.0

        if currentIndex >= 0 && currentIndex < audioFiles.count {
            let file = audioFiles[currentIndex]
            info[MPMediaItemPropertyTitle] = file.url.deletingPathExtension().lastPathComponent
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
}

// MARK: - Stream Handlers

class PlayingStreamHandler: NSObject, FlutterStreamHandler {
    weak var plugin: IOSAudioPlayerPlugin?

    init(plugin: IOSAudioPlayerPlugin) {
        self.plugin = plugin
    }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        plugin?.eventSink = events
        if let playing = plugin?.isPlaying {
            events(playing)
        }
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        plugin?.eventSink = nil
        return nil
    }
}

class PositionStreamHandler: NSObject, FlutterStreamHandler {
    weak var plugin: IOSAudioPlayerPlugin?

    init(plugin: IOSAudioPlayerPlugin) {
        self.plugin = plugin
    }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        plugin?.positionEventSink = events
        if let position = plugin?.getCurrentPositionMs() {
            events(position)
        }
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        plugin?.positionEventSink = nil
        return nil
    }
}

class DurationStreamHandler: NSObject, FlutterStreamHandler {
    weak var plugin: IOSAudioPlayerPlugin?

    init(plugin: IOSAudioPlayerPlugin) {
        self.plugin = plugin
    }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        plugin?.durationEventSink = events
        if let duration = plugin?.getCurrentDurationMs() {
            events(duration)
        }
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        plugin?.durationEventSink = nil
        return nil
    }
}

class IndexStreamHandler: NSObject, FlutterStreamHandler {
    weak var plugin: IOSAudioPlayerPlugin?

    init(plugin: IOSAudioPlayerPlugin) {
        self.plugin = plugin
    }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        plugin?.indexEventSink = events
        if let index = plugin?.currentIndex {
            events(index)
        }
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        plugin?.indexEventSink = nil
        return nil
    }
}



// /* import Flutter
// import UIKit
// import AVFoundation
// import MediaPlayer
//
// public class IOSAudioPlayerPlugin: NSObject, FlutterPlugin {
//     private var audioEngine: AVAudioEngine?
//     private var playerNode: AVAudioPlayerNode?
//     private var equalizer: AVAudioUnitEQ?
//     private var timePitch: AVAudioUnitTimePitch?
//     private var audioFiles: [AVAudioFile] = []
//     internal var currentIndex: Int = 0
//     internal var isPlaying: Bool = false
//     private var loopMode: String = "off"
//     private var isShuffleEnabled: Bool = false
//     private var playbackSpeed: Float = 1.0
//
//     // Position tracking
//     private var timer: Timer?
//     private var positionInSamples: AVAudioFramePosition = 0
//     private var seekPosition: AVAudioFramePosition = 0
//     private var isSeeking: Bool = false
//     private var lastNotifiedPosition: Int = -1
//
//     // Event sinks
//     var eventSink: FlutterEventSink?
//     var positionEventSink: FlutterEventSink?
//     var durationEventSink: FlutterEventSink?
//
//     // Equalizer
//     private let frequencies: [Float] = [60, 230, 910, 3600, 14000]
//     private let numberOfBands = 5
//     private var isEqualizerEnabled: Bool = false
//
//     // MARK: - Plugin Registration
//
//     public static func register(with registrar: FlutterPluginRegistrar) {
//         let channel = FlutterMethodChannel(
//             name: "com.example.music_app.ios_audio_player",
//             binaryMessenger: registrar.messenger()
//         )
//         let instance = IOSAudioPlayerPlugin()
//         registrar.addMethodCallDelegate(instance, channel: channel)
//         instance.setupEventChannels(registrar: registrar)
//     }
//
//     private func setupEventChannels(registrar: FlutterPluginRegistrar) {
//         FlutterEventChannel(
//             name: "com.example.music_app.ios_audio_player/playing_stream",
//             binaryMessenger: registrar.messenger()
//         ).setStreamHandler(PlayingStreamHandler(plugin: self))
//
//         FlutterEventChannel(
//             name: "com.example.music_app.ios_audio_player/position_stream",
//             binaryMessenger: registrar.messenger()
//         ).setStreamHandler(PositionStreamHandler(plugin: self))
//
//         FlutterEventChannel(
//             name: "com.example.music_app.ios_audio_player/duration_stream",
//             binaryMessenger: registrar.messenger()
//         ).setStreamHandler(DurationStreamHandler(plugin: self))
//     }
//
//     // MARK: - Method Handler
//
//     public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
//         switch call.method {
//         case "initialize":
//             initializePlayer(result: result)
//
//         case "setPlaylist":
//             guard let args = call.arguments as? [String: Any],
//                   let filePaths = args["filePaths"] as? [String] else {
//                 result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
//                 return
//             }
//             let startIndex = args["startIndex"] as? Int ?? 0
//             let autoPlay = args["autoPlay"] as? Bool ?? true
//             setPlaylist(filePaths: filePaths, startIndex: startIndex, autoPlay: autoPlay, result: result)
//
//         case "play":
//             play(result: result)
//
//         case "pause":
//             pause(result: result)
//
//         case "stop":
//             stop(result: result)
//
//         case "seekToNext":
//             seekToNext(result: result)
//
//         case "seekToPrevious":
//             seekToPrevious(result: result)
//
//         case "seek":
//             guard let args = call.arguments as? [String: Any],
//                   let positionMs = args["position"] as? Int else {
//                 result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
//                 return
//             }
//             let index = args["index"] as? Int
//             seek(positionMs: positionMs, index: index, result: result)
//
//         case "setSpeed":
//             guard let args = call.arguments as? [String: Any],
//                   let speed = args["speed"] as? Double else {
//                 result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
//                 return
//             }
//             setSpeed(speed: Float(speed), result: result)
//
//         case "setLoopMode":
//             guard let args = call.arguments as? [String: Any],
//                   let mode = args["mode"] as? String else {
//                 result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
//                 return
//             }
//             setLoopMode(mode: mode, result: result)
//
//         case "setShuffleEnabled":
//             guard let args = call.arguments as? [String: Any],
//                   let enabled = args["enabled"] as? Bool else {
//                 result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
//                 return
//             }
//             setShuffleEnabled(enabled: enabled, result: result)
//
//         case "getCurrentIndex":
//             result(currentIndex)
//
//         case "isPlaying":
//             result(isPlaying)
//
//         case "getPosition":
//             result(getCurrentPositionMs())
//
//         case "getDuration":
//             result(getCurrentDurationMs())
//
//         // Equalizer methods
//         case "eq_setEnabled":
//             guard let args = call.arguments as? [String: Any],
//                   let enabled = args["enabled"] as? Bool else {
//                 result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
//                 return
//             }
//             setEqualizerEnabled(enabled: enabled, result: result)
//
//         case "eq_setBandLevel":
//             guard let args = call.arguments as? [String: Any],
//                   let bandIndex = args["bandIndex"] as? Int,
//                   let gain = args["gain"] as? Double else {
//                 result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
//                 return
//             }
//             setEqualizerBandLevel(bandIndex: bandIndex, gain: Float(gain), result: result)
//
//         case "eq_getBandLevels":
//             getEqualizerBandLevels(result: result)
//
//         case "eq_getFrequencies":
//             result(frequencies.map { Double($0) })
//
//         case "eq_setBassBoost":
//             guard let args = call.arguments as? [String: Any],
//                   let strength = args["strength"] as? Double else {
//                 result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
//                 return
//             }
//             setBassBoost(strength: Float(strength), result: result)
//
//         default:
//             result(FlutterMethodNotImplemented)
//         }
//     }
//
//     // MARK: - Player Initialization
//
//     private func initializePlayer(result: @escaping FlutterResult) {
//         do {
//             let session = AVAudioSession.sharedInstance()
//             try session.setCategory(.playback, mode: .default, options: [])
//             try session.setActive(true)
//
//             audioEngine = AVAudioEngine()
//             playerNode = AVAudioPlayerNode()
//             equalizer = AVAudioUnitEQ(numberOfBands: numberOfBands)
//             timePitch = AVAudioUnitTimePitch()
//
//             guard let engine = audioEngine,
//                   let node = playerNode,
//                   let eq = equalizer,
//                   let pitch = timePitch else {
//                 result(FlutterError(code: "INIT_FAILED", message: "Failed to create audio components", details: nil))
//                 return
//             }
//
//             engine.attach(node)
//             engine.attach(eq)
//             engine.attach(pitch)
//
//             // Configure equalizer bands
//             for i in 0..<numberOfBands {
//                 let band = eq.bands[i]
//                 band.frequency = frequencies[i]
//                 band.gain = 0.0
//                 band.bypass = false
//                 band.filterType = .parametric
//                 band.bandwidth = 0.5
//             }
//
//             // Start with EQ bypassed
//             eq.bypass = true
//
//             // Connect: player -> EQ -> timePitch -> mixer
//             let mixer = engine.mainMixerNode
//             let format = node.outputFormat(forBus: 0)
//
//             engine.connect(node, to: eq, format: format)
//             engine.connect(eq, to: pitch, format: format)
//             engine.connect(pitch, to: mixer, format: format)
//
//             engine.prepare()
//             try engine.start()
//
//             setupRemoteTransportControls()
//
//             print("✅ iOS Audio Player initialized")
//             result(true)
//
//         } catch {
//             print("❌ Init error: \(error)")
//             result(FlutterError(code: "INIT_ERROR", message: error.localizedDescription, details: nil))
//         }
//     }
//
//     // MARK: - Playlist Management
//
//     private func setPlaylist(filePaths: [String], startIndex: Int, autoPlay: Bool, result: @escaping FlutterResult) {
//         audioFiles.removeAll()
//
//         do {
//             for path in filePaths {
//                 let file = try AVAudioFile(forReading: URL(fileURLWithPath: path))
//                 audioFiles.append(file)
//             }
//
//             currentIndex = max(0, min(startIndex, audioFiles.count - 1))
//
//             if !audioFiles.isEmpty {
//                 scheduleCurrentFile()
//
//                 if autoPlay {
//                     play(result: result)
//                 } else {
//                     result(true)
//                 }
//             } else {
//                 result(true)
//             }
//
//         } catch {
//             print("❌ Playlist error: \(error)")
//             result(FlutterError(code: "PLAYLIST_ERROR", message: error.localizedDescription, details: nil))
//         }
//     }
//
//     private func scheduleCurrentFile() {
//         guard let node = playerNode,
//               currentIndex >= 0 && currentIndex < audioFiles.count else {
//             return
//         }
//
//         let file = audioFiles[currentIndex]
//         safeStopPlayerNode()
//
//         positionInSamples = 0
//         seekPosition = 0
//         lastNotifiedPosition = -1
//
//         node.scheduleFile(file, at: nil) { [weak self] in
//             DispatchQueue.main.async {
//                 self?.handlePlaybackCompleted()
//             }
//         }
//
//         notifyPositionChanged()
//         notifyDurationChanged()
//
//         print("📀 Scheduled: \(file.url.lastPathComponent)")
//     }
//
//     private func safeStopPlayerNode() {
//         guard let engine = audioEngine, let node = playerNode else { return }
//
//         if !engine.isRunning {
//             try? engine.start()
//         }
//
//         if node.isPlaying {
//             node.stop()
//         }
//     }
//
//     // MARK: - Playback Control
//
//     private func play(result: @escaping FlutterResult) {
//         guard let node = playerNode, let engine = audioEngine else {
//             result(FlutterError(code: "NOT_INITIALIZED", message: "Player not initialized", details: nil))
//             return
//         }
//
//         do {
//             if !engine.isRunning {
//                 try engine.start()
//             }
//
//             if !isPlaying {
//                 node.play()
//                 isPlaying = true
//                 startPositionTimer()
//                 notifyPlayingStateChanged()
//                 updateNowPlayingInfo()
//             }
//
//             result(true)
//         } catch {
//             print("❌ Play error: \(error)")
//             result(FlutterError(code: "PLAY_ERROR", message: error.localizedDescription, details: nil))
//         }
//     }
//
//     private func pause(result: @escaping FlutterResult) {
//         guard let node = playerNode else {
//             result(FlutterError(code: "NOT_INITIALIZED", message: "Player not initialized", details: nil))
//             return
//         }
//
//         if isPlaying {
//             node.pause()
//             isPlaying = false
//             stopPositionTimer()
//             notifyPlayingStateChanged()
//             updateNowPlayingInfo()
//         }
//
//         result(true)
//     }
//
//     private func stop(result: @escaping FlutterResult) {
//         safeStopPlayerNode()
//         isPlaying = false
//         positionInSamples = 0
//         seekPosition = 0
//         lastNotifiedPosition = -1
//         stopPositionTimer()
//         notifyPlayingStateChanged()
//         notifyPositionChanged()
//         result(true)
//     }
//
//     private func seek(positionMs: Int, index: Int?, result: @escaping FlutterResult) {
//         guard let node = playerNode else {
//             result(FlutterError(code: "NOT_INITIALIZED", message: "Player not initialized", details: nil))
//             return
//         }
//
//         let wasPlaying = isPlaying
//         isSeeking = true
//
//         stopPositionTimer()
//         safeStopPlayerNode()
//
//         // Track change
//         if let newIndex = index, newIndex != currentIndex {
//             currentIndex = max(0, min(newIndex, audioFiles.count - 1))
//
//             guard currentIndex >= 0 && currentIndex < audioFiles.count else {
//                 isSeeking = false
//                 result(false)
//                 return
//             }
//
//             let file = audioFiles[currentIndex]
//             let sampleRate = file.processingFormat.sampleRate
//             let targetFrame = AVAudioFramePosition(Double(positionMs) / 1000.0 * sampleRate)
//             let clampedFrame = max(0, min(targetFrame, file.length))
//
//             positionInSamples = clampedFrame
//             seekPosition = clampedFrame
//             lastNotifiedPosition = -1
//
//             if clampedFrame < file.length {
//                 let frameCount = AVAudioFrameCount(file.length - clampedFrame)
//                 node.scheduleSegment(file, startingFrame: clampedFrame, frameCount: frameCount, at: nil) { [weak self] in
//                     DispatchQueue.main.async {
//                         self?.handlePlaybackCompleted()
//                     }
//                 }
//             }
//
//             positionEventSink?(positionMs)
//
//             if wasPlaying {
//                 node.play()
//                 isPlaying = true
//                 startPositionTimer()
//                 notifyPlayingStateChanged()
//             }
//
//             notifyDurationChanged()
//             updateNowPlayingInfo()
//
//             DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
//                 self?.isSeeking = false
//             }
//
//             result(true)
//             return
//         }
//
//         // Seek within track
//         guard currentIndex >= 0 && currentIndex < audioFiles.count else {
//             isSeeking = false
//             result(false)
//             return
//         }
//
//         let file = audioFiles[currentIndex]
//         let sampleRate = file.processingFormat.sampleRate
//         let targetFrame = AVAudioFramePosition(Double(positionMs) / 1000.0 * sampleRate)
//         let clampedFrame = max(0, min(targetFrame, file.length))
//
//         positionInSamples = clampedFrame
//         seekPosition = clampedFrame
//         lastNotifiedPosition = -1
//
//         if clampedFrame < file.length {
//             let frameCount = AVAudioFrameCount(file.length - clampedFrame)
//             node.scheduleSegment(file, startingFrame: clampedFrame, frameCount: frameCount, at: nil) { [weak self] in
//                 DispatchQueue.main.async {
//                     self?.handlePlaybackCompleted()
//                 }
//             }
//         }
//
//         positionEventSink?(positionMs)
//
//         if wasPlaying {
//             node.play()
//             isPlaying = true
//             startPositionTimer()
//             notifyPlayingStateChanged()
//         }
//
//         updateNowPlayingInfo()
//
//         DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
//             self?.isSeeking = false
//         }
//
//         result(true)
//     }
//
//     private func seekToNext(result: @escaping FlutterResult) {
//         guard !audioFiles.isEmpty else {
//             result(false)
//             return
//         }
//
//         let wasPlaying = isPlaying
//         safeStopPlayerNode()
//         stopPositionTimer()
//
//         currentIndex = (currentIndex + 1) % audioFiles.count
//         positionInSamples = 0
//         seekPosition = 0
//         lastNotifiedPosition = -1
//
//         scheduleCurrentFile()
//         positionEventSink?(0)
//
//         if wasPlaying {
//             play(result: { _ in })
//         }
//
//         result(true)
//     }
//
//     private func seekToPrevious(result: @escaping FlutterResult) {
//         guard !audioFiles.isEmpty else {
//             result(false)
//             return
//         }
//
//         let wasPlaying = isPlaying
//         safeStopPlayerNode()
//         stopPositionTimer()
//
//         currentIndex = currentIndex > 0 ? currentIndex - 1 : audioFiles.count - 1
//         positionInSamples = 0
//         seekPosition = 0
//         lastNotifiedPosition = -1
//
//         scheduleCurrentFile()
//         positionEventSink?(0)
//
//         if wasPlaying {
//             play(result: { _ in })
//         }
//
//         result(true)
//     }
//
//     // MARK: - Playback Settings
//
//     private func setSpeed(speed: Float, result: @escaping FlutterResult) {
//         guard let pitch = timePitch else {
//             result(false)
//             return
//         }
//
//         playbackSpeed = max(0.25, min(speed, 2.0))
//         pitch.rate = playbackSpeed
//         updateNowPlayingInfo()
//
//         result(true)
//     }
//
//     private func setLoopMode(mode: String, result: @escaping FlutterResult) {
//         loopMode = mode
//         result(true)
//     }
//
//     private func setShuffleEnabled(enabled: Bool, result: @escaping FlutterResult) {
//         isShuffleEnabled = enabled
//         result(true)
//     }
//
//     // MARK: - Position Tracking
//
//     private func startPositionTimer() {
//         stopPositionTimer()
//         timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
//             guard let self = self, !self.isSeeking else { return }
//             self.updatePosition()
//         }
//     }
//
//     private func stopPositionTimer() {
//         timer?.invalidate()
//         timer = nil
//     }
//
//     private func updatePosition() {
//         guard let node = playerNode,
//               let nodeTime = node.lastRenderTime,
//               let playerTime = node.playerTime(forNodeTime: nodeTime),
//               currentIndex >= 0 && currentIndex < audioFiles.count else {
//             return
//         }
//
//         let file = audioFiles[currentIndex]
//         positionInSamples = min(seekPosition + playerTime.sampleTime, file.length)
//
//         let currentPosMs = getCurrentPositionMs()
//
//         // Only notify if position changed significantly (avoid spam)
//         if abs(currentPosMs - lastNotifiedPosition) > 100 {
//             lastNotifiedPosition = currentPosMs
//             notifyPositionChanged()
//         }
//     }
//
//     internal func getCurrentPositionMs() -> Int {
//         guard currentIndex >= 0 && currentIndex < audioFiles.count else {
//             return 0
//         }
//
//         let file = audioFiles[currentIndex]
//         let sampleRate = file.processingFormat.sampleRate
//         return Int((Double(positionInSamples) / sampleRate) * 1000)
//     }
//
//     internal func getCurrentDurationMs() -> Int {
//         guard currentIndex >= 0 && currentIndex < audioFiles.count else {
//             return 0
//         }
//
//         let file = audioFiles[currentIndex]
//         let sampleRate = file.processingFormat.sampleRate
//         return Int((Double(file.length) / sampleRate) * 1000)
//     }
//
//     // MARK: - Playback Completion
//
//     private func handlePlaybackCompleted() {
//         guard !isSeeking else { return }
//
//         switch loopMode {
//         case "one":
//             scheduleCurrentFile()
//             if let node = playerNode {
//                 node.play()
//                 isPlaying = true
//                 startPositionTimer()
//                 notifyPlayingStateChanged()
//                 updateNowPlayingInfo()
//             }
//
//         case "all":
//             currentIndex = (currentIndex + 1) % audioFiles.count
//             scheduleCurrentFile()
//             if let node = playerNode {
//                 node.play()
//                 isPlaying = true
//                 startPositionTimer()
//                 notifyPlayingStateChanged()
//                 updateNowPlayingInfo()
//             }
//
//         default:
//             if currentIndex < audioFiles.count - 1 {
//                 currentIndex += 1
//                 scheduleCurrentFile()
//                 if let node = playerNode {
//                     node.play()
//                     isPlaying = true
//                     startPositionTimer()
//                     notifyPlayingStateChanged()
//                     updateNowPlayingInfo()
//                 }
//             } else {
//                 isPlaying = false
//                 stopPositionTimer()
//                 notifyPlayingStateChanged()
//             }
//         }
//     }
//
//     // MARK: - Equalizer Methods
//
//     private func setEqualizerEnabled(enabled: Bool, result: @escaping FlutterResult) {
//         guard let eq = equalizer else {
//             result(false)
//             return
//         }
//
//         isEqualizerEnabled = enabled
//         eq.bypass = !enabled
//
//         print("🎚 Equalizer: \(enabled ? "ON" : "OFF")")
//         result(true)
//     }
//
//     private func setEqualizerBandLevel(bandIndex: Int, gain: Float, result: @escaping FlutterResult) {
//         guard let eq = equalizer,
//               bandIndex >= 0 && bandIndex < numberOfBands else {
//             result(FlutterError(code: "INVALID_BAND", message: "Invalid band index", details: nil))
//             return
//         }
//
//         let clampedGain = max(-15.0, min(15.0, gain))
//         eq.bands[bandIndex].gain = clampedGain
//
//         print("🎚 Band \(bandIndex) (\(Int(frequencies[bandIndex]))Hz): \(clampedGain)dB")
//         result(true)
//     }
//
//     private func getEqualizerBandLevels(result: @escaping FlutterResult) {
//         guard let eq = equalizer else {
//             result([])
//             return
//         }
//
//         let levels = eq.bands.map { Double($0.gain) }
//         result(levels)
//     }
//
//     private func setBassBoost(strength: Float, result: @escaping FlutterResult) {
//         guard let eq = equalizer else {
//             result(false)
//             return
//         }
//
//         let clampedStrength = max(0, min(strength, 1.0))
//         let bassGain = clampedStrength * 10.0
//
//         if numberOfBands >= 2 {
//             eq.bands[0].gain = bassGain        // 60Hz
//             eq.bands[1].gain = bassGain * 0.7  // 230Hz
//         }
//
//         print("🔊 Bass boost: \(clampedStrength)")
//         result(true)
//     }
//
//     // MARK: - Event Notifications
//
//     private func notifyPlayingStateChanged() {
//         eventSink?(isPlaying)
//     }
//
//     private func notifyPositionChanged() {
//         positionEventSink?(getCurrentPositionMs())
//     }
//
//     private func notifyDurationChanged() {
//         durationEventSink?(getCurrentDurationMs())
//     }
//
//     // MARK: - Now Playing & Remote Control
//
//     private func setupRemoteTransportControls() {
//         let commandCenter = MPRemoteCommandCenter.shared()
//
//         commandCenter.playCommand.addTarget { [weak self] _ in
//             self?.play(result: { _ in })
//             return .success
//         }
//
//         commandCenter.pauseCommand.addTarget { [weak self] _ in
//             self?.pause(result: { _ in })
//             return .success
//         }
//
//         commandCenter.nextTrackCommand.addTarget { [weak self] _ in
//             self?.seekToNext(result: { _ in })
//             return .success
//         }
//
//         commandCenter.previousTrackCommand.addTarget { [weak self] _ in
//             self?.seekToPrevious(result: { _ in })
//             return .success
//         }
//
//         commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
//             guard let self = self,
//                   let positionEvent = event as? MPChangePlaybackPositionCommandEvent else {
//                 return .commandFailed
//             }
//
//             let positionMs = Int(positionEvent.positionTime * 1000)
//             self.seek(positionMs: positionMs, index: nil, result: { _ in })
//             return .success
//         }
//     }
//
//     private func updateNowPlayingInfo() {
//         var info = [String: Any]()
//
//         info[MPMediaItemPropertyPlaybackDuration] = Double(getCurrentDurationMs()) / 1000.0
//         info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = Double(getCurrentPositionMs()) / 1000.0
//         info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? Double(playbackSpeed) : 0.0
//
//         if currentIndex >= 0 && currentIndex < audioFiles.count {
//             let file = audioFiles[currentIndex]
//             info[MPMediaItemPropertyTitle] = file.url.deletingPathExtension().lastPathComponent
//         }
//
//         MPNowPlayingInfoCenter.default().nowPlayingInfo = info
//     }
// }
//
// // MARK: - Stream Handlers
//
// class PlayingStreamHandler: NSObject, FlutterStreamHandler {
//     weak var plugin: IOSAudioPlayerPlugin?
//
//     init(plugin: IOSAudioPlayerPlugin) {
//         self.plugin = plugin
//     }
//
//     func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
//         plugin?.eventSink = events
//         // Send initial state
//         if let playing = plugin?.isPlaying {
//             events(playing)
//         }
//         return nil
//     }
//
//     func onCancel(withArguments arguments: Any?) -> FlutterError? {
//         plugin?.eventSink = nil
//         return nil
//     }
// }
//
// class PositionStreamHandler: NSObject, FlutterStreamHandler {
//     weak var plugin: IOSAudioPlayerPlugin?
//
//     init(plugin: IOSAudioPlayerPlugin) {
//         self.plugin = plugin
//     }
//
//     func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
//         plugin?.positionEventSink = events
//         // Send initial position
//         if let position = plugin?.getCurrentPositionMs() {
//             events(position)
//         }
//         return nil
//     }
//
//     func onCancel(withArguments arguments: Any?) -> FlutterError? {
//         plugin?.positionEventSink = nil
//         return nil
//     }
// }
//
// class DurationStreamHandler: NSObject, FlutterStreamHandler {
//     weak var plugin: IOSAudioPlayerPlugin?
//
//     init(plugin: IOSAudioPlayerPlugin) {
//         self.plugin = plugin
//     }
//
//     func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
//         plugin?.durationEventSink = events
//         // Send initial duration
//         if let duration = plugin?.getCurrentDurationMs() {
//             events(duration)
//         }
//         return nil
//     }
//
//     func onCancel(withArguments arguments: Any?) -> FlutterError? {
//         plugin?.durationEventSink = nil
//         return nil
//     }
// } *//*  *//*  *//*  *//*  *//*  *//*  *//*  *//*  *//*  *//*  *//*  *//*  *//*  *//*  *//*  */ */

// MARK: - Helper Extension
/*
extension IOSAudioPlayerPlugin {
    func getCurrentPositionMs() -> Int {
        guard currentIndex >= 0 && currentIndex < audioFiles.count else {
            return 0
        }

        let file = audioFiles[currentIndex]
        let sampleRate = file.processingFormat.sampleRate
        return Int((Double(positionInSamples) / sampleRate) * 1000)
    }

    func getCurrentDurationMs() -> Int {
        guard currentIndex >= 0 && currentIndex < audioFiles.count else {
            return 0
        }

        let file = audioFiles[currentIndex]
        let sampleRate = file.processingFormat.sampleRate
        return Int((Double(file.length) / sampleRate) * 1000)
    }
} */
