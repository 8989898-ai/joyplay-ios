import UIKit
import WebKit

final class GameWebView: UIView {
    private let onClose: () -> Void
    private let webView = WKWebView()
    private var scriptMessageHandler: WeakScriptMessageHandler?
    private var areScriptMessageHandlersRegistered = false

    init(
        displayMode: GameDisplayMode,
        appKey: String,
        token: String,
        onClose: @escaping () -> Void
    ) {
        self.onClose = onClose
        super.init(frame: .zero)
        configureWebView()
        registerScriptMessageHandlers()
        loadGame(displayMode: displayMode, appKey: appKey, token: token)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func stop() {
        removeScriptMessageHandlers()
        webView.stopLoading()
    }

    private func configureWebView() {
        let closeForwarder = WKUserScript(
            source: GameBridgeScript.experienceLinkCloseForwarder,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
        webView.configuration.userContentController.addUserScript(closeForwarder)

        webView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: topAnchor),
            webView.leadingAnchor.constraint(equalTo: leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func loadGame(displayMode: GameDisplayMode, appKey: String, token: String) {
        guard let url = GameURLBuilder.makeURL(
            appKey: appKey,
            token: token,
            displayMode: displayMode
        ) else {
            return
        }
        print("打开游戏链接：\(url.absoluteString)")
        webView.load(URLRequest(url: url))
    }

    private func registerScriptMessageHandlers() {
        guard !areScriptMessageHandlersRegistered else {
            return
        }

        let scriptMessageHandler = WeakScriptMessageHandler(delegate: self)
        for message in GameScriptMessage.allCases {
            webView.configuration.userContentController.add(
                scriptMessageHandler,
                name: message.rawValue
            )
        }
        self.scriptMessageHandler = scriptMessageHandler
        areScriptMessageHandlersRegistered = true
    }

    private func removeScriptMessageHandlers() {
        guard areScriptMessageHandlersRegistered else {
            return
        }

        for message in GameScriptMessage.allCases {
            webView.configuration.userContentController.removeScriptMessageHandler(forName: message.rawValue)
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
        guard let scriptMessage = GameScriptMessage(rawValue: message.name) else {
            return
        }

        switch scriptMessage {
        case .insufficientBalance:
            print("游戏回调：用户下注时余额不足")
        case .recharge:
            print("游戏回调：用户主动点击增加金币")
        case .close:
            print("游戏回调：用户主动关闭游戏")
            stop()
            onClose()
        case .openGameSuccess:
            print("游戏回调：游戏加载成功")
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
