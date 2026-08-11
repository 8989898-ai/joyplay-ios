import UIKit

final class FullScreenGameViewController: UIViewController {
    private let gameURL: URL
    private lazy var gameWebView: GameWebView? = GameWebView(
        gameURL: gameURL,
        displayMode: .full,
        onEvent: { [weak self] event in
            self?.handleGameEvent(event)
        }
    )

    init(gameURL: URL) {
        self.gameURL = gameURL
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = GameDisplayMode.full.title
        view.backgroundColor = .systemBackground
        configureGameView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
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

        NSLayoutConstraint.activate([
            gameWebView.topAnchor.constraint(equalTo: view.topAnchor),
            gameWebView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gameWebView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gameWebView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}
