import UIKit
import iflyMSC

public class SpeechRecognitionView: UIView {

    public var onResult: ((String) -> Void)?
    public var resultFilter: ((String) -> String?)?
    public var onDismiss: (() -> Void)?

    // MARK: - UI

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "请语音输入"
        l.textAlignment = .center
        l.textColor = .white
        l.font = .systemFont(ofSize: 16, weight: .medium)
        l.backgroundColor = .systemBlue
        return l
    }()

    private let leftImageView  = SpeechRecognitionView.makeAnimatedImageView(prefix: "warehousing_mic_left",  count: 5)
    private let rightImageView = SpeechRecognitionView.makeAnimatedImageView(prefix: "warehousing_mic_right", count: 5)

    private let voiceImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = SpeechRecognitionView.bundleImage(named: "warehousing_mic")
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let cancelButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("取消", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 16)
        b.backgroundColor = UIColor(red: 0.94, green: 0.95, blue: 1, alpha: 1)
        return b
    }()

    private let confirmButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("确认", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 16)
        b.backgroundColor = .systemBlue
        return b
    }()

    private let recognizer = SpeechRecognizer()

    // MARK: - Init

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    deinit { recognizer.stopListening() }

    // MARK: - Setup

    private func setup() {
        backgroundColor = .white
        layer.cornerRadius = 15
        layer.masksToBounds = true

        [titleLabel, leftImageView, voiceImageView, rightImageView, cancelButton, confirmButton]
            .forEach { $0.translatesAutoresizingMaskIntoConstraints = false; addSubview($0) }

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            titleLabel.heightAnchor.constraint(equalToConstant: 48),

            voiceImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            voiceImageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 25),
            voiceImageView.widthAnchor.constraint(equalToConstant: 44),
            voiceImageView.heightAnchor.constraint(equalToConstant: 44),

            leftImageView.trailingAnchor.constraint(equalTo: voiceImageView.leadingAnchor, constant: -10),
            leftImageView.centerYAnchor.constraint(equalTo: voiceImageView.centerYAnchor),
            leftImageView.widthAnchor.constraint(equalToConstant: 90),
            leftImageView.heightAnchor.constraint(equalToConstant: 47),

            rightImageView.leadingAnchor.constraint(equalTo: voiceImageView.trailingAnchor, constant: 10),
            rightImageView.centerYAnchor.constraint(equalTo: voiceImageView.centerYAnchor),
            rightImageView.widthAnchor.constraint(equalToConstant: 90),
            rightImageView.heightAnchor.constraint(equalToConstant: 47),

            cancelButton.topAnchor.constraint(equalTo: voiceImageView.bottomAnchor, constant: 23),
            cancelButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            cancelButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            cancelButton.heightAnchor.constraint(equalToConstant: 55),

            confirmButton.topAnchor.constraint(equalTo: cancelButton.topAnchor),
            confirmButton.leadingAnchor.constraint(equalTo: cancelButton.trailingAnchor),
            confirmButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            confirmButton.widthAnchor.constraint(equalTo: cancelButton.widthAnchor),
            confirmButton.heightAnchor.constraint(equalTo: cancelButton.heightAnchor),
        ])

        cancelButton.addTarget(self, action: #selector(dismiss), for: .touchUpInside)
        confirmButton.addTarget(self, action: #selector(dismiss), for: .touchUpInside)

        recognizer.resultFilter = { [weak self] in self?.resultFilter?($0) }
        recognizer.onResult = { [weak self] result in
            self?.onResult?(result)
            self?.dismiss()
        }
        recognizer.startListening()
        leftImageView.startAnimating()
        rightImageView.startAnimating()
    }

    @objc private func dismiss() {
        recognizer.stopListening()
        removeFromSuperview()
        onDismiss?()
    }

    // MARK: - Helpers

    private static func makeAnimatedImageView(prefix: String, count: Int) -> UIImageView {
        let iv = UIImageView()
        iv.animationImages = (1...count).compactMap { bundleImage(named: "\(prefix)\($0)") }
        iv.animationDuration = 1.75
        iv.contentMode = .scaleAspectFit
        return iv
    }

    private static func bundleImage(named name: String) -> UIImage? {
        #if SWIFT_PACKAGE
        // SPM: 使用 Bundle.module
        let bundle = Bundle.module
        #else
        // CocoaPods: 从 resource_bundle 加载
        let bundle = Bundle(for: SpeechRecognitionView.self)
            .url(forResource: "EasyIFly", withExtension: "bundle")
            .flatMap(Bundle.init(url:)) ?? Bundle(for: SpeechRecognitionView.self)
        #endif
        return UIImage(named: name, in: bundle, compatibleWith: nil)
    }
}

// MARK: - Convenience present / dismiss

public extension SpeechRecognitionView {

    /// 以半透明遮罩形式展示在 window 上
    static func show(
        title: String = "请语音输入",
        resultFilter: @escaping (String) -> String?,
        onResult: @escaping (String) -> Void,
        onDismiss: (() -> Void)? = nil
    ) {
        guard let window = UIApplication.shared.windows.first(where: \.isKeyWindow) else { return }

        let overlay = UIControl()
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        overlay.translatesAutoresizingMaskIntoConstraints = false
        window.addSubview(overlay)
        NSLayoutConstraint.activate([
            overlay.topAnchor.constraint(equalTo: window.topAnchor),
            overlay.bottomAnchor.constraint(equalTo: window.bottomAnchor),
            overlay.leadingAnchor.constraint(equalTo: window.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: window.trailingAnchor),
        ])

        let view = SpeechRecognitionView()
        view.titleLabel.text = title
        view.resultFilter = resultFilter
        view.translatesAutoresizingMaskIntoConstraints = false
        window.addSubview(view)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: window.leadingAnchor, constant: 32),
            view.trailingAnchor.constraint(equalTo: window.trailingAnchor, constant: -32),
            view.bottomAnchor.constraint(equalTo: window.safeAreaLayoutGuide.bottomAnchor, constant: -20),
        ])

        view.onResult = onResult
        view.onDismiss = {
            overlay.removeFromSuperview()
            onDismiss?()
        }
        overlay.addTarget(view, action: #selector(dismiss), for: .touchUpInside)
    }
}
