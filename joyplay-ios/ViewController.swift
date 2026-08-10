import UIKit

final class ViewController: UIViewController {
    private let backendWidthHeightRatios: [GameDisplayMode: CGFloat] = [
        .half: 1.0,
        .largeHalf: 2.0 / 3.0
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        let aspectRatios = backendWidthHeightRatios.compactMapValues {
            GameAspectRatio(widthHeightRatio: $0)
        }
        let gameModeTabBarController = GameModeTabBarController(
            appKey: GameLaunchCredentials.appKey,
            token: GameLaunchCredentials.token,
            aspectRatios: aspectRatios
        )
        navigationController?.setViewControllers([gameModeTabBarController], animated: false)
    }
}
