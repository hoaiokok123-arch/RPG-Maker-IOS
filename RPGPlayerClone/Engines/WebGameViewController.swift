import Foundation
import UIKit
import WebKit

private final class WeakScriptMessageHandler: NSObject, WKScriptMessageHandler {
    weak var target: WKScriptMessageHandler?

    init(target: WKScriptMessageHandler) {
        self.target = target
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        target?.userContentController(userContentController, didReceive: message)
    }
}

final class WebGameViewController: UIViewController, WKNavigationDelegate, WKScriptMessageHandler {
    private let game: Game
    private let controlMap = VirtualGamepadResourceLoader.controlMap()

    private lazy var webView = makeWebView()
    private let gamepadView = VirtualGamepadView(configuration: .loadFromDefaults())
    private let statusLabel = UILabel()
    private var saveBridgeProxy: WeakScriptMessageHandler?

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
        loadGame()
    }

    override var prefersStatusBarHidden: Bool {
        true
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        true
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        webView.stopLoading()
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "saveBridge")
        webView.navigationDelegate = nil
        saveBridgeProxy = nil
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "saveBridge",
              let payload = message.body as? [String: Any],
              let type = payload["type"] as? String,
              type == "snapshot",
              let snapshot = payload["payload"] as? [String: String] else {
            return
        }

        UserDefaults.standard.set(snapshot, forKey: saveSnapshotKey)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        injectBundledGamepadSupport()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        showNavigationError(error)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        showNavigationError(error)
    }

    private func makeWebView() -> WKWebView {
        let contentController = WKUserContentController()
        let proxy = WeakScriptMessageHandler(target: self)
        saveBridgeProxy = proxy
        contentController.add(proxy, name: "saveBridge")

        for script in bundledUserScripts() {
            contentController.addUserScript(script)
        }

        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.allowsInlineMediaPlayback = true
        configuration.userContentController = contentController

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.backgroundColor = .black
        webView.isOpaque = false
        webView.scrollView.isScrollEnabled = false
        webView.navigationDelegate = self
        return webView
    }

    private func bundledUserScripts() -> [WKUserScript] {
        var scripts: [WKUserScript] = [
            WKUserScript(
                source: makeBootstrapScript(),
                injectionTime: .atDocumentStart,
                forMainFrameOnly: true
            )
        ]

        if let helperScript = VirtualGamepadResourceLoader.textResource(named: "gamepad", withExtension: "js") {
            scripts.append(
                WKUserScript(
                    source: helperScript,
                    injectionTime: .atDocumentEnd,
                    forMainFrameOnly: true
                )
            )
        }

        if let styleScript = makeStyleInjectionScript() {
            scripts.append(
                WKUserScript(
                    source: styleScript,
                    injectionTime: .atDocumentEnd,
                    forMainFrameOnly: true
                )
            )
        }

        return scripts
    }

    private func setupLayout() {
        webView.translatesAutoresizingMaskIntoConstraints = false
        gamepadView.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        statusLabel.textColor = .white
        statusLabel.numberOfLines = 0
        statusLabel.textAlignment = .center
        statusLabel.font = .preferredFont(forTextStyle: .body)
        statusLabel.isHidden = true

        view.addSubview(webView)
        view.addSubview(statusLabel)
        view.addSubview(gamepadView)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            statusLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            statusLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24),

            gamepadView.topAnchor.constraint(equalTo: view.topAnchor),
            gamepadView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gamepadView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gamepadView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
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

    private func loadGame() {
        guard let entryURL = resolveEntryPoint(for: game.path) else {
            statusLabel.text = """
            Khong tim thay file index.html cho game MV/MZ.

            Da thu:
            - <game>/www/index.html
            - <game>/index.html
            """
            statusLabel.isHidden = false
            return
        }

        statusLabel.isHidden = true
        webView.loadFileURL(entryURL, allowingReadAccessTo: game.path)
    }

    private func resolveEntryPoint(for root: URL) -> URL? {
        let fileManager = FileManager.default
        let candidates = [
            root.appendingPathComponent("www/index.html"),
            root.appendingPathComponent("index.html")
        ]

        return candidates.first(where: { fileManager.itemExists(at: $0) })
    }

    private func makeBootstrapScript() -> String {
        let snapshot = (UserDefaults.standard.dictionary(forKey: saveSnapshotKey) as? [String: String]) ?? [:]
        let snapshotJSON = jsonLiteral(for: snapshot) ?? "{}"
        let controlMapJSON = jsonLiteral(for: controlMap) ?? "{}"

        return """
        (function() {
            const initialSnapshot = \(snapshotJSON);
            const controlMap = \(controlMapJSON);

            try {
                Object.entries(initialSnapshot).forEach(([key, value]) => {
                    localStorage.setItem(key, value);
                });
            } catch (error) {
                console.log("localStorage bootstrap skipped", error);
            }

            function keyValueForCode(code) {
                switch (code) {
                case "ShiftLeft":
                case "ShiftRight":
                    return "Shift";
                case "ControlLeft":
                case "ControlRight":
                    return "Control";
                case "AltLeft":
                case "AltRight":
                    return "Alt";
                case "MetaLeft":
                case "MetaRight":
                    return "Meta";
                default:
                    return code;
                }
            }

            function dispatchMappings(mappings, pressed) {
                mappings.forEach(function(code) {
                    const eventType = pressed ? "keydown" : "keyup";
                    const event = new KeyboardEvent(eventType, {
                        key: keyValueForCode(code),
                        code: code,
                        bubbles: true
                    });
                    if (document.activeElement && document.activeElement !== document.body) {
                        document.activeElement.dispatchEvent(event);
                    }
                    document.dispatchEvent(event);
                    window.dispatchEvent(event);
                });
            }

            function saveSnapshot() {
                try {
                    const payload = {};
                    for (let i = 0; i < localStorage.length; i += 1) {
                        const key = localStorage.key(i);
                        payload[key] = localStorage.getItem(key);
                    }
                    window.webkit.messageHandlers.saveBridge.postMessage({
                        type: "snapshot",
                        payload: payload
                    });
                } catch (error) {
                    console.log("save snapshot skipped", error);
                }
            }

            window.RPGPlayerClone = window.RPGPlayerClone || {};
            window.RPGPlayerClone.dispatchButton = function(button, pressed) {
                const mappings = controlMap[button] || [];
                if (mappings.length === 0) {
                    return;
                }

                dispatchMappings(mappings, pressed);
            };

            window.RPGPlayerClone.restoreSaveSnapshot = function() {
                return initialSnapshot;
            };

            window.addEventListener("pagehide", saveSnapshot);
            window.addEventListener("beforeunload", saveSnapshot);
            document.addEventListener("visibilitychange", function() {
                if (document.hidden) {
                    saveSnapshot();
                }
            });
        })();
        """
    }

    private func makeStyleInjectionScript() -> String? {
        guard let css = VirtualGamepadResourceLoader.textResource(named: "gamepad", withExtension: "css"),
              let cssLiteral = javaScriptStringLiteral(css) else {
            return nil
        }

        return """
        (function() {
            if (document.getElementById("rpgplayerclone-gamepad-style")) {
                return;
            }

            const style = document.createElement("style");
            style.id = "rpgplayerclone-gamepad-style";
            style.textContent = \(cssLiteral);

            if (document.head) {
                document.head.appendChild(style);
            } else {
                document.documentElement.appendChild(style);
            }
        })();
        """
    }

    private func injectBundledGamepadSupport() {
        let script = """
        (function() {
            document.documentElement.classList.add("rpgplayer-gamepad-enabled");
            if (document.body) {
                document.body.classList.add("rpgplayer-gamepad-enabled");
            }

            if (window.RPGPlayerCloneGamepad && window.RPGPlayerCloneGamepad.mount) {
                window.RPGPlayerCloneGamepad.mount();
            }
        })();
        """

        webView.evaluateJavaScript(script)
    }

    private func showNavigationError(_ error: Error) {
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain, nsError.code == NSURLErrorCancelled {
            return
        }

        statusLabel.text = "Khong tai duoc game web: \(error.localizedDescription)"
        statusLabel.isHidden = false
    }

    private func jsonLiteral(for object: Any) -> String? {
        guard JSONSerialization.isValidJSONObject(object),
              let data = try? JSONSerialization.data(withJSONObject: object, options: []),
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }

        return string
    }

    private func javaScriptStringLiteral(_ string: String) -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: [string], options: []),
              let json = String(data: data, encoding: .utf8) else {
            return nil
        }

        return String(json.dropFirst().dropLast())
    }

    @objc private func handleVirtualInput(_ notification: Notification) {
        guard let event = notification.userInfo?[VirtualGamepadEvent.notificationUserInfoKey] as? VirtualGamepadEvent else {
            return
        }

        let script = "window.RPGPlayerClone && window.RPGPlayerClone.dispatchButton('\(event.button.rawValue)', \(event.isPressed ? "true" : "false"));"
        webView.evaluateJavaScript(script)
    }

    @objc private func handleShutdown() {
        webView.stopLoading()
        webView.loadHTMLString("", baseURL: nil)
    }

    private var saveSnapshotKey: String {
        "RPGPlayerClone.SaveSnapshot.\(game.id.uuidString)"
    }
}
