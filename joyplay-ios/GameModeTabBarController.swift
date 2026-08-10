import UIKit

final class GameModeTabBarController: UITabBarController {
    private let appKey: String
    private let token: String
    private let aspectRatios: [GameDisplayMode: GameAspectRatio]
    private lazy var modeTabsBackButton: UIBarButtonItem = {
        let button = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(showFullModeTab)
        )
        button.accessibilityLabel = String(localized: "common.back", defaultValue: "Back")
        return button
    }()

    init(
        appKey: String,
        token: String,
        aspectRatios: [GameDisplayMode: GameAspectRatio]
    ) {
        self.appKey = appKey
        self.token = token
        self.aspectRatios = aspectRatios
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = String(localized: "game.title", defaultValue: "Game")
        delegate = self
        viewControllers = GameDisplayMode.allCases.map { mode in
            let viewController = GameModeLaunchViewController(
                displayMode: mode,
                appKey: appKey,
                token: token,
                aspectRatio: aspectRatios[mode]
            )
            viewController.tabBarItem = UITabBarItem(
                title: mode.title,
                image: GameModeTabIcon.make(fillRatio: mode.tabIconFillRatio),
                selectedImage: nil
            )
            return viewController
        }
        updateBackButton()
    }

    @objc private func showFullModeTab() {
        guard selectedDisplayMode?.backDestination == .fullModeTab else {
            return
        }

        (selectedViewController as? GameModeLaunchViewController)?.removeEmbeddedGameIfNeeded()
        selectedIndex = 0
        tabBar.isHidden = false
        updateBackButton()
    }

    private var selectedDisplayMode: GameDisplayMode? {
        let displayModes = GameDisplayMode.allCases
        guard displayModes.indices.contains(selectedIndex) else {
            return nil
        }
        return displayModes[selectedIndex]
    }

    private func updateBackButton() {
        navigationItem.leftBarButtonItem = selectedDisplayMode?.backDestination == .fullModeTab
            ? modeTabsBackButton
            : nil
    }
}

private enum GameModeTabIcon {
    private static let size = CGSize(width: 25, height: 22)

    static func make(fillRatio: CGFloat) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let screenRect = CGRect(x: 2, y: 2, width: 21, height: 18)
            let screenPath = UIBezierPath(roundedRect: screenRect, cornerRadius: 3)
            screenPath.lineWidth = 1.75

            UIColor.black.setStroke()
            screenPath.stroke()

            let contentRect = screenRect.insetBy(dx: 3, dy: 3)
            let fillHeight = contentRect.height * min(max(fillRatio, 0), 1)
            let fillRect = CGRect(
                x: contentRect.minX,
                y: contentRect.maxY - fillHeight,
                width: contentRect.width,
                height: fillHeight
            )

            context.cgContext.saveGState()
            screenPath.addClip()
            UIColor.black.setFill()
            context.fill(fillRect)
            context.cgContext.restoreGState()
        }
        .withRenderingMode(.alwaysTemplate)
    }
}

extension GameModeTabBarController: UITabBarControllerDelegate {
    func tabBarController(
        _ tabBarController: UITabBarController,
        didSelect viewController: UIViewController
    ) {
        guard let selectedDisplayMode else {
            return
        }
        tabBar.isHidden = selectedDisplayMode.hidesModeTabBar
        updateBackButton()
    }
}

private final class GameModeLaunchViewController: UIViewController {
    private let displayMode: GameDisplayMode
    private let appKey: String
    private let token: String
    private let aspectRatio: GameAspectRatio?
    private var embeddedGameView: GameWebView?

    private lazy var backgroundImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: displayMode.backgroundImageName))
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()

    private let gameButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.title = String(localized: "game.title", defaultValue: "Game")
        configuration.baseBackgroundColor = UIColor(named: "AccentColor")
        configuration.cornerStyle = .capsule
        configuration.titleAlignment = .center
        configuration.contentInsets = NSDirectionalEdgeInsets(
            top: 14,
            leading: 28,
            bottom: 14,
            trailing: 28
        )
        let button = UIButton(configuration: configuration)
        button.titleLabel?.numberOfLines = 0
        return button
    }()

    init(
        displayMode: GameDisplayMode,
        appKey: String,
        token: String,
        aspectRatio: GameAspectRatio?
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
        view.backgroundColor = .systemBackground
        switch displayMode {
        case .full:
            gameButton.configuration?.title = String(
                localized: "game.open.full",
                defaultValue: "Open Full-Screen Game"
            )
        case .half:
            gameButton.configuration?.title = String(
                localized: "game.open.half",
                defaultValue: "Open Half-Screen Game"
            )
        case .sevenTenths:
            gameButton.configuration?.title = String(
                localized: "game.open.seven_tenths",
                defaultValue: "Open Large Half-Screen Game"
            )
        }
        configureLayout()
        gameButton.addTarget(self, action: #selector(openGame), for: .touchUpInside)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startGameButtonBreathing()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopGameButtonBreathing()
    }

    private func configureLayout() {
        backgroundImageView.isHidden = !displayMode.usesGameBackground
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        gameButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backgroundImageView)
        view.addSubview(gameButton)

        var constraints = [
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ]

        constraints += [
            gameButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            gameButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            gameButton.widthAnchor.constraint(equalToConstant: 160),
            gameButton.heightAnchor.constraint(equalTo: gameButton.widthAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    @objc private func openGame() {
        switch displayMode.launchPresentation {
        case .pushed:
            stopGameButtonBreathing()
            let gameViewController = GameViewController(
                displayMode: displayMode,
                appKey: appKey,
                token: token,
                aspectRatio: aspectRatio
            )
            gameViewController.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(gameViewController, animated: true)
        case .embedded:
            embedGame()
        }
    }

    private func embedGame() {
        guard embeddedGameView == nil,
              let aspectRatio else {
            return
        }

        stopGameButtonBreathing()
        let gameWebView = GameWebView(
            displayMode: displayMode,
            appKey: appKey,
            token: token,
            isNativeDemo: true,
            onEvent: { [weak self] event in
                guard event == .close else {
                    return
                }
                self?.removeEmbeddedGame()
            }
        )
        gameWebView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gameWebView)
        NSLayoutConstraint.activate([
            gameWebView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gameWebView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gameWebView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            gameWebView.heightAnchor.constraint(
                equalTo: gameWebView.widthAnchor,
                multiplier: aspectRatio.heightMultiplier
            )
        ])
        embeddedGameView = gameWebView
        gameButton.isHidden = true
    }

    private func removeEmbeddedGame() {
        guard let gameWebView = embeddedGameView else {
            return
        }

        gameWebView.stop()
        gameWebView.removeFromSuperview()
        embeddedGameView = nil
        gameButton.isHidden = false
        startGameButtonBreathing()
    }

    func removeEmbeddedGameIfNeeded() {
        removeEmbeddedGame()
    }

    private func startGameButtonBreathing() {
        guard !gameButton.isHidden, !UIAccessibility.isReduceMotionEnabled else {
            stopGameButtonBreathing()
            return
        }

        gameButton.layer.removeAllAnimations()
        gameButton.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
        UIView.animate(
            withDuration: 0.6,
            delay: 0,
            options: [.curveEaseInOut, .autoreverse, .repeat, .allowUserInteraction]
        ) { [weak self] in
            self?.gameButton.transform = CGAffineTransform(scaleX: 1.04, y: 1.04)
        }
    }

    private func stopGameButtonBreathing() {
        gameButton.layer.removeAllAnimations()
        gameButton.transform = .identity
    }
}
