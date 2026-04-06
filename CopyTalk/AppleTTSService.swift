import Cocoa

class AppleTTSService: NSObject, NSSpeechSynthesizerDelegate {

    private var synthesizer: NSSpeechSynthesizer?
    private var continuation: CheckedContinuation<Void, Never>?

    /// テキストを読み上げ、完了まで待機する
    func speakAndWait(text: String, language: SpeechLanguage) async {
        let voiceId = selectVoice(for: language)
        let synth = NSSpeechSynthesizer(voice: voiceId)
        synth?.delegate = self

        let googleRate = UserDefaults.standard.double(forKey: "speakingRate")
        let rate = googleRate > 0 ? googleRate : 1.0
        synth?.rate = mapSpeakingRate(rate)

        synthesizer = synth

        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            self.continuation = cont
            if synth?.startSpeaking(text) != true {
                cont.resume()
                self.continuation = nil
            }
        }
    }

    /// 読み上げを即座に停止する
    func stop() {
        synthesizer?.stopSpeaking()
    }

    /// 言語に応じた音声を選択する
    private func selectVoice(for language: SpeechLanguage) -> NSSpeechSynthesizer.VoiceName? {
        let targetLocale: String
        switch language {
        case .japanese: targetLocale = "ja"
        case .english: targetLocale = "en"
        }

        // 利用可能な音声から言語に一致するものを探す
        let voices = NSSpeechSynthesizer.availableVoices
        for voice in voices {
            let attrs = NSSpeechSynthesizer.attributes(forVoice: voice)
            if let localeId = attrs[.localeIdentifier] as? String,
               localeId.hasPrefix(targetLocale) {
                return voice
            }
        }
        return NSSpeechSynthesizer.defaultVoice
    }

    /// Google TTS の速度 (0.5-2.0, 1.0=標準) を NSSpeechSynthesizer の速度にマッピング
    /// NSSpeechSynthesizer.rate はワード/分（デフォルト約180-200）
    private func mapSpeakingRate(_ googleRate: Double) -> Float {
        // Google 0.5 -> 100wpm, Google 1.0 -> 190wpm, Google 2.0 -> 350wpm
        let mapped = 100 + (googleRate - 0.5) * (250.0 / 1.5)
        return Float(max(80, min(400, mapped)))
    }

    // MARK: - NSSpeechSynthesizerDelegate

    func speechSynthesizer(_ sender: NSSpeechSynthesizer, didFinishSpeaking finishedSpeaking: Bool) {
        continuation?.resume()
        continuation = nil
    }
}
