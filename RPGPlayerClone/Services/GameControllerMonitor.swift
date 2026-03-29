import Foundation
import GameController

final class GameControllerMonitor: NSObject {
    static let shared = GameControllerMonitor()

    private var isStarted = false
    private var controllerStates: [ObjectIdentifier: Set<VirtualGamepadButton>] = [:]

    private override init() {
        super.init()
    }

    func start() {
        guard !isStarted else {
            return
        }

        isStarted = true

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleControllerDidConnect(_:)),
            name: NSNotification.Name.GCControllerDidConnect,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleControllerDidDisconnect(_:)),
            name: NSNotification.Name.GCControllerDidDisconnect,
            object: nil
        )

        GCController.controllers().forEach(register)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func handleControllerDidConnect(_ notification: Notification) {
        guard let controller = notification.object as? GCController else {
            return
        }

        register(controller)
    }

    @objc private func handleControllerDidDisconnect(_ notification: Notification) {
        guard let controller = notification.object as? GCController else {
            return
        }

        unregister(controller)
    }

    private func register(_ controller: GCController) {
        guard let gamepad = controller.extendedGamepad else {
            return
        }

        let identifier = ObjectIdentifier(controller)
        controllerStates[identifier] = snapshot(for: gamepad)

        gamepad.valueChangedHandler = { [weak self, weak controller] _, _ in
            guard let self, let controller else {
                return
            }

            DispatchQueue.main.async {
                self.syncState(for: controller)
            }
        }

        controller.controllerPausedHandler = { [weak self] _ in
            self?.emitPulse(for: .start)
        }
    }

    private func unregister(_ controller: GCController) {
        let identifier = ObjectIdentifier(controller)
        let previouslyPressed = controllerStates.removeValue(forKey: identifier) ?? []

        controller.extendedGamepad?.valueChangedHandler = nil
        controller.controllerPausedHandler = nil

        for button in previouslyPressed.sorted(by: buttonSortOrder) {
            GameInputDispatcher.post(.init(button: button, isPressed: false), source: controller)
        }
    }

    private func syncState(for controller: GCController) {
        guard let gamepad = controller.extendedGamepad else {
            unregister(controller)
            return
        }

        let identifier = ObjectIdentifier(controller)
        let previous = controllerStates[identifier] ?? []
        let current = snapshot(for: gamepad)

        let released = previous.subtracting(current).sorted(by: buttonSortOrder)
        let pressed = current.subtracting(previous).sorted(by: buttonSortOrder)

        for button in released {
            GameInputDispatcher.post(.init(button: button, isPressed: false), source: controller)
        }

        for button in pressed {
            GameInputDispatcher.post(.init(button: button, isPressed: true), source: controller)
        }

        controllerStates[identifier] = current
    }

    private func snapshot(for gamepad: GCExtendedGamepad) -> Set<VirtualGamepadButton> {
        var pressedButtons = Set<VirtualGamepadButton>()

        if gamepad.buttonA.isPressed {
            pressedButtons.insert(.a)
        }
        if gamepad.buttonB.isPressed {
            pressedButtons.insert(.b)
        }
        if gamepad.buttonX.isPressed {
            pressedButtons.insert(.x)
        }
        if gamepad.buttonY.isPressed {
            pressedButtons.insert(.y)
        }
        if gamepad.leftShoulder.isPressed || gamepad.leftTrigger.isPressed {
            pressedButtons.insert(.l)
        }
        if gamepad.rightShoulder.isPressed || gamepad.rightTrigger.isPressed {
            pressedButtons.insert(.r)
        }

        let upPressed = gamepad.dpad.up.isPressed || gamepad.leftThumbstick.yAxis.value > analogThreshold
        let downPressed = gamepad.dpad.down.isPressed || gamepad.leftThumbstick.yAxis.value < -analogThreshold
        let leftPressed = gamepad.dpad.left.isPressed || gamepad.leftThumbstick.xAxis.value < -analogThreshold
        let rightPressed = gamepad.dpad.right.isPressed || gamepad.leftThumbstick.xAxis.value > analogThreshold

        if upPressed {
            pressedButtons.insert(.up)
        }
        if downPressed {
            pressedButtons.insert(.down)
        }
        if leftPressed {
            pressedButtons.insert(.left)
        }
        if rightPressed {
            pressedButtons.insert(.right)
        }

        return pressedButtons
    }

    private var analogThreshold: Float {
        let configured = UserDefaults.standard.double(forKey: "settings.inputSensitivity")
        let normalized = configured == 0 ? 0.55 : min(max(configured, 0.1), 1.0)
        return Float(max(0.15, 1.0 - normalized))
    }

    private func emitPulse(for button: VirtualGamepadButton) {
        GameInputDispatcher.post(.init(button: button, isPressed: true), source: self)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            GameInputDispatcher.post(.init(button: button, isPressed: false), source: self)
        }
    }

    private func buttonSortOrder(_ lhs: VirtualGamepadButton, _ rhs: VirtualGamepadButton) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
