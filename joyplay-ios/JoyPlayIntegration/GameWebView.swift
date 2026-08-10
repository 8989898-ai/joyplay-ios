import UIKit
import WebKit

final class GameWebView: UIView {
    private let displayMode: GameDisplayMode
    private let appKey: String
    private let token: String
    private let isNativeDemo: Bool
    private let automaticallyShowsRechargePrompt: Bool
    private let onEvent: (GameEvent) -> Void
    private let webView = WKWebView()
    private var scriptMessageHandler: WeakScriptMessageHandler?
    private var areScriptMessageHandlersRegistered = false
    private var hasLoadedGame = false

    init(
        displayMode: GameDisplayMode,
        appKey: String,
        token: String,
        isNativeDemo: Bool = false,
        automaticallyShowsRechargePrompt: Bool = true,
        onEvent: @escaping (GameEvent) -> Void
    ) {
        self.displayMode = displayMode
        self.appKey = appKey
        self.token = token
        self.isNativeDemo = isNativeDemo
        self.automaticallyShowsRechargePrompt = automaticallyShowsRechargePrompt
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
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: topAnchor),
            webView.leadingAnchor.constraint(equalTo: leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
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
            isNativeDemo: isNativeDemo
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

    private func showRechargePrompt() {
        let alertController = UIAlertController(
            title: nil,
            message: GameRechargePrompt.message,
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(
            title: GameRechargePrompt.notRechargedTitle,
            style: .cancel
        ))
        alertController.addAction(UIAlertAction(
            title: GameRechargePrompt.notifyGameTitle,
            style: .default,
            handler: { [weak self] _ in
                self?.notifyGameBalanceDidChange()
            }
        ))
        hostingViewController?.present(alertController, animated: true)
    }

    private var hostingViewController: UIViewController? {
        var responder: UIResponder? = self
        while let currentResponder = responder {
            if let viewController = currentResponder as? UIViewController {
                return viewController
            }
            responder = currentResponder.next
        }
        return nil
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

        if automaticallyShowsRechargePrompt && event.showsRechargePrompt {
            showRechargePrompt()
        }
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
