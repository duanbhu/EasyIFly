import UIKit

public class SpeechRecognitionView: UIView {

    public var onResult: ((String) -> Void)?
    public var resultFilter: ((String) -> String?)?
    public var onDismiss: (() -> Void)?
    
    /// 可在显示期间切换主题，不会重启识别。
    public var theme: SpeechRecognitionTheme = .blue { didSet { applyTheme() } }

    private var isListening = false

    // MARK: - UI

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "请语音输入"
        l.textAlignment = .center
        l.textColor = .white
        l.font = .systemFont(ofSize: 16)
        l.backgroundColor = .systemBlue
        return l
    }()

    private let waveformView = SpeechWaveformView()
    private let voiceImageView = SpeechMicrophoneView()

    private let cancelButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("结束录入", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 16)
        b.backgroundColor = UIColor(red: 0.94, green: 0.95, blue: 1, alpha: 1)
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

    deinit { 
        stopListening()
    }

    // MARK: - Setup

    private func setup() {
        backgroundColor = .white
        layer.cornerRadius = 15
        layer.masksToBounds = true

        [titleLabel, waveformView, voiceImageView, cancelButton]
            .forEach { $0.translatesAutoresizingMaskIntoConstraints = false; addSubview($0) }

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            titleLabel.heightAnchor.constraint(equalToConstant: 48),

            voiceImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            voiceImageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            voiceImageView.widthAnchor.constraint(equalToConstant: 44),
            voiceImageView.heightAnchor.constraint(equalToConstant: 44),

            waveformView.centerXAnchor.constraint(equalTo: centerXAnchor),
            waveformView.centerYAnchor.constraint(equalTo: voiceImageView.centerYAnchor),
            waveformView.widthAnchor.constraint(equalToConstant: 244),
            waveformView.heightAnchor.constraint(equalToConstant: 47),

            cancelButton.topAnchor.constraint(equalTo: voiceImageView.bottomAnchor, constant: 24),
            cancelButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            cancelButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            cancelButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            cancelButton.heightAnchor.constraint(equalToConstant: 55),
        ])

        cancelButton.addTarget(self, action: #selector(dismiss), for: .touchUpInside)

        recognizer.resultFilter = { [weak self] in self?.resultFilter?($0) }
        recognizer.onResult = { [weak self] result in
            self?.onResult?(result)
            self?.dismiss()
        }
        applyTheme()
        // 不自动开始识别，等待外部调用 startListening()
    }
    
    /// 开始语音识别
    public func startListening() {
        guard !isListening else { return }
        isListening = true
        waveformView.start()
        recognizer.startListening()
    }
    
    /// 停止语音识别
    public func stopListening() {
        waveformView.stop()
        guard isListening else { return }
        isListening = false
        recognizer.stopListening()
    }

    #if targetEnvironment(simulator)
    /// UI 验收时注入文本；仍经过 resultFilter，匹配后正常回调并关闭弹层。
    public func simulateResult(_ text: String) {
        recognizer.simulateResult(text)
    }
    #endif

    @objc private func dismiss() {
        stopListening()
        removeFromSuperview()
        onDismiss?()
    }

    private func applyTheme() {
        backgroundColor = theme.backgroundColor
        titleLabel.backgroundColor = theme.titleBackgroundColor
        titleLabel.textColor = theme.titleTextColor
        waveformView.color = theme.waveformColor
        voiceImageView.color = theme.microphoneColor
        cancelButton.backgroundColor = theme.buttonBackgroundColor
        cancelButton.setTitleColor(theme.buttonTextColor, for: .normal)
    }

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil { waveformView.start() } else { waveformView.stop() }
    }
}

// MARK: - Convenience present / dismiss

public extension SpeechRecognitionView {

    /// 以半透明遮罩形式展示在 window 上
    @discardableResult
    static func show(
        title: String = "请语音输入",
        autoStart: Bool = true,
        theme: SpeechRecognitionTheme = .blue,
        resultFilter: @escaping (String) -> String?,
        onResult: @escaping (String) -> Void,
        onDismiss: (() -> Void)? = nil
    ) -> SpeechRecognitionView? {
        guard let window = UIApplication.shared.windows.first(where: \.isKeyWindow) else { return nil }

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
        view.theme = theme
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
        
        // 根据 autoStart 参数决定是否自动开始识别
        if autoStart {
            view.startListening()
        }
        
        return view
    }
}

/// 与 Android SpeechRecognitionTheme 对应，各区域颜色可独立配置。
public struct SpeechRecognitionTheme {
    public var primaryColor: UIColor
    public var titleBackgroundColor: UIColor
    public var titleTextColor: UIColor
    public var waveformColor: UIColor
    public var microphoneColor: UIColor
    public var buttonBackgroundColor: UIColor
    public var buttonTextColor: UIColor
    public var backgroundColor: UIColor

