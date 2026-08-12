import UIKit
import WebKit

/// The single host-facing view for loading, laying out, and observing a JoyPlay game.
final class GameWebView: UIView {
    private let gameURL: URL
    private let displayMode: GameDisplayMode
    private let aspectRatio: GameAspectRatio?
    private let onEvent: (GameEvent) -> Void
    private let webView = WKWebView()
    private var scriptMessageHandler: WeakScriptMessageHandler?
    private var areScriptMessageHandlersRegistered = false
    private var hasLoadedGame = false
    private var isStopped = false

    /// Creates a game view from a complete backend URL and the backend's original ratio.
    ///
    /// Full screen requires no ratio. Embedded modes require a finite, positive
    /// width-divided-by-height ratio. Initialization also fails for non-HTTPS URLs,
    /// missing hosts, or URLs that already contain `safeTop` or `paddingBottom`.
    init?(
        gameURL: URL,
        displayMode: GameDisplayMode,
        widthHeightRatio: CGFloat? = nil,
        onEvent: @escaping (GameEvent) -> Void
    ) {
        guard GameURLRuntimeAdapter.isValidBackendGameURL(gameURL) else {
            return nil
        }

        let aspectRatio: GameAspectRatio?
        switch displayMode {
        case .full:
            guard widthHeightRatio == nil else {
                return nil
            }
            aspectRatio = nil
        case .half, .largeHalf:
            guard let widthHeightRatio,
                  let validatedAspectRatio = GameAspectRatio(
                      widthHeightRatio: widthHeightRatio
                  ) else {
                return nil
            }
            aspectRatio = validatedAspectRatio
        }

        self.gameURL = gameURL
        self.displayMode = displayMode
        self.aspectRatio = aspectRatio
        self.onEvent = onEvent
        super.init(frame: .zero)
        self.translatesAutoresizingMaskIntoConstraints = false
        configureWebView()
        registerScriptMessageHandlers()
    }

    deinit {
        stop()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        loadGameIfNeeded()
    }

    /// Adds the game view to a host container and installs the mode-specific outer constraints.
    ///
    /// The host should not call `addSubview` or create constraints for this view separately.
    func attach(to containerView: UIView) {
        containerView.addSubview(self)

        var constraints = [
            leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ]
        if displayMode == .full {
            constraints.append(
                topAnchor.constraint(equalTo: containerView.topAnchor)
            )
        }
        NSLayoutConstraint.activate(constraints)
    }

    /// Stops loading and unregisters all H5 message handlers.
    ///
    /// Call this before the host actively removes the game. Repeated calls are safe.
    func stop() {
        guard !isStopped else {
            return
        }
        isStopped = true
        removeScriptMessageHandlers()
        webView.stopLoading()
    }

    /// Notifies H5 to refresh the player's balance after a successful host-side recharge.
    func notifyGameBalanceDidChange() {
        webView.evaluateJavaScript(
            GameBridgeScript.balanceRefresh,
            completionHandler: { _, error in
                if error != nil {
                    print("Failed to notify the game of the balance change")
                } else {
                    print("Notified the game of the balance change")
                }
            }
        )
    }

    private func configureWebView() {
        if displayMode != .full {
            backgroundColor = .black
        }
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(webView)

        var constraints = [
            webView.topAnchor.constraint(equalTo: topAnchor),
            webView.leadingAnchor.constraint(equalTo: leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ]
        if displayMode != .full, let aspectRatio {
            constraints += [
                webView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
                webView.heightAnchor.constraint(
                    equalTo: webView.widthAnchor,
                    multiplier: aspectRatio.heightMultiplier
                )
            ]
        } else {
            constraints.append(webView.bottomAnchor.constraint(equalTo: bottomAnchor))
        }
        NSLayoutConstraint.activate(constraints)
    }

    private func loadGameIfNeeded() {
        guard !hasLoadedGame, !isStopped, let window else {
            return
        }

        let loadURL: URL
        if displayMode == .full {
            guard let url = GameURLRuntimeAdapter.appendingFullScreenParameters(
                paddingBottom: window.safeAreaInsets.bottom,
                to: gameURL
            ) else {
                print("Failed to append full-screen parameters to the game URL")
                return
            }
            loadURL = url
        } else {
            loadURL = gameURL
        }
        hasLoadedGame = true
        print("Loading game")
        webView.load(URLRequest(url: loadURL))
    }

    private func registerScriptMessageHandlers() {
        guard !areScriptMessageHandlersRegistered else {
            return
        }

        let scriptMessageHandler = WeakScriptMessageHandler(delegate: self)
        for event in GameEvent.allCases {
            webView.configuration.userContentController.add(
                scriptMessageHandler,
                name: event.rawValue
            )
        }
        self.scriptMessageHandler = scriptMessageHandler
        areScriptMessageHandlersRegistered = true
    }

    private func removeScriptMessageHandlers() {
        guard areScriptMessageHandlersRegistered else {
            return
        }

        for event in GameEvent.allCases {
            webView.configuration.userContentController.removeScriptMessageHandler(forName: event.rawValue)
        }
        scriptMessageHandler = nil
        areScriptMessageHandlersRegistered = false
    }
}

extension GameWebView: WKScriptMessageHandler {
    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard let event = GameEvent(rawValue: message.name) else {
            return
        }

        switch event {
        case .insufficientBalance:
            print("Game callback: insufficient balance")
        case .recharge:
            print("Game callback: recharge requested")
        case .close:
            print("Game callback: close requested")
            stop()
        case .openGameSuccess:
            print("Game callback: game opened successfully")
        }

        onEvent(event)
    }
}

/// Breaks the retain cycle otherwise created by `WKUserContentController` retaining its handler.
private final class WeakScriptMessageHandler: NSObject, WKScriptMessageHandler {
    private weak var delegate: WKScriptMessageHandler?

    init(delegate: WKScriptMessageHandler) {
        self.delegate = delegate
    }

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        delegate?.userContentController(userContentController, didReceive: message)
    }
}
