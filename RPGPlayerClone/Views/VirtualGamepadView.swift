import Foundation
import UIKit

enum VirtualGamepadButton: String, CaseIterable, Codable {
    case up
    case down
    case left
    case right
    case a
    case b
    case x
    case y
    case l
    case r
    case start
    case select
}

struct VirtualGamepadEvent: Hashable {
    static let notificationUserInfoKey = "VirtualGamepadEvent"

    let button: VirtualGamepadButton
    let isPressed: Bool
}

protocol VirtualGamepadViewDelegate: AnyObject {
    func virtualGamepadView(_ view: VirtualGamepadView, didEmit event: VirtualGamepadEvent)
}

extension Notification.Name {
    static let virtualGamepadEventDidChange = Notification.Name("RPGPlayerClone.virtualGamepadEventDidChange")
}

final class VirtualGamepadView: UIView {
    struct Configuration {
        var isVisible: Bool = true
        var buttonDiameter: CGFloat = 64
        var dPadButtonSize: CGFloat = 58
        var shoulderButtonWidth: CGFloat = 72
        var opacity: CGFloat = 0.78

        static func loadFromDefaults() -> Configuration {
            let defaults = UserDefaults.standard
            var config = Configuration()

            if let value = defaults.object(forKey: "settings.virtualGamepadEnabled") as? Bool {
                config.isVisible = value
            }

            if let value = defaults.object(forKey: "settings.virtualGamepadOpacity") as? Double {
                config.opacity = CGFloat(value)
            }

            if (defaults.string(forKey: "settings.virtualGamepadLayout") ?? "standard") == "compact" {
                config.buttonDiameter = 56
                config.dPadButtonSize = 52
                config.shoulderButtonWidth = 64
            }

            return config
        }
    }

    weak var delegate: VirtualGamepadViewDelegate?

    private var configuration: Configuration
    private var buttonMap: [ObjectIdentifier: VirtualGamepadButton] = [:]

    private let dPadContainer = UIView()
    private let actionContainer = UIView()
    private let shoulderContainer = UIStackView()

