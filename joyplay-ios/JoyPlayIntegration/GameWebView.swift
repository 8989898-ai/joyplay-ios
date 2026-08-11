import UIKit
import WebKit

final class GameWebView: UIView {
    private let displayMode: GameDisplayMode
    private let appKey: String
    private let token: String
    private let aspectRatio: GameAspectRatio?
    private let additionalURLQueryItems: [URLQueryItem]
    private let onEvent: (GameEvent) -> Void
    private let webView = WKWebView()
    private var scriptMessageHandler: WeakScriptMessageHandler?
    private var areScriptMessageHandlersRegistered = false
    private var hasLoadedGame = false

    init(
        displayMode: GameDisplayMode,
        appKey: String,
        token: String,
        aspectRatio: GameAspectRatio? = nil,
        additionalURLQueryItems: [URLQueryItem] = [],
        onEvent: @escaping (GameEvent) -> Void
    ) {
        self.displayMode = displayMode
        self.appKey = appKey
        self.token = token
        self.aspectRatio = aspectRatio
        self.additionalURLQueryItems = additionalURLQueryItems
        self.onEvent = onEvent
        super.init(frame: .zero)
        configureWebView()
        registerScriptMessageHandlers()
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
        guard !hasLoadedGame, let window else {
            return
        }

        let paddingBottom = window.safeAreaInsets.bottom
        guard let url = GameURLBuilder.makeURL(
            appKey: appKey,
            token: token,
            displayMode: displayMode,
            paddingBottom: paddingBottom,
            additionalURLQueryItems: additionalURLQueryItems
        ) else {
            return
        }
        hasLoadedGame = true
        print("打开游戏链接：\(url.absoluteString)")
        webView.load(URLRequest(url: url))
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
