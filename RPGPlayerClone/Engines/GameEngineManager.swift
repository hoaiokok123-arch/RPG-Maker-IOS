import Foundation
import UIKit

extension Notification.Name {
    static let engineShouldTerminate = Notification.Name("RPGPlayerClone.engineShouldTerminate")
}

final class GameEngineManager {
    static let shared = GameEngineManager()

    private weak var currentController: UIViewController?

    private init() {}

    func launch(game: Game) -> UIViewController? {
        shutdownCurrentEngine()

        let controller: UIViewController?
        switch game.gameType {
        case .rpg2k, .rpg2k3:
            controller = EasyRPGWrapper(game: game)
        case .rpgXP, .rpgVX, .rpgVXAce:
            controller = MKXPZWrapper(game: game)
        case .rpgMV, .rpgMZ:
            controller = WebGameViewController(game: game)
        case .unknown:
            controller = nil
        }

        currentController = controller
        return controller
    }

    func shutdownCurrentEngine() {
        NotificationCenter.default.post(name: .engineShouldTerminate, object: nil)
        currentController?.view.removeFromSuperview()
        currentController?.removeFromParent()
        currentController = nil
    }
}
