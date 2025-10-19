// AishaAssistantView.swift
import SwiftUI
import AVKit
import AVFoundation
import Speech
import Combine

final class KeyboardObserver: ObservableObject {
    @Published var height: CGFloat = 0
    private var cancellables = Set<AnyCancellable>()

    init() {
        let nc = NotificationCenter.default
        nc.publisher(for: UIResponder.keyboardWillChangeFrameNotification)
            .merge(with: nc.publisher(for: UIResponder.keyboardWillHideNotification))
            .sink { [weak self] note in
                guard
                    let info = note.userInfo,
                    let end = info[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
                else { return }
                self?.height = end.minY >= UIScreen.main.bounds.height ? 0 : end.height
            }
            .store(in: &cancellables)
    }
}

@MainActor
final class VoiceAudioPlayer: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var isPlaying = false
    private var player: AVAudioPlayer?
    private var tempFileURL: URL?

    func playAudioData(_ data: Data, contentType: String?) throws {
        let ext: String = {
            guard let ct = contentType?.lowercased() else { return "m4a" }
            if ct.contains("aac") { return "aac" }
            if ct.contains("mp4") || ct.contains("m4a") { return "m4a" }
            return "m4a"
        }()

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("aisha_reply_\(UUID().uuidString).\(ext)")

        try data.write(to: url, options: .atomic)

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        tempFileURL = url
        player = try AVAudioPlayer(contentsOf: url)
        player?.delegate = self
        player?.prepareToPlay()
        player?.play()
        isPlaying = true
    }

    // Allow manual cancel from overlay
    func stopPlayback() {
        player?.stop()
        isPlaying = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        if let u = tempFileURL { try? FileManager.default.removeItem(at: u) }
        tempFileURL = nil
        player = nil
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        if let u = tempFileURL { try? FileManager.default.removeItem(at: u) }
        tempFileURL = nil
        self.player = nil
    }
}



struct AishaAssistantView: View {
    @EnvironmentObject private var net: NetworkingService

    @State private var isThinking = false
    @State private var message = ""
    @FocusState private var typing: Bool
    @StateObject private var kb = KeyboardObserver()
    @StateObject private var audio = VoiceAudioPlayer()
    @State private var showIntro = true
    @State private var thread: [ChatMessage] = []

    // voice
    @State private var showRecorder = false
    @State private var overlayPhase: VoiceOverlayPhase = .listening
    @StateObject private var speech = SpeechRecognizer()

    let suggestions = [
        "Give me my monthly report",
        "Show my zakat amount",
        "How can I effectively spend my money?",
        "I should pay my mahr this year. Give me a plan"
    ]

    var body: some View {
        ZStack {
            ZamanGradientView().ignoresSafeArea()

            VStack(spacing: 0) {
                if showIntro {
                    VStack(spacing: 24) {
                        Text("Aisha Assistant").font(.title).fontWeight(.semibold)
                        if let ui = UIImage(named: "AishaHappy") {
                            Image(uiImage: ui).resizable().scaledToFit().frame(width: 140, height: 140)
                        } else { Text("🧕").font(.system(size: 120)) }
                        Text("Your Financial AI Assistant. Speak or type to interact.")
                            .font(.subheadline).foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        VStack(spacing: 12) {
                            ForEach(suggestions, id: \.self) { s in
                                Text(s)
                                    .font(.callout).fontWeight(.semibold)
                                    .padding(.horizontal, 18).padding(.vertical, 10)
                                    .background(Capsule().fill(Color(red: 0.93, green: 0.98, blue: 0.42)))
                                    .foregroundStyle(.black)
                                    .contentShape(Capsule())
                                    .onTapGesture { sendLocal(s) }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 24)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                ChatList(messages: thread)
                    .frame(maxWidth: .infinity,
                           maxHeight: showIntro ? 0 : .infinity,
                           alignment: .top)
                    .clipped()
                    .animation(.spring(response: 0.3, dampingFraction: 0.9), value: showIntro)

                if isThinking && !showIntro {
                    TypingBubble()
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.spring(response: 0.25, dampingFraction: 0.9), value: isThinking)
                }
            }
            .safeAreaInset(edge: .bottom) {
                ChatInputBar(
                    text: $message,
                    typing: $typing,
                    sendAction: { txt in
                        let t = txt.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !t.isEmpty else { return }
                        sendLocal(t)
                        message = ""
                    },
                    voiceAction: { startVoice() }
                )
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .padding(.bottom, kb.height > 0 ? max(kb.height - 8, 0) : 100)
            }

            if showRecorder {
                VoiceOverlay(
                    level: $speech.level,
                    phase: $overlayPhase,
                    stop: { stopVoice(sendText: true) },
                    cancel: { stopSession() }
                )
                .transition(.opacity)
                .onAppear { speech.start() }
            }
        }
        .onChange(of: audio.isPlaying) { playing in
            if playing {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                    overlayPhase = .speaking
                    showRecorder = true
                }
            } else if showRecorder && overlayPhase == .speaking {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                    showRecorder = false
                    overlayPhase = .listening
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { typing = false }
            }
        }
    }

    // MARK: - Local send + network
    @MainActor
    private func sendLocal(_ text: String) {
        showIntro = false
        withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
            thread.append(.init(role: .user, text: text))
        }
        sendRemote(text)
    }

