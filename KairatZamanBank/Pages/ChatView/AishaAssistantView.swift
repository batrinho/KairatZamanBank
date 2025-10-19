import SwiftUI
import Combine
import Speech
import AVFoundation

private let base = "https://zamanbank-api-production.up.railway.app"
private let bearer =
"""
eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJiZWtvbmFpIiwiaWF0IjoxNzYwODQ2MjI0LCJleHAiOjE3NjA5MzI2MjR9.H6p1z4pVyhGP2h6XKhmELsKlwQ5XmQeuams0DwAWhUk
"""

private struct ChatAPIResponse: Decodable {
    let response: String
    let message: String?
}

private struct TypingBubble: View {
    @State private var t: Double = 0

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: "sparkles")
                .font(.headline.weight(.bold))
            Text("Aisha is thinking")
                .font(.callout).fontWeight(.semibold)

            Spacer(minLength: 0)

            // three animated dots
            HStack(spacing: 6) {
                ForEach(0..<3) { i in
                    Circle()
                        .frame(width: 6, height: 6)
                        .opacity(dotOpacity(i))
                        .scaleEffect(dotScale(i))
                        .animation(.easeInOut(duration: 0.9).repeatForever().delay(Double(i) * 0.15), value: t)
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
        .onAppear { t = 1 } // kick off animations
    }

    private func dotOpacity(_ i: Int) -> Double {
        // subtle pulse: 0.3 -> 1 -> 0.3
        // animation driven by 't' state flipping to start
        return 0.3 + 0.7 * abs(sin((t + Double(i) * 0.35) * .pi))
    }

    private func dotScale(_ i: Int) -> CGFloat {
        0.8 + 0.2 * CGFloat(abs(sin((t + Double(i) * 0.35) * .pi)))
    }
}

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
    @State private var isThinking = false
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
    
    @MainActor
    private func sendRemote(_ text: String) {
        // prevent overlapping requests (optional, but helpful)
        if isThinking { return }
        isThinking = true

        Task {
            defer { isThinking = false } // always turn off

            do {
                var comps = URLComponents(string: "\(base)/chat-bot/chat")!
                comps.queryItems = [URLQueryItem(name: "text", value: text)]
                guard let url = comps.url else { return }

                var req = URLRequest(url: url)
                req.httpMethod = "POST"
                req.setValue("Bearer \(bearer)", forHTTPHeaderField: "Authorization")
                req.setValue("application/json", forHTTPHeaderField: "Accept")

                let (data, resp) = try await URLSession.shared.data(for: req)
                guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                    let code = (resp as? HTTPURLResponse)?.statusCode ?? -1
                    throw NSError(domain: "HTTPError", code: code)
                }

                let decoded = try JSONDecoder().decode(ChatAPIResponse.self, from: data)
                let botReply = decoded.response.trimmingCharacters(in: .whitespacesAndNewlines)

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

                        if isThinking && !showIntro {
                            TypingBubble() // ⬅️ new little bubble
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
    
    // MARK: - Local send + network
    private func sendLocal(_ text: String) {
        showIntro = false
        withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
            thread.append(.init(role: .user, text: text))
        }
        sendRemote(text) // ← hit your backend
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
