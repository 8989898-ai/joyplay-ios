import UIKit

final class PartialGameViewController: UIViewController {
    private let displayMode: GameDisplayMode
    private let appKey: String
    private let token: String
    private let widthHeightRatio: CGFloat
    private var gameWebView: GameWebView?

    private lazy var backgroundImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: displayMode.backgroundImageName))
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()

    private lazy var gameButton = DemoGameLaunchButton(title: displayMode.openGameTitle)

    init(
        displayMode: GameDisplayMode,
        appKey: String,
        token: String,
        widthHeightRatio: CGFloat
    ) {
        self.displayMode = displayMode
        self.appKey = appKey
        self.token = token
        self.widthHeightRatio = widthHeightRatio
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = String(localized: "game.title", defaultValue: "Game")
        view.backgroundColor = .systemBackground
        configureLayout()
        gameButton.addTarget(self, action: #selector(openGame), for: .touchUpInside)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        gameButton.startBreathing()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        gameButton.stopBreathing()
        if isMovingFromParent {
            gameWebView?.stop()
        }
    }

    private func configureLayout() {
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backgroundImageView)
        view.addSubview(gameButton)

        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            gameButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            gameButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            gameButton.widthAnchor.constraint(equalToConstant: 160),
            gameButton.heightAnchor.constraint(equalTo: gameButton.widthAnchor)
        ])
    }

    @objc private func openGame() {
        guard gameWebView == nil,
              let gameURL = DemoGameURLBuilder.makeURL(
                  appKey: appKey,
                  token: token,
                  displayMode: displayMode
              ) else {
            return
        }

        guard let gameWebView = GameWebView(
            gameURL: gameURL,
            displayMode: displayMode,
            widthHeightRatio: widthHeightRatio,
            onEvent: { [weak self] event in
                self?.handleGameEvent(event)
            }
        ) else {
            return
        }

        gameButton.stopBreathing()
        view.addSubview(gameWebView)
        NSLayoutConstraint.activate([
            gameWebView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gameWebView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gameWebView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        self.gameWebView = gameWebView
        gameButton.isHidden = true
    }

    private func handleGameEvent(_ event: GameEvent) {
        switch event {
        case .insufficientBalance, .recharge:
            DemoRechargePromptPresenter.present(from: self) { [weak self] in
                self?.gameWebView?.notifyGameBalanceDidChange()
            }
        case .close:
            removeGameView()
        case .openGameSuccess:
            break
        }
    }

    private func removeGameView() {
        guard let gameWebView else {
            return
        }

        gameWebView.stop()
        gameWebView.removeFromSuperview()
        self.gameWebView = nil
        gameButton.isHidden = false
        gameButton.startBreathing()
    }
}
