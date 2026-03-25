import UIKit
import EasyIFly

class ViewController: UIViewController {

    private let resultLabel: UILabel = {
        let l = UILabel()
        l.text = "识别结果将显示在这里"
        l.textAlignment = .center
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let startButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("开始语音识别", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 18)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.addSubview(resultLabel)
        view.addSubview(startButton)

        NSLayoutConstraint.activate([
            resultLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            resultLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -60),
            resultLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            resultLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            startButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            startButton.topAnchor.constraint(equalTo: resultLabel.bottomAnchor, constant: 32),
        ])

        startButton.addTarget(self, action: #selector(startRecognition), for: .touchUpInside)

        EasyIFly.setup(appid: AppConfig.iflyAppID)
    }

    @objc private func startRecognition() {
        EasyIFly.showVirtualNumberInput { phone in
            self.resultLabel.text = "识别结果：\(phone)"
        }
    }
}
