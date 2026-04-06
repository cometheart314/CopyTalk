import Cocoa

@MainActor
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
    /// システム設定（アクセシビリティ > システムの声）を優先し、
    /// 言語が一致しない場合のみ該当言語の音声にフォールバック
    private func selectVoice(for language: SpeechLanguage) -> NSSpeechSynthesizer.VoiceName? {
        let targetPrefix: String
        switch language {
        case .japanese: targetPrefix = "ja"
        case .english:  targetPrefix = "en"
        }

        // システムのデフォルト音声が対象言語に一致すればそれを使う
        let defaultVoice = NSSpeechSynthesizer.defaultVoice
        let defaultAttrs = NSSpeechSynthesizer.attributes(forVoice: defaultVoice)
        if let localeId = defaultAttrs[.localeIdentifier] as? String,
           localeId.hasPrefix(targetPrefix) {
            return defaultVoice
        }

        // 一致しない場合、対象言語の音声から最初のものを選択
        for voice in NSSpeechSynthesizer.availableVoices {
            let attrs = NSSpeechSynthesizer.attributes(forVoice: voice)
            if let localeId = attrs[.localeIdentifier] as? String,
               localeId.hasPrefix(targetPrefix) {
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

    nonisolated func speechSynthesizer(_ sender: NSSpeechSynthesizer, didFinishSpeaking finishedSpeaking: Bool) {
        Task { @MainActor in
            continuation?.resume()
            continuation = nil
        }
    }
}
