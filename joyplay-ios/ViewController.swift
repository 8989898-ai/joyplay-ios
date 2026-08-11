import UIKit

final class ViewController: UIViewController {
    private let backendWidthHeightRatios: [GameDisplayMode: CGFloat] = [
        .half: 1.0,
        .largeHalf: 2.0 / 3.0
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        let gameModeSelectionViewController = GameModeSelectionViewController(
            appKey: GameLaunchCredentials.appKey,
            token: GameLaunchCredentials.token,
            widthHeightRatios: backendWidthHeightRatios
        )
        navigationController?.setViewControllers([gameModeSelectionViewController], animated: false)
    }
}
