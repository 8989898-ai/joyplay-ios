import UIKit

/// Presents Demo-only recharge UI; integrating apps provide their own localized recharge flow.
enum DemoRechargePromptPresenter {
    static func present(
        from viewController: UIViewController,
        onNotifyGame: @escaping () -> Void
    ) {
        let alertController = UIAlertController(
            title: nil,
            message: String(
                localized: "game.recharge_prompt.message",
                defaultValue: "Please show the app's recharge screen. After the player recharges successfully, call the JS method from native code to notify the game to refresh the player's balance."
            ),
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(
            title: String(
                localized: "game.recharge_prompt.not_recharged",
                defaultValue: "Not Recharged"
            ),
            style: .cancel
        ))
        alertController.addAction(UIAlertAction(
            title: String(
                localized: "game.recharge_prompt.notify_game",
                defaultValue: "Notify Game"
            ),
            style: .default,
            handler: { _ in
                onNotifyGame()
            }
        ))
        viewController.present(alertController, animated: true)
    }
}
