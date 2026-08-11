import UIKit

final class GameModeSelectionViewController: UIViewController {
    private let backendWidthHeightRatios: [GameDisplayMode: CGFloat] = [
        .half: 1.0,
        .largeHalf: 2.0 / 3.0
    ]
    private var gameData: [DemoGameData] = []

    private lazy var gameButton = DemoGameLaunchButton(title: GameDisplayMode.full.openGameTitle)
    private lazy var fullModeButton = makeModeButton(for: .full)
    private lazy var halfModeButton = makeModeButton(for: .half)
    private lazy var largeHalfModeButton = makeModeButton(for: .largeHalf)
    private lazy var modeButtonStack: UIStackView = {
        let stack = UIStackView(
            arrangedSubviews: [fullModeButton, halfModeButton, largeHalfModeButton]
        )
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let gameData = DemoGameDataSource.makeGameData(
            appKey: GameLaunchCredentials.appKey,
            token: GameLaunchCredentials.token,
            widthHeightRatios: backendWidthHeightRatios
        ) else {
            return
        }
        self.gameData = gameData
        title = String(localized: "game.title", defaultValue: "Game")
        view.backgroundColor = .systemBackground
        configureLayout()
        gameButton.addTarget(self, action: #selector(openFullScreenGame), for: .touchUpInside)
        fullModeButton.isSelected = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fullModeButton.isSelected = true
        halfModeButton.isSelected = false
        largeHalfModeButton.isSelected = false
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        gameButton.startBreathing()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        gameButton.stopBreathing()
    }

    private func configureLayout() {
        view.addSubview(gameButton)
        view.addSubview(modeButtonStack)

        NSLayoutConstraint.activate([
            gameButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            gameButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            gameButton.widthAnchor.constraint(equalToConstant: 160),
            gameButton.heightAnchor.constraint(equalTo: gameButton.widthAnchor),
            modeButtonStack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            modeButtonStack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            modeButtonStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            modeButtonStack.heightAnchor.constraint(equalToConstant: 64)
        ])
    }

    private func makeModeButton(for mode: GameDisplayMode) -> UIButton {
        var configuration = UIButton.Configuration.plain()
        configuration.title = mode.title
        configuration.image = GameModeIcon.make(fillRatio: mode.modeIconFillRatio)
        configuration.imagePlacement = .top
        configuration.imagePadding = 4

        let button = UIButton(configuration: configuration)
        button.tag = GameDisplayMode.allCases.firstIndex(of: mode) ?? 0
        button.addTarget(self, action: #selector(selectMode(_:)), for: .touchUpInside)
        button.configurationUpdateHandler = { button in
            var configuration = button.configuration
            configuration?.baseForegroundColor = button.isSelected
                ? UIColor(named: "AccentColor")
                : .secondaryLabel
            button.configuration = configuration
        }
        return button
    }

    @objc private func openFullScreenGame() {
        guard let selectedGameData = gameData(for: .full) else {
            return
        }

        let fullScreenGameViewController = FullScreenGameViewController(
            gameData: selectedGameData
        )
        navigationController?.pushViewController(fullScreenGameViewController, animated: true)
    }

    @objc private func selectMode(_ sender: UIButton) {
        let modes = GameDisplayMode.allCases
        guard modes.indices.contains(sender.tag) else {
            return
        }

        let displayMode = modes[sender.tag]
        guard displayMode != .full,
              let selectedGameData = gameData(for: displayMode) else {
            return
        }

        let partialGameViewController = PartialGameViewController(
            gameData: selectedGameData
        )
        navigationController?.pushViewController(partialGameViewController, animated: true)
    }

    private func gameData(for displayMode: GameDisplayMode) -> DemoGameData? {
        gameData.first(where: { $0.displayMode == displayMode })
    }
}

private enum GameModeIcon {
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
