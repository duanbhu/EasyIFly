import Foundation
import iflyMSC

public class EasyIFly {

    public static func setup(appid: String) {
        SpeechRecognizer.setup(appid: appid)
    }

    public static func showSpeechInput(
        title: String = "请语音输入",
        resultFilter: @escaping (String) -> String?,
        onResult: @escaping (String) -> Void,
        onDismiss: (() -> Void)? = nil
    ) {
        SpeechRecognitionView.show(
            title: title,
            resultFilter: resultFilter,
            onResult: onResult,
            onDismiss: onDismiss
        )
    }

    /// 识别手机号（11位）
    public static func showPhoneInput(
        onResult: @escaping (String) -> Void,
        onDismiss: (() -> Void)? = nil
    ) {
        showSpeechInput(
            title: "请语音输入手机号",
            resultFilter: { text in
                let digits = text.filter(\.isNumber)
                return digits.count == 11 ? digits : nil
            },
            onResult: onResult,
            onDismiss: onDismiss
        )
    }

    /// 识别虚拟号（18888888888-1234）或普通手机号（11位）
    public static func showVirtualNumberInput(
        onResult: @escaping (String) -> Void,
        onDismiss: (() -> Void)? = nil
    ) {
        showSpeechInput(
            title: "请语音输入手机号",
            resultFilter: { text in
                let digits = text.filter(\.isNumber)
                switch digits.count {
                case 11:
                    return digits
                case 14, 15:
                    return "\(digits.prefix(11))-\(digits.dropFirst(11))"
                default:
                    return nil
                }
            },
            onResult: onResult,
            onDismiss: onDismiss
        )
    }
}
