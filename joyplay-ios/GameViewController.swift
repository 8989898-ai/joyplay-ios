import UIKit

final class GameViewController: UIViewController {
    private let gameURL: URL
    private let displayMode: GameDisplayMode
    private let widthHeightRatio: CGFloat?
    private lazy var gameWebView: GameWebView? = GameWebView(
        gameURL: gameURL,
        displayMode: displayMode,
        widthHeightRatio: widthHeightRatio,
        onEvent: { [weak self] event in
            self?.handleGameEvent(event)
        }
    )

    init(
        gameURL: URL,
        displayMode: GameDisplayMode,
        widthHeightRatio: CGFloat? = nil
    ) {
        self.gameURL = gameURL
        self.displayMode = displayMode
        self.widthHeightRatio = widthHeightRatio
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = displayMode.title
        view.backgroundColor = .systemBackground
        configureGameView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(displayMode.hidesNavigationBar, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent {
            gameWebView?.stop()
        }
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    private func handleGameEvent(_ event: GameEvent) {
        switch event {
        case .insufficientBalance, .recharge:
            DemoRechargePromptPresenter.present(from: self) { [weak self] in
                self?.gameWebView?.notifyGameBalanceDidChange()
            }
        case .close:
            navigationController?.popViewController(animated: true)
        case .openGameSuccess:
            break
        }
    }

    private func configureGameView() {
        guard let gameWebView else {
            return
        }
        view.addSubview(gameWebView)

        let verticalConstraints: [NSLayoutConstraint]
        if displayMode != .full {
            verticalConstraints = [
                gameWebView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ]
        } else {
            verticalConstraints = [
                gameWebView.topAnchor.constraint(equalTo: view.topAnchor),
                gameWebView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ]
        }

        NSLayoutConstraint.activate(verticalConstraints + [
            gameWebView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gameWebView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
}
