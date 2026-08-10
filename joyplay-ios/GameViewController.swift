import UIKit

final class GameViewController: UIViewController {
    private let displayMode: GameDisplayMode
    private let appKey: String
    private let token: String
    private let aspectRatio: GameAspectRatio?
    private lazy var gameWebView = GameWebView(
        displayMode: displayMode,
        appKey: appKey,
        token: token,
        isNativeDemo: true,
        onEvent: { [weak self] event in
            guard event == .close else {
                return
            }
            self?.navigationController?.popViewController(animated: true)
        }
    )

    init(
        displayMode: GameDisplayMode,
        appKey: String,
        token: String,
        aspectRatio: GameAspectRatio? = nil
    ) {
        self.displayMode = displayMode
        self.appKey = appKey
        self.token = token
        self.aspectRatio = aspectRatio
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
            gameWebView.stop()
        }
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    private func configureGameView() {
        gameWebView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gameWebView)

        let verticalConstraints: [NSLayoutConstraint]
        if let aspectRatio {
            verticalConstraints = [
                gameWebView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
                gameWebView.heightAnchor.constraint(
                    equalTo: gameWebView.widthAnchor,
                    multiplier: aspectRatio.heightMultiplier
                )
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
