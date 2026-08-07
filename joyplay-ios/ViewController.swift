import UIKit

final class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let gameModeTabBarController = GameModeTabBarController(
            appKey: GameLaunchCredentials.appKey,
            token: GameLaunchCredentials.token
        )
        navigationController?.setViewControllers([gameModeTabBarController], animated: false)
    }
}
