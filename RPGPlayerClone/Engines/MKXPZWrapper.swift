import Foundation
import UIKit

protocol MKXPZEngineBridging: AnyObject {
    func makeViewController(gameDirectory: URL) -> UIViewController
    func handleInput(_ event: VirtualGamepadEvent)
    func shutdown()
}

enum MKXPZBridgeRegistry {
    static var bridge: MKXPZEngineBridging? = RuntimeMKXPZBridge.makeIfAvailable()
}

final class MKXPZWrapper: UIViewController {
    private let game: Game
    private let containerView = UIView()
    private let messageLabel = UILabel()
    private let gamepadView = VirtualGamepadView(configuration: .loadFromDefaults())
    private var embeddedController: UIViewController?

    init(game: Game) {
        self.game = game
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupLayout()
        registerObservers()
        startEngine()
    }

    override var prefersStatusBarHidden: Bool {
        true
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        true
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        MKXPZBridgeRegistry.bridge?.shutdown()
    }

    private func setupLayout() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        gamepadView.translatesAutoresizingMaskIntoConstraints = false

        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        messageLabel.textColor = .white
        messageLabel.font = .preferredFont(forTextStyle: .body)
        messageLabel.isHidden = true

        view.addSubview(containerView)
        view.addSubview(messageLabel)
        view.addSubview(gamepadView)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            messageLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            messageLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            messageLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            messageLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24),

            gamepadView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gamepadView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gamepadView.topAnchor.constraint(equalTo: view.topAnchor),
            gamepadView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func startEngine() {
        guard let bridge = MKXPZBridgeRegistry.bridge else {
            showPlaceholder(text: """
            MKXPZ framework chua duoc gan.

            Huong lam de tiep:
            1. Port mkxp-z sang iOS va dong goi thanh XCFramework.
            2. Expose Objective-C class `MKXPZBridge`.
            3. Implement selectors:
               + createViewControllerWithGamePath:
               + sendInputWithButton:pressed:
               + shutdownEngine
            """)
            return
        }

        let child = bridge.makeViewController(gameDirectory: game.path)
        embed(child)
    }

    private func embed(_ child: UIViewController) {
        embeddedController?.willMove(toParent: nil)
        embeddedController?.view.removeFromSuperview()
        embeddedController?.removeFromParent()

        addChild(child)
        child.view.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(child.view)

        NSLayoutConstraint.activate([
            child.view.topAnchor.constraint(equalTo: containerView.topAnchor),
            child.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            child.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            child.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        child.didMove(toParent: self)
        embeddedController = child
        messageLabel.isHidden = true
    }

    private func showPlaceholder(text: String) {
        messageLabel.text = text
        messageLabel.isHidden = false
    }

    private func registerObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleVirtualInput(_:)),
            name: .virtualGamepadEventDidChange,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleShutdown),
            name: .engineShouldTerminate,
            object: nil
        )
    }

    @objc private func handleVirtualInput(_ notification: Notification) {
        guard let event = notification.userInfo?[VirtualGamepadEvent.notificationUserInfoKey] as? VirtualGamepadEvent else {
            return
        }

        MKXPZBridgeRegistry.bridge?.handleInput(event)
    }

    @objc private func handleShutdown() {
        MKXPZBridgeRegistry.bridge?.shutdown()
    }
}
