import UIKit

final class ViewController: UIViewController {
    private let appKeyTextField: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .roundedRect
        textField.placeholder = String(
            localized: "home.app_key.placeholder",
            defaultValue: "Enter AppKey"
        )
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.clearButtonMode = .whileEditing
        return textField
    }()

    private let tokenTextField: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .roundedRect
        textField.placeholder = String(
            localized: "home.token.placeholder",
            defaultValue: "Enter Game Token"
        )
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.clearButtonMode = .whileEditing
        return textField
    }()

    private let enterGameButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.title = String(
            localized: "home.enter_button",
            defaultValue: "Enter"
        )
        configuration.cornerStyle = .medium

        let button = UIButton(configuration: configuration)
        button.isEnabled = false
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = String(
            localized: "home.title",
            defaultValue: "H5 Game Integration Demo"
        )
        view.backgroundColor = .systemBackground
        configureLayout()
        configureActions()
    }

    private func configureLayout() {
        let scrollView = UIScrollView()
        let contentView = UIView()
        let inputLabel = makeLabel(
            text: String(
                localized: "home.section.integration_info",
                defaultValue: "Integration Information"
            ),
            style: .headline
        )

        let formStackView = UIStackView(arrangedSubviews: [
            inputLabel,
            appKeyTextField,
            tokenTextField,
            enterGameButton
        ])
        formStackView.axis = .vertical
        formStackView.spacing = 16

        [scrollView, contentView, formStackView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(formStackView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            contentView.heightAnchor.constraint(greaterThanOrEqualTo: scrollView.frameLayoutGuide.heightAnchor),

            formStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 40),
            formStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            formStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            formStackView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -24),

            appKeyTextField.heightAnchor.constraint(equalToConstant: 44),
            tokenTextField.heightAnchor.constraint(equalToConstant: 44),
            enterGameButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    private func makeLabel(text: String, style: UIFont.TextStyle) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .preferredFont(forTextStyle: style)
        label.adjustsFontForContentSizeCategory = true
        return label
    }

    private func configureActions() {
        appKeyTextField.addTarget(self, action: #selector(inputDidChange), for: .editingChanged)
        tokenTextField.addTarget(self, action: #selector(inputDidChange), for: .editingChanged)
        enterGameButton.addTarget(self, action: #selector(enterGame), for: .touchUpInside)

        let dismissKeyboardTap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        dismissKeyboardTap.cancelsTouchesInView = false
        dismissKeyboardTap.delegate = self
        view.addGestureRecognizer(dismissKeyboardTap)
    }

    @objc private func inputDidChange() {
        enterGameButton.isEnabled = GameEntryValidator.isValid(
            appKey: appKeyTextField.text ?? "",
            token: tokenTextField.text ?? ""
        )
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func enterGame() {
        view.endEditing(true)

        guard
            let appKey = appKeyTextField.text,
            let token = tokenTextField.text,
            GameEntryValidator.isValid(appKey: appKey, token: token)
        else {
            return
        }

        let gameModeTabBarController = GameModeTabBarController(
            appKey: appKey.trimmingCharacters(in: .whitespacesAndNewlines),
            token: token.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        navigationController?.pushViewController(gameModeTabBarController, animated: true)
    }
}

extension ViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        !(touch.view is UIControl)
    }
}