    public init(
        primaryColor: UIColor,
        titleBackgroundColor: UIColor? = nil,
        titleTextColor: UIColor = .white,
        waveformColor: UIColor? = nil,
        microphoneColor: UIColor? = nil,
        buttonBackgroundColor: UIColor = UIColor(white: 245 / 255, alpha: 1),
        buttonTextColor: UIColor? = nil,
        backgroundColor: UIColor = .white
    ) {
        self.primaryColor = primaryColor
        self.titleBackgroundColor = titleBackgroundColor ?? primaryColor
        self.titleTextColor = titleTextColor
        self.waveformColor = waveformColor ?? primaryColor
        self.microphoneColor = microphoneColor ?? primaryColor
        self.buttonBackgroundColor = buttonBackgroundColor
        self.buttonTextColor = buttonTextColor ?? primaryColor
        self.backgroundColor = backgroundColor
    }

    public static let blue = SpeechRecognitionTheme(
        primaryColor: UIColor(rgb: 0x007aff),
        waveformColor: UIColor(rgb: 0x91aaf7),
        microphoneColor: UIColor(rgb: 0x6e8ee7),
        buttonBackgroundColor: UIColor(rgb: 0xf0f2ff)
    )
    public static let red = SpeechRecognitionTheme(
        primaryColor: UIColor(rgb: 0xff3b30),
        titleBackgroundColor: UIColor(rgb: 0xfff5e6),
        titleTextColor: .black,
        waveformColor: UIColor(rgb: 0xff8a80),
        buttonBackgroundColor: UIColor(rgb: 0xffefed)
    )
}

private extension UIColor {
    convenience init(rgb: UInt32) {
        self.init(red: CGFloat((rgb >> 16) & 255) / 255,
                  green: CGFloat((rgb >> 8) & 255) / 255,
                  blue: CGFloat(rgb & 255) / 255, alpha: 1)
    }
}

// Android 同款五帧波形，每帧 350 ms。
private final class SpeechWaveformView: UIView {
    var color: UIColor = .clear { didSet { setNeedsDisplay() } }
    private let bars: [CGFloat] = [0.24, 0.42, 0.62, 0.35, 0.75, 0.48, 0.28, 0.58, 0.82, 0.36]
    private var animationFrame = 0
    private var timer: Timer?

    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
        isUserInteractionEnabled = false
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    deinit { timer?.invalidate() }

    func start() {
        guard timer == nil else { return }
        advanceFrame()
        let ticker = Timer(timeInterval: 0.35, repeats: true) { [weak self] _ in self?.advanceFrame() }
        timer = ticker
        RunLoop.main.add(ticker, forMode: .common)
    }
    private func advanceFrame() {
        animationFrame = (animationFrame + 1) % 5
        setNeedsDisplay()
    }
    func stop() {
        timer?.invalidate()
        timer = nil
    }
    override func draw(_ rect: CGRect) {
        color.setStroke()
        let path = UIBezierPath()
        // Android 波形为 2px 细线，麦克风为 2dp。
        path.lineWidth = 2 / (window?.screen.scale ?? UIScreen.main.scale)
        let gap = bounds.width * 90 / 244 / CGFloat(bars.count)
        let inner = bounds.width * 32 / 244
        for side: CGFloat in [-1, 1] {
            for index in bars.indices {
                let x = bounds.midX + side * (inner + CGFloat(index) * gap)
                let height = bounds.height * bars[(index + animationFrame) % bars.count]
                path.move(to: CGPoint(x: x, y: bounds.midY - height / 2))
                path.addLine(to: CGPoint(x: x, y: bounds.midY + height / 2))
            }
        }
        path.stroke()
    }
}

private final class SpeechMicrophoneView: UIView {
    var color: UIColor = .clear { didSet { setNeedsDisplay() } }
    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
        isUserInteractionEnabled = false
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func draw(_ rect: CGRect) {
        color.setStroke()
        let cx = bounds.midX
        let cy = bounds.midY
        let unit = min(bounds.width, bounds.height) / 44
        let capsule = UIBezierPath(roundedRect: CGRect(x: cx - 6 * unit, y: cy - 18 * unit,
                                                     width: 12 * unit, height: 22 * unit), cornerRadius: 6 * unit)
        capsule.lineWidth = 2
        capsule.stroke()
        let stand = UIBezierPath()
        let arc = UIBezierPath(arcCenter: .zero, radius: 1, startAngle: 0, endAngle: .pi, clockwise: true)
        arc.apply(CGAffineTransform(scaleX: 12 * unit, y: 10 * unit))
        arc.apply(CGAffineTransform(translationX: cx, y: cy + 2 * unit))
        stand.append(arc)
        stand.move(to: CGPoint(x: cx, y: cy + 12 * unit))
        stand.addLine(to: CGPoint(x: cx, y: cy + 19 * unit))
        stand.move(to: CGPoint(x: cx - 7 * unit, y: cy + 19 * unit))
        stand.addLine(to: CGPoint(x: cx + 7 * unit, y: cy + 19 * unit))
        stand.lineWidth = 2
        stand.lineCapStyle = .round
        stand.stroke()
    }
}
