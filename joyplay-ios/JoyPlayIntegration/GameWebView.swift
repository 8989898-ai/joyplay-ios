import UIKit
import WebKit

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

    func stop() {
        guard !isStopped else {
            return
        }
        isStopped = true
        removeScriptMessageHandlers()
        webView.stopLoading()
    }

    func notifyGameBalanceDidChange() {
        webView.evaluateJavaScript(
            GameBridgeScript.balanceRefresh,
            completionHandler: { _, error in
                if error != nil {
                    print("原生通知JS--失败")
                } else {
                    print("原生通知JS--成功")
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
                print("游戏链接追加全屏参数失败")
                return
            }
            loadURL = url
        } else {
            loadURL = gameURL
        }
        hasLoadedGame = true
        print("开始加载游戏")
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
            print("游戏回调：用户下注时余额不足")
        case .recharge:
            print("游戏回调：用户主动点击增加金币")
        case .close:
            print("游戏回调：用户主动关闭游戏")
            stop()
        case .openGameSuccess:
            print("游戏回调：游戏加载成功")
        }

        onEvent(event)
    }
}

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
