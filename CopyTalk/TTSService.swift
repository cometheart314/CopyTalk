import Foundation

/// 言語設定
enum SpeechLanguage: String {
    case japanese = "ja-JP"
    case english = "en-US"
}

/// TTS モデル
enum TTSModel: String {
    case neural2 = "neural2"
    case chirp3HD = "chirp3HD"

    var displayName: String {
        switch self {
        case .neural2: return "Neural2"
        case .chirp3HD: return "Chirp 3: HD"
        }
    }

    static let allCases: [TTSModel] = [.neural2, .chirp3HD]

    /// UserDefaults から現在のモデルを取得
    static var current: TTSModel {
        if let saved = UserDefaults.standard.string(forKey: "ttsModel"),
           let model = TTSModel(rawValue: saved) {
            return model
        }
        return .neural2
    }
}

/// 音声の種類
struct VoiceOption {
    let name: String        // API に送る名前 (例: "ja-JP-Neural2-B")
    let displayName: String // UI に表示する名前
    let language: SpeechLanguage
    let model: TTSModel

    static let allVoices: [VoiceOption] = [
        // Japanese - Neural2
        VoiceOption(name: "ja-JP-Neural2-B", displayName: "Neural2 B (Female)", language: .japanese, model: .neural2),
        VoiceOption(name: "ja-JP-Neural2-C", displayName: "Neural2 C (Male)",   language: .japanese, model: .neural2),
        VoiceOption(name: "ja-JP-Neural2-D", displayName: "Neural2 D (Male)",   language: .japanese, model: .neural2),
        // English - Neural2
        VoiceOption(name: "en-US-Neural2-C", displayName: "Neural2 C (Female)",  language: .english, model: .neural2),
        VoiceOption(name: "en-US-Neural2-D", displayName: "Neural2 D (Male)",    language: .english, model: .neural2),
        VoiceOption(name: "en-US-Neural2-F", displayName: "Neural2 F (Female)",  language: .english, model: .neural2),
        VoiceOption(name: "en-US-Neural2-J", displayName: "Neural2 J (Male)",    language: .english, model: .neural2),
        // Japanese - Chirp 3: HD
        VoiceOption(name: "ja-JP-Chirp3-HD-Aoede",  displayName: "Aoede (Female)",  language: .japanese, model: .chirp3HD),
        VoiceOption(name: "ja-JP-Chirp3-HD-Kore",   displayName: "Kore (Female)",   language: .japanese, model: .chirp3HD),
        VoiceOption(name: "ja-JP-Chirp3-HD-Leda",   displayName: "Leda (Female)",   language: .japanese, model: .chirp3HD),
        VoiceOption(name: "ja-JP-Chirp3-HD-Zephyr", displayName: "Zephyr (Female)", language: .japanese, model: .chirp3HD),
        VoiceOption(name: "ja-JP-Chirp3-HD-Puck",   displayName: "Puck (Male)",     language: .japanese, model: .chirp3HD),
        VoiceOption(name: "ja-JP-Chirp3-HD-Charon", displayName: "Charon (Male)",   language: .japanese, model: .chirp3HD),
        VoiceOption(name: "ja-JP-Chirp3-HD-Fenrir", displayName: "Fenrir (Male)",   language: .japanese, model: .chirp3HD),
        VoiceOption(name: "ja-JP-Chirp3-HD-Orus",   displayName: "Orus (Male)",     language: .japanese, model: .chirp3HD),
        // English - Chirp 3: HD
        VoiceOption(name: "en-US-Chirp3-HD-Aoede",  displayName: "Aoede (Female)",  language: .english, model: .chirp3HD),
        VoiceOption(name: "en-US-Chirp3-HD-Kore",   displayName: "Kore (Female)",   language: .english, model: .chirp3HD),
        VoiceOption(name: "en-US-Chirp3-HD-Leda",   displayName: "Leda (Female)",   language: .english, model: .chirp3HD),
        VoiceOption(name: "en-US-Chirp3-HD-Zephyr", displayName: "Zephyr (Female)", language: .english, model: .chirp3HD),
        VoiceOption(name: "en-US-Chirp3-HD-Puck",   displayName: "Puck (Male)",     language: .english, model: .chirp3HD),
        VoiceOption(name: "en-US-Chirp3-HD-Charon", displayName: "Charon (Male)",   language: .english, model: .chirp3HD),
        VoiceOption(name: "en-US-Chirp3-HD-Fenrir", displayName: "Fenrir (Male)",   language: .english, model: .chirp3HD),
        VoiceOption(name: "en-US-Chirp3-HD-Orus",   displayName: "Orus (Male)",     language: .english, model: .chirp3HD),
    ]

    /// 指定の言語・モデルに合う音声を返す
    static func voices(for language: SpeechLanguage, model: TTSModel) -> [VoiceOption] {
        allVoices.filter { $0.language == language && $0.model == model }
    }
}

class TTSService {

    private let session = URLSession.shared
    private let endpoint = "https://texttospeech.googleapis.com/v1/text:synthesize"

    /// テキストを音声合成して音声データ（Linear16 PCM）を返す
    func synthesize(text: String, language: SpeechLanguage) async throws -> Data {
        // MainActor で UserDefaults / KeychainHelper にアクセスする
        let (apiKey, rate, selectedVoice) = await MainActor.run {
            let key = KeychainHelper.getAPIKey()
            let speakingRate = UserDefaults.standard.double(forKey: "speakingRate")
            let r = speakingRate > 0 ? speakingRate : 1.0
            let v = self.voiceName(for: language)
            return (key, r, v)
        }

        guard let apiKey else {
            throw TTSError.noAPIKey
        }

        let voiceName = selectedVoice

        // Chirp 3: HD は中黒「・」で単語を繰り返すことがあるためスペースに置換
        let inputText: String
        if voiceName.contains("Chirp3-HD") {
            inputText = text.replacingOccurrences(of: "・", with: "")
        } else {
            inputText = text
        }

        let requestBody: [String: Any] = [
            "input": ["text": inputText],
            "voice": [
                "languageCode": language.rawValue,
                "name": voiceName
            ],
            "audioConfig": [
                "audioEncoding": "LINEAR16",
                "speakingRate": rate,
                "sampleRateHertz": 24000
            ]
        ]

        guard let url = URL(string: "\(endpoint)?key=\(apiKey)") else {
            throw TTSError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TTSError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw TTSError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let audioContent = json["audioContent"] as? String,
              let audioData = Data(base64Encoded: audioContent) else {
            throw TTSError.invalidAudioData
        }

        return audioData
    }

    /// 言語に応じた音声名を返す（設定から取得）
    private func voiceName(for language: SpeechLanguage) -> String {
        let model = TTSModel.current
        let key: String
        switch language {
        case .japanese: key = "japaneseVoice"
        case .english:  key = "englishVoice"
        }

        if let saved = UserDefaults.standard.string(forKey: key) {
            let voices = VoiceOption.voices(for: language, model: model)
            if voices.contains(where: { $0.name == saved }) {
                return saved
            }
        }

        return VoiceOption.voices(for: language, model: model).first?.name ?? "ja-JP-Neural2-B"
    }
}

// MARK: - Errors

enum TTSError: LocalizedError {
    case noAPIKey
    case invalidURL
    case invalidResponse
    case apiError(statusCode: Int, message: String)
    case invalidAudioData

    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "API key is not configured."
        case .invalidURL:
            return "Invalid API URL."
        case .invalidResponse:
            return "Invalid response from server."
        case .apiError(let code, let message):
            return "API error (\(code)): \(message)"
        case .invalidAudioData:
            return "Failed to decode audio data."
        }
    }
}
