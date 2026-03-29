import Foundation
import UIKit

@objc private protocol EasyRPGNativeBridgeFactory {
    @objc(createViewControllerWithGamePath:)
    static func createViewController(withGamePath path: NSString) -> UIViewController?

    @objc(sendInputWithButton:pressed:)
    static func sendInput(button: NSString, pressed: Bool)

    @objc(shutdownEngine)
    static func shutdownEngine()
}

@objc private protocol MKXPZNativeBridgeFactory {
    @objc(createViewControllerWithGamePath:)
    static func createViewController(withGamePath path: NSString) -> UIViewController?

    @objc(sendInputWithButton:pressed:)
    static func sendInput(button: NSString, pressed: Bool)

    @objc(shutdownEngine)
    static func shutdownEngine()
}

private final class NativeBridgeFailureViewController: UIViewController {
    private let message: String

    init(message: String) {
        self.message = message
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = .white
        label.text = message

        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            label.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24)
        ])
    }
}

final class RuntimeEasyRPGBridge: EasyRPGEngineBridging {
    private let factory: EasyRPGNativeBridgeFactory.Type

    private init(factory: EasyRPGNativeBridgeFactory.Type) {
        self.factory = factory
    }

    static func makeIfAvailable() -> EasyRPGEngineBridging? {
        let candidates = [
            "EasyRPGBridge",
            "RPGPlayerClone.EasyRPGBridge",
            "EasyRPGBridge.EasyRPGBridge"
        ]

        guard let factory = candidates
            .lazy
            .compactMap({ NSClassFromString($0) as? EasyRPGNativeBridgeFactory.Type })
            .first else {
            return nil
        }

        return RuntimeEasyRPGBridge(factory: factory)
    }

    func makeViewController(gameDirectory: URL) -> UIViewController {
        factory.createViewController(withGamePath: gameDirectory.path as NSString) ?? NativeBridgeFailureViewController(
            message: "EasyRPGBridge da duoc nap nhung khong tao duoc UIViewController."
        )
    }

    func handleInput(_ event: VirtualGamepadEvent) {
        factory.sendInput(button: event.button.rawValue as NSString, pressed: event.isPressed)
    }

    func shutdown() {
        factory.shutdownEngine()
    }
}

final class RuntimeMKXPZBridge: MKXPZEngineBridging {
    private let factory: MKXPZNativeBridgeFactory.Type

    private init(factory: MKXPZNativeBridgeFactory.Type) {
        self.factory = factory
    }

    static func makeIfAvailable() -> MKXPZEngineBridging? {
        let candidates = [
            "MKXPZBridge",
            "RPGPlayerClone.MKXPZBridge",
            "MKXPZBridge.MKXPZBridge"
        ]

        guard let factory = candidates
            .lazy
            .compactMap({ NSClassFromString($0) as? MKXPZNativeBridgeFactory.Type })
            .first else {
            return nil
        }

        return RuntimeMKXPZBridge(factory: factory)
    }

    func makeViewController(gameDirectory: URL) -> UIViewController {
        factory.createViewController(withGamePath: gameDirectory.path as NSString) ?? NativeBridgeFailureViewController(
            message: "MKXPZBridge da duoc nap nhung khong tao duoc UIViewController."
        )
    }

    func handleInput(_ event: VirtualGamepadEvent) {
        factory.sendInput(button: event.button.rawValue as NSString, pressed: event.isPressed)
    }

    func shutdown() {
        factory.shutdownEngine()
    }
}
