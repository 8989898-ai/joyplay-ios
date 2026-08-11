import UIKit

final class DemoGameLaunchButton: UIButton {
    init(title: String) {
        var configuration = UIButton.Configuration.filled()
        configuration.title = title
        configuration.baseBackgroundColor = UIColor(named: "AccentColor")
        configuration.cornerStyle = .capsule
        configuration.titleAlignment = .center
        configuration.contentInsets = NSDirectionalEdgeInsets(
            top: 14,
            leading: 28,
            bottom: 14,
            trailing: 28
        )
        super.init(frame: .zero)
        self.configuration = configuration
        titleLabel?.numberOfLines = 0
        translatesAutoresizingMaskIntoConstraints = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func startBreathing() {
        guard !isHidden, !UIAccessibility.isReduceMotionEnabled else {
            stopBreathing()
            return
        }
        layer.removeAllAnimations()
        transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
        UIView.animate(
            withDuration: 0.6,
            delay: 0,
            options: [.curveEaseInOut, .autoreverse, .repeat, .allowUserInteraction]
        ) { [weak self] in
            self?.transform = CGAffineTransform(scaleX: 1.04, y: 1.04)
        }
    }

    func stopBreathing() {
        layer.removeAllAnimations()
        transform = .identity
    }
}
