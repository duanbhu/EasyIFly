import UIKit
import EasyIFly

class ViewController: UIViewController {
    private var mode = 1
    private var redTheme = false
    private weak var sheet: SpeechRecognitionView?
    private let modeTitle = UILabel()
    private let resultLabel = UILabel()
    private let modes = UIStackView()
    private let themes = UIStackView()
    private let startButton = UIButton(type: .system)
    private var theme: SpeechRecognitionTheme { redTheme ? .red : .blue }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        EasyIFly.setup(appid: AppConfig.iflyAppID)

        let root = UIStackView()
        root.axis = .vertical
        root.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(root)
        NSLayoutConstraint.activate([
            root.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            root.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            root.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        themes.distribution = .fillEqually
        for (index, title) in ["蓝色主题", "红色主题"].enumerated() {
            let button = makeButton(title, tag: index, selector: #selector(selectTheme(_:)))
            button.setTitleColor(index == 0 ? SpeechRecognitionTheme.blue.primaryColor : SpeechRecognitionTheme.red.primaryColor, for: .normal)
            themes.addArrangedSubview(button)
        }
        root.addArrangedSubview(themes)

        let panel = UIStackView()
        panel.axis = .vertical
        panel.isLayoutMarginsRelativeArrangement = true
        panel.layoutMargins = UIEdgeInsets(top: 16, left: 20, bottom: 16, right: 20)
        panel.layer.cornerRadius = 24
        panel.layer.borderWidth = 1
        panel.layer.borderColor = UIColor(white: 221 / 255, alpha: 1).cgColor
        root.addArrangedSubview(panel)
        modeTitle.font = .systemFont(ofSize: 16)
        modeTitle.textColor = .darkGray
        panel.addArrangedSubview(modeTitle)
        panel.setCustomSpacing(6, after: modeTitle)

        modes.distribution = .fillEqually
        for (index, title) in ["手机号", "手机号／虚拟号", "普通文字"].enumerated() {
            modes.addArrangedSubview(makeButton(title, tag: index, selector: #selector(selectMode(_:))))
        }
        panel.addArrangedSubview(modes)
        panel.setCustomSpacing(12, after: modes)
        resultLabel.font = .systemFont(ofSize: 20)
        resultLabel.textColor = .black
        resultLabel.numberOfLines = 0
        resultLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 48).isActive = true
        panel.addArrangedSubview(resultLabel)
        panel.setCustomSpacing(8, after: resultLabel)
        startButton.setTitle("开始说话", for: .normal)
        startButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
        startButton.addTarget(self, action: #selector(startRecognition), for: .touchUpInside)
        panel.addArrangedSubview(startButton)
        #if targetEnvironment(simulator)
        redTheme = UserDefaults.standard.string(forKey: "speech-theme") == "red"
        mode = ["phone", "virtual", "text"].firstIndex(of: UserDefaults.standard.string(forKey: "speech-mode") ?? "virtual") ?? 1
        #endif
        renderMode()
        applyTheme()
    }

    #if targetEnvironment(simulator)
    private var didPresentPreview = false

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !didPresentPreview, UserDefaults.standard.bool(forKey: "show-dialog") else { return }
        didPresentPreview = true
        startRecognition()
    }
    #endif

    private func makeButton(_ title: String, tag: Int, selector: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14)
        button.tag = tag
        button.heightAnchor.constraint(equalToConstant: 48).isActive = true
        button.addTarget(self, action: selector, for: .touchUpInside)
        return button
    }

    @objc private func selectTheme(_ sender: UIButton) {
        redTheme = sender.tag == 1
        applyTheme()
        sheet?.theme = theme
    }

    private func applyTheme() {
        for (index, button) in themes.arrangedSubviews.enumerated() {
            button.alpha = (index == 1) == redTheme ? 1 : 0.55
        }
        for case let button as UIButton in modes.arrangedSubviews + [startButton] {
            button.setTitleColor(theme.buttonTextColor, for: .normal)
            button.backgroundColor = theme.buttonBackgroundColor
        }
    }

    @objc private func selectMode(_ sender: UIButton) {
        mode = sender.tag
        renderMode()
    }

    private func renderMode() {
        modeTitle.text = ["语音录入手机号", "语音录入手机号／虚拟号", "语音转文字"][mode]
        resultLabel.text = "请点击开始，说出要录入的内容"
        for (index, button) in modes.arrangedSubviews.enumerated() {
            button.alpha = index == mode ? 1 : 0.55
        }
    }

    @objc private func startRecognition() {
        let onResult: (String) -> Void = { [weak self] value in
            guard let self = self else { return }
            self.resultLabel.text = self.mode == 2 ? value : "手机号：" + value.replacingOccurrences(of: "-", with: "\n虚拟号：")
        }
        var autoStart = true
        #if targetEnvironment(simulator)
        autoStart = UserDefaults.standard.object(forKey: "auto-start") == nil || UserDefaults.standard.bool(forKey: "auto-start")
        #endif
        switch mode {
        case 0:
            sheet = EasyIFly.showPhoneInput(autoStart: autoStart, theme: theme, onResult: onResult)
        case 1:
            sheet = EasyIFly.showVirtualNumberInput(autoStart: autoStart, theme: theme, onResult: onResult)
        default:
            sheet = EasyIFly.showSpeechInput(autoStart: autoStart, theme: theme, resultFilter: { $0.isEmpty ? nil : $0 }, onResult: onResult)
        }
        #if targetEnvironment(simulator)
        if let text = UserDefaults.standard.string(forKey: "simulated-text") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.sheet?.simulateResult(text)
            }
        }
        #endif
    }
}