    init(configuration: Configuration) {
        self.configuration = configuration
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        isUserInteractionEnabled = configuration.isVisible
        isHidden = !configuration.isVisible
        alpha = configuration.opacity
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func apply(configuration: Configuration) {
        self.configuration = configuration
        isHidden = !configuration.isVisible
        isUserInteractionEnabled = configuration.isVisible
        alpha = configuration.opacity
    }

    private func setupViews() {
        setupShoulders()
        setupDPad()
        setupActionButtons()
    }

    private func setupShoulders() {
        shoulderContainer.axis = .horizontal
        shoulderContainer.alignment = .center
        shoulderContainer.distribution = .equalSpacing
        shoulderContainer.translatesAutoresizingMaskIntoConstraints = false

        let lButton = makeButton(title: "L", size: CGSize(width: configuration.shoulderButtonWidth, height: 40), mappedTo: .l)
        let selectButton = makeButton(title: "Select", size: CGSize(width: 72, height: 36), mappedTo: .select)
        let startButton = makeButton(title: "Start", size: CGSize(width: 72, height: 36), mappedTo: .start)
        let rButton = makeButton(title: "R", size: CGSize(width: configuration.shoulderButtonWidth, height: 40), mappedTo: .r)

        [lButton, UIView(), selectButton, startButton, UIView(), rButton].forEach { view in
            shoulderContainer.addArrangedSubview(view)
        }

        addSubview(shoulderContainer)

        NSLayoutConstraint.activate([
            shoulderContainer.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 10),
            shoulderContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            shoulderContainer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16)
        ])
    }

    private func setupDPad() {
        dPadContainer.translatesAutoresizingMaskIntoConstraints = false
        addSubview(dPadContainer)

        let up = makeButton(title: "Up", size: squareSize(configuration.dPadButtonSize), mappedTo: .up)
        let down = makeButton(title: "Dn", size: squareSize(configuration.dPadButtonSize), mappedTo: .down)
        let left = makeButton(title: "Lt", size: squareSize(configuration.dPadButtonSize), mappedTo: .left)
        let right = makeButton(title: "Rt", size: squareSize(configuration.dPadButtonSize), mappedTo: .right)
        let center = UIView()

        [up, down, left, right, center].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            dPadContainer.addSubview($0)
        }

        NSLayoutConstraint.activate([
            dPadContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            dPadContainer.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -20),
            dPadContainer.widthAnchor.constraint(equalToConstant: configuration.dPadButtonSize * 3),
            dPadContainer.heightAnchor.constraint(equalToConstant: configuration.dPadButtonSize * 3),

            center.centerXAnchor.constraint(equalTo: dPadContainer.centerXAnchor),
            center.centerYAnchor.constraint(equalTo: dPadContainer.centerYAnchor),
            center.widthAnchor.constraint(equalToConstant: configuration.dPadButtonSize),
            center.heightAnchor.constraint(equalToConstant: configuration.dPadButtonSize),

            up.centerXAnchor.constraint(equalTo: center.centerXAnchor),
            up.bottomAnchor.constraint(equalTo: center.topAnchor),

            down.centerXAnchor.constraint(equalTo: center.centerXAnchor),
            down.topAnchor.constraint(equalTo: center.bottomAnchor),

            left.trailingAnchor.constraint(equalTo: center.leadingAnchor),
            left.centerYAnchor.constraint(equalTo: center.centerYAnchor),

            right.leadingAnchor.constraint(equalTo: center.trailingAnchor),
            right.centerYAnchor.constraint(equalTo: center.centerYAnchor)
        ])
    }

    private func setupActionButtons() {
        actionContainer.translatesAutoresizingMaskIntoConstraints = false
        addSubview(actionContainer)

        let a = makeButton(title: "A", size: squareSize(configuration.buttonDiameter), mappedTo: .a)
        let b = makeButton(title: "B", size: squareSize(configuration.buttonDiameter), mappedTo: .b)
        let x = makeButton(title: "X", size: squareSize(configuration.buttonDiameter), mappedTo: .x)
        let y = makeButton(title: "Y", size: squareSize(configuration.buttonDiameter), mappedTo: .y)

        [a, b, x, y].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            actionContainer.addSubview($0)
        }

        NSLayoutConstraint.activate([
            actionContainer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            actionContainer.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -24),
            actionContainer.widthAnchor.constraint(equalToConstant: configuration.buttonDiameter * 2.6),
            actionContainer.heightAnchor.constraint(equalToConstant: configuration.buttonDiameter * 2.6),

            a.centerXAnchor.constraint(equalTo: actionContainer.centerXAnchor),
            a.bottomAnchor.constraint(equalTo: actionContainer.bottomAnchor),

            b.trailingAnchor.constraint(equalTo: actionContainer.trailingAnchor),
            b.centerYAnchor.constraint(equalTo: actionContainer.centerYAnchor),

            x.leadingAnchor.constraint(equalTo: actionContainer.leadingAnchor),
            x.centerYAnchor.constraint(equalTo: actionContainer.centerYAnchor),

            y.centerXAnchor.constraint(equalTo: actionContainer.centerXAnchor),
            y.topAnchor.constraint(equalTo: actionContainer.topAnchor)
        ])
    }

    private func squareSize(_ value: CGFloat) -> CGSize {
        CGSize(width: value, height: value)
    }

    private func makeButton(title: String, size: CGSize, mappedTo mappedButton: VirtualGamepadButton) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false

        var config = UIButton.Configuration.filled()
        config.title = title
        config.cornerStyle = .capsule
        config.baseForegroundColor = .white
        config.baseBackgroundColor = UIColor.darkGray.withAlphaComponent(0.88)
        config.background.strokeColor = .white.withAlphaComponent(0.15)
        config.background.strokeWidth = 1
        button.configuration = config

        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: size.width),
            button.heightAnchor.constraint(equalToConstant: size.height)
        ])

        let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(handlePress(_:)))
        recognizer.minimumPressDuration = 0
        recognizer.cancelsTouchesInView = false
        button.addGestureRecognizer(recognizer)

        buttonMap[ObjectIdentifier(button)] = mappedButton
        return button
    }

    @objc private func handlePress(_ recognizer: UILongPressGestureRecognizer) {
        guard let button = recognizer.view as? UIButton,
              let mapped = buttonMap[ObjectIdentifier(button)] else {
            return
        }

        switch recognizer.state {
        case .began:
            button.transform = CGAffineTransform(scaleX: 0.94, y: 0.94)
            emit(mapped, isPressed: true)
        case .ended, .cancelled, .failed:
            button.transform = .identity
            emit(mapped, isPressed: false)
        default:
            break
        }
    }

    private func emit(_ button: VirtualGamepadButton, isPressed: Bool) {
        let event = VirtualGamepadEvent(button: button, isPressed: isPressed)
        delegate?.virtualGamepadView(self, didEmit: event)
        GameInputDispatcher.post(event, source: self)
    }
}
