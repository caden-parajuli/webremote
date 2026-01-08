var volume = 50;

class WS {
    url: string;
    socket: WebSocket;

    constructor() {
        let protocol: string;
        if (window.location.protocol == "https:") {
            protocol = "wss://";
        } else {
            protocol = "ws://"
        }
        this.url = protocol + window.location.host + "/ws";

        this.connect();
    }

    connect(message?: string | ArrayBuffer | Blob) {
        this.socket = new WebSocket(this.url);

        this.socket.addEventListener("open", (_event) => {
            if (typeof message != "undefined") {
                this.socket.send(message);
            }
            this.getVolume();
        });

        this.socket.addEventListener("message", (event) => {
            const message = JSON.parse(event.data);
            console.log("Message received: ", message);
            this.handleMessage(message);
        });

        this.socket.addEventListener("close", (_event) => {
            console.warn("WebSocket closed");
        });

        this.socket.addEventListener("error", (error) => {
            console.warn("WebSocket error: ", error);
            this.socket.close();
        });
    }

    send(data: string | ArrayBuffer | Blob) {
        if (this.socket.readyState === WebSocket.CLOSED) {
            this.connect(data);
            return;
        }

        this.socket.send(data);
    }

    handleMessage(message: { type: string; level: string | number; }) {
        if (message.type == "Volume") {
            setVolumeText(message.level);
        }
    }


    callKeyProc(event: string, key: string): void {
        this.send(JSON.stringify({
            [event]: {
                key: key
            }
        }))
    }

    pushKey(key: string) {
        this.callKeyProc("PressKey", key);
    }

    keyDown(key: string) {
        this.callKeyProc("PushKey", key);
    }

    keyUp(key: string) {
        this.callKeyProc("ReleaseKey", key);
    }

    typeString(text: string) {
        this.send(JSON.stringify({
            Type: {
                message: text
            }
        }));
    }


    getVolume() {
        console.log("Getting volume");
        this.send(`"GetVolume"`);
    }

    setVolume(value: number) {
        this.send(JSON.stringify({
            SetVolume: {
                value: value
            }
        }));
    }

    adjustVolume(amount: number) {
        this.send(JSON.stringify({
            AdjustVolume: {
                delta: amount
            }
        }));
    }


    openApp(app: string) {
        this.send(JSON.stringify({
            GotoApp: {
                name: app
            }
        }));
    }


    callMpris(method: string) {
        this.send(`"${method}"`);
    }
}


//
// Page Handlers
//

function setVolumeText(volume: string | number) {
    const textVolume = String(volume);
    document.getElementById("volume-level")!.innerText = textVolume + "%";
    let slider = document.getElementById("volume-slider")! as HTMLInputElement;
    slider.value = textVolume;
    fixSliderStyle(slider);
}

function addListenerIfNotNull(el: Element | null, ev: string, f: any): void {
    if (el != null) {
        el.addEventListener(ev, f);
    }
}

function addKeyboardDialogHandlers(ws: WS) {
    let keyboard_button = document.getElementById("keyboard-button")!;
    let dialog = document.getElementById("keyboard-modal")! as HTMLDialogElement;
    let textBox = document.getElementById("to-type")! as HTMLInputElement;
    let confirmButton = document.getElementById("keyboard-ok")!;

    keyboard_button.addEventListener("click", () => {
        dialog.showModal();
        confirmButton.focus();
        textBox.focus();
    })

    dialog.addEventListener("close", (_) => {
        let text = dialog.returnValue;
        if (text !== "") {
            ws.typeString(text);
        }
    });

    confirmButton.addEventListener("click", (e) => {
        e.preventDefault();
        dialog.close(textBox.value);
    });
}

/** Add control/key listeners */
function addControlHandlers(ws: WS) {
    var keyButtons = document.querySelectorAll(".key-button")
    keyButtons.forEach(keyButton => {
        addListenerIfNotNull(keyButton, "click", function (_: any) {
            ws.pushKey(this.dataset.key);
        });
        // @ts-ignore
        console.log("Add handler: " + keyButton.dataset.key);
    });

    addKeyboardDialogHandlers(ws);
}

/** Add app listeners */
function addAppHandlers(ws: WS) {
    var appButtons = document.querySelectorAll(".app-btn")
    appButtons.forEach(appButton => {
        addListenerIfNotNull(appButton, "click", function (_: any) {
            ws.openApp(this.dataset.app);
        });
    });
}

function fixSliderStyle(slider: { value: number | string; style: { background: string; }; }) {
    const percent = (Number(slider.value) / 100) * 100;
    const gradient = `linear-gradient(90deg, var(--theme-color) ${percent}%, var(--track-background) ${percent}%)`;
    slider.style.background = gradient;
}

function addSliderListener(ws: WS) {
    const sliders = document.querySelectorAll("input[type=range]")! as NodeListOf<HTMLInputElement>;
    sliders.forEach(rangeInput => {
        fixSliderStyle(rangeInput);
        addListenerIfNotNull(rangeInput, "input", function () { fixSliderStyle(this) });
    });
    const volumeSlider = document.getElementById("volume-slider");
    addListenerIfNotNull(volumeSlider, "change", (event: { target: { value: any; }; }) => {
        let value = event.target.value;
        ws.setVolume(Number(value));
    });
}

function setVolumeControlHandlers(ws: WS) {
    addListenerIfNotNull(document.getElementById("volume-down"), "click", function () {
        ws.adjustVolume(-5);
    });
    addListenerIfNotNull(document.getElementById("volume-up"), "click", function () {
        ws.adjustVolume(5);
    });
}

function setMediaControlHandlers(ws: WS) {
    addListenerIfNotNull(document.getElementById("play-button"), "click", function () {
        ws.callMpris("Play");
    });
    addListenerIfNotNull(document.getElementById("pause-button"), "click", function () {
        ws.callMpris("Pause");
    });
    addListenerIfNotNull(document.getElementById("play-pause-button"), "click", function () {
        ws.callMpris("PlayPause");
    });
    addListenerIfNotNull(document.getElementById("stop-button"), "click", function () {
        ws.callMpris("Stop");
    });
}


//
// Main
//

function registerSW() {
    if ("serviceWorker" in navigator) {
        navigator.serviceWorker.register("/service-worker.js")
            .then((registration) => {
                console.log("Service Worker registered with scope:", registration.scope);
            })
            .catch((error) => {
                console.error("Service Worker registration failed:", error);
            });
    }
}

function onContentLoad() {
    const ws = new WS();

    addSliderListener(ws);

    setVolumeControlHandlers(ws);
    setMediaControlHandlers(ws);
    addControlHandlers(ws);
    addAppHandlers(ws);

    // Prevent keyboard causing a viewport resize
    // @ts-ignore
    // navigator.virtualKeyboard.overlaysContent = true;

    // Prevent scroll on iOS
    window.addEventListener("scroll", (scroll_event) => {
        scroll_event.preventDefault();
        window.scrollTo(0, 0);
    });
}

window.onload = registerSW
document.addEventListener("DOMContentLoaded", onContentLoad);
