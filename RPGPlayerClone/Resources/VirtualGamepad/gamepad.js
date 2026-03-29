/*
 * Derived from aidatorajiro/easyrpg-web:
 * - www/pre.js
 * - www/orig.js
 *
 * This version is trimmed into a reusable helper for embedded web runtimes.
 */

(function () {
  const hasTouchscreen = window.matchMedia("(hover: none), (pointer: coarse)").matches;
  const keys = new Map();
  const keysDown = new Map();
  let keySet = new Set();
  let previousKeySet = new Set();
  let lastTouchedId = null;

  function difference(source, subset) {
    return new Set([...source].filter((item) => !subset.has(item)));
  }

  function union(source, subset) {
    return new Set([...source, ...subset]);
  }

  function resolveCanvas() {
    return document.getElementById("canvas");
  }

  function simulateKeyboardEvent(eventType, key) {
    const canvas = resolveCanvas();
    if (!canvas) {
      return;
    }

    const event = new Event(eventType, { bubbles: true });
    event.code = key;
    canvas.dispatchEvent(event);
  }

  function executeKeySet() {
    const keyUps = difference(previousKeySet, keySet);
    const keyDowns = difference(keySet, previousKeySet);

    keyUps.forEach((key) => simulateKeyboardEvent("keyup", key));
    keyDowns.forEach((key) => simulateKeyboardEvent("keydown", key));

    previousKeySet = new Set(keySet);
  }

  function updateSimulatedKeySet(action, subset) {
    const nextKeys = new Set(String(subset || "").split(",").filter(Boolean));

    if (action === "add") {
      keySet = union(keySet, nextKeys);
    } else if (action === "remove") {
      keySet = difference(keySet, nextKeys);
    }

    executeKeySet();
  }

  function bindKey(node, key) {
    keys.set(node.id, key);

    node.addEventListener("touchstart", (event) => {
      event.preventDefault();
      updateSimulatedKeySet("add", key);
      keysDown.set(event.target.id, node.id);
      node.classList.add("active");
    });

    node.addEventListener("touchend", (event) => {
      event.preventDefault();

      const pressedKey = keysDown.get(event.target.id);
      if (pressedKey && keys.has(pressedKey)) {
        updateSimulatedKeySet("remove", keys.get(pressedKey));
      }

      keysDown.delete(event.target.id);
      node.classList.remove("active");

      if (lastTouchedId) {
        const touchedNode = document.getElementById(lastTouchedId);
        if (touchedNode) {
          touchedNode.classList.remove("active");
        }
      }
    });

    node.addEventListener("touchmove", (event) => {
      const touch = event.changedTouches[0];
      if (!touch) {
        return;
      }

      const originalTargetId = keysDown.get(touch.target.id);
      const nextTarget = document.elementFromPoint(touch.clientX, touch.clientY);
      const nextTargetId = nextTarget ? nextTarget.id : null;

      if (originalTargetId === nextTargetId) {
        return;
      }

      if (originalTargetId && keys.has(originalTargetId)) {
        updateSimulatedKeySet("remove", keys.get(originalTargetId));
        keysDown.delete(touch.target.id);
        const originalNode = document.getElementById(originalTargetId);
        if (originalNode) {
          originalNode.classList.remove("active");
        }
      }

      if (nextTargetId && keys.has(nextTargetId)) {
        updateSimulatedKeySet("add", keys.get(nextTargetId));
        keysDown.set(touch.target.id, nextTargetId);
        lastTouchedId = nextTargetId;
        nextTarget.classList.add("active");
      }
    });
  }

  const gamepads = {};
  const haveEvents = "ongamepadconnected" in window;

  function addGamepad(gamepad) {
    if (!gamepad) {
      return;
    }
    gamepads[gamepad.index] = gamepad;
    updateTouchControlsVisibility();
  }

  function removeGamepad(gamepad) {
    if (!gamepad) {
      return;
    }
    delete gamepads[gamepad.index];
    updateTouchControlsVisibility();
  }

  function getGamepads() {
    if (navigator.getGamepads) {
      return navigator.getGamepads();
    }
    if (navigator.webkitGetGamepads) {
      return navigator.webkitGetGamepads();
    }
    return [];
  }

  function scanGamepads() {
    const pads = getGamepads();
    for (let index = 0; index < pads.length; index += 1) {
      const pad = pads[index];
      if (!pad) {
        continue;
      }

      if (pad.index in gamepads) {
        gamepads[pad.index] = pad;
      } else {
        addGamepad(pad);
      }
    }
  }

  function updateTouchControlsVisibility() {
    const shouldShow = hasTouchscreen && Object.keys(gamepads).length === 0;
    document.querySelectorAll("#dpad, #apad").forEach((element) => {
      element.style.display = shouldShow ? "" : "none";
    });
  }

  function mount() {
    if (hasTouchscreen) {
      document.querySelectorAll("[data-key]").forEach((button) => {
        bindKey(button, button.dataset.key);
      });
    } else {
      const canvas = resolveCanvas();
      if (canvas) {
        canvas.addEventListener("contextmenu", (event) => {
          event.preventDefault();
        });
      }
    }

    if (!haveEvents) {
      window.setInterval(scanGamepads, 500);
    }

    window.addEventListener("gamepadconnected", (event) => addGamepad(event.gamepad));
    window.addEventListener("gamepaddisconnected", (event) => removeGamepad(event.gamepad));

    const fullscreenButton = document.querySelector("#controls-fullscreen");
    if (fullscreenButton) {
      fullscreenButton.addEventListener("click", () => {
        const viewport = document.getElementById("viewport");
        if (viewport && viewport.requestFullscreen) {
          viewport.requestFullscreen();
        }
      });
    }

    updateTouchControlsVisibility();
  }

  window.RPGPlayerCloneGamepad = {
    mount,
    simulateKeyboardEvent,
    updateSimulatedKeySet,
    updateTouchControlsVisibility
  };
})();

