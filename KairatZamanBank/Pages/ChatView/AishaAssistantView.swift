import SwiftUI
import Combine
import Speech
import AVFoundation

// MARK: - Keyboard helper
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
                    let end = (info[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)
                else { return }
                self?.height = end.minY >= UIScreen.main.bounds.height ? 0 : end.height
            }
            .store(in: &cancellables)
    }
}

// MARK: - Speech recognizer (idempotent)
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
            guard status == .authorized else { DispatchQueue.main.async { completion(false) }; return }
            AVAudioApplication.requestRecordPermission { micOK in
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
            if recognizer?.supportsOnDeviceRecognition == true { req.requiresOnDeviceRecognition = true }
            request = req
            
            isRunning = true
            isStopping = false
            
            task = recognizer?.recognitionTask(with: req) { [weak self] result, error in
                guard let self else { return }
                if let r = result {
                    self.transcript = r.bestTranscription.formattedString
                }
                if error != nil || (result?.isFinal ?? false) { self.cleanupSession() }
            }
            
            let input = audioEngine.inputNode
            let format = input.outputFormat(forBus: 0)
            input.removeTap(onBus: 0)
            input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buf, _ in
                guard let self else { return }
                self.request?.append(buf)
                guard let ch = buf.floatChannelData?[0] else { return }
                let n = Int(buf.frameLength)
                let rms = sqrt((0..<n).reduce(0) { $0 + Double(ch[$1] * ch[$1]) } / Double(max(n,1)))
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

// MARK: - Screen
struct AishaAssistantView: View {
    @State private var message = ""
    @FocusState private var typing: Bool
    @StateObject private var kb = KeyboardObserver()
    
    @State private var showIntro = true
    @State private var thread: [ChatMessage] = []
    
    // voice
    @State private var showRecorder = false
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
            
            if !showRecorder {
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
                                        .onTapGesture { sendLocal(s) } // now adds to thread
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
                }
                .safeAreaInset(edge: .bottom) {
                    ChatInputBar(
                        text: $message,
                        typing: $typing,
                        sendAction: { txt in
                            let t = txt.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !t.isEmpty else { return }
                            sendLocal(t) // typed messages now go to thread
                            message = ""
                        },
                        voiceAction: { startVoice() }
                    )
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .padding(.bottom, kb.height > 0 ? max(kb.height - 8, 0) : 100)
                }
            } else {
                VoiceOverlay(
                    level: $speech.level,
                    stop: { stopVoice(sendText: true) },
                    cancel: { stopSession() }
                )
                .transition(.opacity)
                .onAppear { speech.start() }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { typing = false }
            }
        }
    }
    
    // MARK: - Local send with echo
    private func sendLocal(_ text: String) {
        showIntro = false
        withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
            thread.append(.init(role: .user, text: text))
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                thread.append(.init(role: .assistant, text: text))
            }
        }
    }
    
    // MARK: - Voice actions (unchanged behavior)
    private func startVoice() {
        typing = false
        withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) { showRecorder = true }
    }
    private func stopVoice(sendText: Bool) {
        speech.stop()
        let text = speech.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) { showRecorder = false }
        guard sendText, !text.isEmpty else { return }
        sendLocal(text) // voice result also enters the thread locally
    }
    private func stopSession() {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) { showRecorder = false }
    }
}
