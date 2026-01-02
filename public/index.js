var volume = 50;

/**
 * @param {WebSocket} socket
 * @param {string} event
 * @param {string} key
 * @returns {void}
 */
function callKeyProc(socket, event, key) {
    socket.send(JSON.stringify({
        [event]: {
            key: key
        }
    }));
}

/**
 * @param {WebSocket} socket
 * @param {string} key
 * @returns {void}
 */
function pushKey(socket, key) {
    callKeyProc(socket, "PressKey", key);
}

/**
 * @param {WebSocket} socket
 * @param {string} key
 * @returns {void}
 */
function keyDown(socket, key) {
    callKeyProc(socket, "PushKey", key);
}

/**
 * @param {WebSocket} socket
 * @param {string} key
 * @returns {void}
 */
function keyUp(socket, key) {
    callKeyProc(socket, "ReleaseKey", key);
}


/**
 * @param {WebSocket} socket
 * @param {string} text - The string to type
 * @returns {void}
 */
function typeString(socket, text) {
    socket.send(JSON.stringify({
        Type: {
            message: text
        }
    }));
}

/**
 * @param {WebSocket} socket
 * @returns {void}
 */
function getVolume(socket) {
    socket.send(`"GetVolume"`);
}

/**
 * @param {WebSocket} socket
 * @param {number} value
 * @returns {void}
 */
function setVolume(socket, value) {
    socket.send(JSON.stringify({
        SetVolume: {
            value: value
        }
    }));
}

/**
 * @param {WebSocket} socket
 * @param {number} amount
 * @returns {void}
 */
function adjustVolume(socket, amount) {
    socket.send(JSON.stringify({
        AdjustVolume: {
            delta: amount
        }
    }));
}

/**
 * @param {WebSocket} socket
 * @param {string} app - App name
 * @returns {void}
 */
function openApp(socket, app) {
    socket.send(JSON.stringify({
        GotoApp: {
            name: app
        }
    }));
}


/**
 * @param {WebSocket} socket
 * @param {String} method
 * @returns {void}
 */
function callMpris(socket, method) {
    socket.send(JSON.stringify({
        [method]: {}
    }));
}

/**
 * @param {string | number} volume
 */
function setVolumeText(volume) {
    const textVolume = String(volume);
    document.getElementById("volume-level").innerText = textVolume + "%";
    let slider = /** @type {HTMLInputElement} */ (document.getElementById("volume-slider"));
    slider.value = textVolume;
    fixSliderStyle(slider);
}

/**
 * @param {Element | null} el
 * @param {string} ev
 * @param {any} f
 */
function addListenerIfNotNull(el, ev, f) {
    if (el != null) {
        el.addEventListener(ev, f);
    }
}

/**
 * @param {WebSocket} socket
 */
function addKeyboardDialogHandlers(socket) {
    let keyboard_button = document.getElementById("keyboard-button")
    let dialog = /** @type {HTMLDialogElement} */ (document.getElementById("keyboard-modal"));
    let textBox = /** @type {HTMLInputElement} */ (document.getElementById("to-type"));
    let confirmButton = document.getElementById("keyboard-ok");

    keyboard_button.addEventListener("click", () => {
        dialog.showModal();
        confirmButton.focus();
        textBox.focus();
    })

    dialog.addEventListener("close", (_) => {
        let text = dialog.returnValue;
        if (text !== "") {
            typeString(socket, text);
        }
    });

    confirmButton.addEventListener("click", (e) => {
        e.preventDefault();
        dialog.close(textBox.value);
    });
}

/**
 * Add control/key listeners
 * @param {WebSocket} socket
 */
function addControlHandlers(socket) {
    var keyButtons = document.querySelectorAll(".key-button")
    keyButtons.forEach(keyButton => {
        addListenerIfNotNull(keyButton, "click", function (_) {
            pushKey(socket, this.dataset.key);
        });
        // @ts-ignore
        console.log("Add handler: " + keyButton.dataset.key);
    });

    addKeyboardDialogHandlers(socket);
}