    @MainActor
    private func sendRemote(_ text: String) {
        if isThinking { return }
        isThinking = true
        Task {
            defer { isThinking = false }
            do {
                let botReply = try await net.sendChat(text: text)
                withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                    thread.append(.init(role: .assistant, text: botReply.isEmpty ? "…" : botReply))
                }
            } catch {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                    thread.append(.init(role: .assistant,
                        text: "Sorry, I couldn’t reach the server.\n\(error.localizedDescription)"))
                }
            }
        }
    }

    // MARK: - Voice actions
    private func startVoice() {
        typing = false
        overlayPhase = .listening
        withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) { showRecorder = true }
    }

    private func stopVoice(sendText: Bool) {
        speech.stop()
        let text = speech.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
            overlayPhase = .waiting
            showRecorder = true
        }
        guard sendText, !text.isEmpty else { return }
        sendVoice(text)
    }

    @MainActor
    private func sendVoice(_ text: String) {
        showIntro = false
        withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
            thread.append(.init(role: .user, text: text))
        }
        sendRemoteVoice(text)
    }

    @MainActor
    private func sendRemoteVoice(_ text: String) {
        if isThinking { return }
        isThinking = true
        Task {
            defer { isThinking = false }
            do {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                    overlayPhase = .waiting
                    showRecorder = true
                }
                let (data, ct) = try await net.analyzeSpeech(text: text)
                try audio.playAudioData(data, contentType: ct)
                withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                    thread.append(.init(role: .assistant, text: "🔊 Playing voice reply…"))
                }
            } catch {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                    thread.append(.init(role: .assistant,
                        text: "Sorry, I couldn’t play the voice reply.\n\(error.localizedDescription)"))
                }
                if showRecorder {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                        showRecorder = false
                        overlayPhase = .listening
                    }
                }
            }
        }
    }

    private func stopSession() {
        speech.stop()
        audio.stopPlayback()
        withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
            showRecorder = false
            overlayPhase = .listening
        }
    }
}

@MainActor
final class SpeechRecognizer: NSObject, ObservableObject {
    @Published var transcript: String = ""
    @Published var level: CGFloat = 0

    private let recognizer = SFSpeechRecognizer()
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    private var isRunning = false
    private var isStopping = false

    func start() {
        guard !isRunning else { return }
        requestPermissions { [weak self] ok in
            guard let self, ok else { return }
            self.startEngine()
        }
    }

    func stop() {
        guard isRunning, !isStopping else { return }
        isStopping = true
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        audioEngine.stop()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            self?.task?.cancel()
        }
    }

    private func requestPermissions(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            guard status == .authorized else {
                DispatchQueue.main.async { completion(false) }
                return
            }
            AVAudioSession.sharedInstance().requestRecordPermission { micOK in
                DispatchQueue.main.async { completion(micOK) }
            }
        }
    }

    private func startEngine() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: [.duckOthers])
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            let req = SFSpeechAudioBufferRecognitionRequest()
            req.shouldReportPartialResults = true
            if recognizer?.supportsOnDeviceRecognition == true {
                req.requiresOnDeviceRecognition = true
            }
            request = req

            isRunning = true
            isStopping = false

            task = recognizer?.recognitionTask(with: req) { [weak self] result, error in
                guard let self else { return }
                if let r = result {
                    self.transcript = r.bestTranscription.formattedString
                }
                if error != nil || (result?.isFinal ?? false) {
                    self.cleanupSession()
                }
            }

            let input = audioEngine.inputNode
            let format = input.outputFormat(forBus: 0)
            input.removeTap(onBus: 0)
            input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buf, _ in
                guard let self else { return }
                self.request?.append(buf)

                guard let ch = buf.floatChannelData?[0] else { return }
                let n = Int(buf.frameLength)
                let rms = sqrt((0..<n).reduce(0) { $0 + Double(ch[$1] * ch[$1]) } / Double(max(n, 1)))
                let db = 20 * log10(max(rms, 1e-6))
                let norm = min(max((db + 50) / 30, 0), 1)
                DispatchQueue.main.async { self.level = CGFloat(norm) }
            }

            audioEngine.prepare()
            try audioEngine.start()
        } catch {
            cleanupSession()
        }
    }

    private func cleanupSession() {
        audioEngine.inputNode.removeTap(onBus: 0)
        if audioEngine.isRunning { audioEngine.stop() }
        request = nil
        task = nil
        isRunning = false
        isStopping = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}

// MARK: - Typing bubble in chat
struct TypingBubble: View {
    @State private var t: Double = 0

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: "sparkles")
                .font(.headline.weight(.bold))

            Text("Aisha is thinking")
                .font(.callout)
                .fontWeight(.semibold)

            Spacer(minLength: 0)

            HStack(spacing: 6) {
                ForEach(0..<3) { i in
                    Circle()
                        .frame(width: 6, height: 6)
                        .opacity(dotOpacity(i))
                        .scaleEffect(dotScale(i))
                        .animation(
                            .easeInOut(duration: 0.9)
                                .repeatForever()
                                .delay(Double(i) * 0.15),
                            value: t
                        )
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.black.opacity(0.05), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
        .onAppear { t = 1 }
    }

    private func dotOpacity(_ i: Int) -> Double {
        0.3 + 0.7 * abs(sin((t + Double(i) * 0.35) * .pi))
    }

    private func dotScale(_ i: Int) -> CGFloat {
        0.8 + 0.2 * CGFloat(abs(sin((t + Double(i) * 0.35) * .pi)))
    }
}
