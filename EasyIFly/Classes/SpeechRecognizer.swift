import Foundation
#if !targetEnvironment(simulator)
import iflyMSC
#endif

public class SpeechRecognizer: NSObject {

    public enum Status {
        case beginOfSpeech, endOfSpeech, cancel, results, completed
    }

    public var onStatus: ((Status) -> Void)?
    public var onResult: ((String) -> Void)?

    /// 对识别文本做过滤/转换，返回 nil 表示结果不符合预期，继续识别
    public var resultFilter: ((String) -> String?)?

    #if !targetEnvironment(simulator)
    private let recognizer: IFlySpeechRecognizer = .sharedInstance()

    #endif

    #if targetEnvironment(simulator)
    private var isListening = false
    #endif

    /// 使用前调用一次，传入讯飞 AppID
    public static func setup(appid: String) {
        #if !targetEnvironment(simulator)
        IFlySpeechUtility.createUtility("appid=\(appid)")
        #endif
    }

    public override init() {
        super.init()
        #if !targetEnvironment(simulator)
        applyConfig()
        #endif
    }

    // MARK: - Public

    public func startListening() {
        #if targetEnvironment(simulator)
        guard !isListening else { return }
        isListening = true
        onStatus?(.beginOfSpeech)
        #else
        recognizer.cancel()
        recognizer.delegate = self
        recognizer.startListening()
        #endif
    }

    public func stopListening() {
        #if targetEnvironment(simulator)
        let wasListening = isListening
        isListening = false
        if wasListening { onStatus?(.cancel) }
        #else
        recognizer.delegate = nil
        recognizer.stopListening()
        #endif
    }

    // MARK: - Private

    #if targetEnvironment(simulator)
    /// 注入预览文本，走与真机相同的过滤和结果回调；不录音、不访问网络。
    /// 未开始或已停止时忽略，过滤未通过时继续等待输入。
    public func simulateResult(_ text: String) {
        guard isListening else { return }
        onStatus?(.results)
        guard let filtered = resultFilter?(text) else { return }
        isListening = false
        onStatus?(.endOfSpeech)
        onResult?(filtered)
        onStatus?(.completed)
    }
    #else
    private func applyConfig() {
        let c = IATConfig.shared
        let params: [(String, String)] = [
            ("",            IFlySpeechConstant.params()),
            ("iat",         IFlySpeechConstant.ifly_DOMAIN()),
            (c.speechTimeout, "SPEECH_TIMEOUT"),
            (c.vadEos,      IFlySpeechConstant.vad_EOS()),
            (c.vadBos,      IFlySpeechConstant.vad_BOS()),
            ("20000",       IFlySpeechConstant.net_TIMEOUT()),
            (c.sampleRate,  IFlySpeechConstant.sample_RATE()),
            (c.language,    IFlySpeechConstant.language()),
            (c.accent,      IFlySpeechConstant.accent()),
            (c.dot,         IFlySpeechConstant.asr_PTT()),
            ("0",           "audio_source"),
            ("json",        IFlySpeechConstant.result_TYPE()),
            ("asr.pcm",     IFlySpeechConstant.asr_AUDIO_PATH()),
        ]
        params.forEach { recognizer.setParameter($0.0, forKey: $0.1) }
    }
    #endif
}

// MARK: - IFlySpeechRecognizerDelegate

#if !targetEnvironment(simulator)
extension SpeechRecognizer: IFlySpeechRecognizerDelegate {

    public func onBeginOfSpeech() { onStatus?(.beginOfSpeech) }
    public func onEndOfSpeech()   { onStatus?(.endOfSpeech) }
    public func onCancel()        { onStatus?(.cancel) }

    public func onCompleted(_ errorCode: IFlySpeechError!) {
        onStatus?(.completed)
    }

    public func onVolumeChanged(_ volume: Int32) {}

    public func onResults(_ results: [Any]!, isLast: Bool) {
        onStatus?(.results)

        guard
            let dic = results?.first as? [String: String],
            let raw = ISRDataHelper.string(fromJson: dic.keys.joined())
        else {
            recognizer.startListening()
            return
        }

        if let filtered = resultFilter?(raw) {
            stopListening()
            onResult?(filtered)
        } else {
            recognizer.startListening()
        }
    }
}

#endif