/**
 * Add app listeners
 * @param {WebSocket} socket
 */
function addAppHandlers(socket) {
    var appButtons = document.querySelectorAll(".app-btn")
    appButtons.forEach(appButton => {
        addListenerIfNotNull(appButton, "click", function (_) {
            openApp(socket, this.dataset.app);
        });
        // @ts-ignore
        console.log("Add handler: " + appButton.dataset.app);
    });
}

/**
 * @param {{ value: number|string; style: { background: string; }; }} slider
 */
function fixSliderStyle(slider) {
    const percent = (Number(slider.value) / 100) * 100;
    const gradient = `linear-gradient(90deg, var(--theme-color) ${percent}%, var(--track-background) ${percent}%)`;
    slider.style.background = gradient;
}

/**
 * @param {WebSocket} [socket]
 */
function addSliderListener(socket) {
    const sliders = document.querySelectorAll("input[type=range]");
    sliders.forEach(rangeInput => {
        // @ts-ignore
        fixSliderStyle(rangeInput);
        addListenerIfNotNull(rangeInput, 'input', function () { fixSliderStyle(this) });
    });
    const volumeSlider = document.getElementById("volume-slider");
    addListenerIfNotNull(volumeSlider, "change", (event) => {
        // @ts-ignore
        let value = event.target.value;
        setVolume(socket, Number(value));
    });
}

/**
 * @param {WebSocket} socket
 */
function setVolumeControlHandlers(socket) {
    addListenerIfNotNull(document.getElementById("volume-down"), "click", function () {
        adjustVolume(socket, -5);
    });
    addListenerIfNotNull(document.getElementById("volume-up"), "click", function () {
        adjustVolume(socket, 5);
    });
}

/**
 * @param {WebSocket} socket
 */
function setMediaControlHandlers(socket) {
    addListenerIfNotNull(document.getElementById("play-button"), "click", function () {
        callMpris(socket, "Play");
    });
    addListenerIfNotNull(document.getElementById("pause-button"), "click", function () {
        callMpris(socket, "Pause");
    });
    addListenerIfNotNull(document.getElementById("play-pause-button"), "click", function () {
        callMpris(socket, "PlayPause");
    });
    addListenerIfNotNull(document.getElementById("stop-button"), "click", function () {
        callMpris(socket, "Stop");
    });
}

function registerSW() {
    if ('serviceWorker' in navigator) {
        navigator.serviceWorker.register('/service-worker.js')
            .then((registration) => {
                console.log('Service Worker registered with scope:', registration.scope);
            })
            .catch((error) => {
                console.error('Service Worker registration failed:', error);
            });
    }
}

/**
 * @param {{ type: string; level: string | number; }} message
 */
function handleMessage(message) {
    if (message.type == "Volume") {
        setVolumeText(message.level);
    }
}

function connectSocket() {
    let protocol;
    if (window.location.protocol == "https:") {
        protocol = "wss://";
    } else {
        protocol = "ws://"
    }
    const url = protocol + window.location.host + "/ws";
    const socket = new WebSocket(url);

    socket.addEventListener("message", (event) => {
        const message = JSON.parse(event.data);
        console.log("Message received: ", message);
        handleMessage(message);
    });

    socket.addEventListener("open", (_event) => {
        getVolume(socket);
    });

    return socket;
}

//
// Main
//

function onContentLoad() {
    const socket = connectSocket();

    addSliderListener(socket);

    setVolumeControlHandlers(socket);
    setMediaControlHandlers(socket);
    addControlHandlers(socket);
    addAppHandlers(socket);

    // Prevent keyboard causing a viewport resize
    // @ts-ignore
    // navigator.virtualKeyboard.overlaysContent = true;

    // Prevent scroll on iOS
    window.addEventListener("scroll", (scroll_event) => {
        scroll_event.preventDefault();
        window.scrollTo(0, 0);
    });

}

document.addEventListener('DOMContentLoaded', onContentLoad);
window.onload = registerSW
