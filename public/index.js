
/// Async queue to ensure keypress ordering is preserved
/// Currently uses a pretty inefficient queue implementation with array pushes and shifts
class FetchQueue {
    constructor() {
        this.running = false;
        this.queue = [];
    }

    /**
     * @param {() => any} f
     * @returns {Promise<any>}
     */
    addTask(f) {
        return new Promise((res, rej) => {
            const task = async () => {
                try {
                    this.running = true;
                    const result = await f();
                    res(result);
                } catch (e) {
                    rej(e);
                } finally {
                    this.running = false;
                    if (this.queue.length > 0) {
                        const nextTask = this.queue.shift();
                        nextTask();
                    }
                }
            }

            if (this.running) {
                this.queue.push(task);
            } else {
                task();
            }
        })
    }

    /**
     * @param {URL | string} url
     * @param {string} method
     * @returns {Promise<Response>}
     */
    runFetch(url, method, body=null) {
        return this.addTask(async () => {
            let response = await fetch(url, {
                method: method,
                body: body,
            })
            return response;
        });
    }
}

/**
 * @param {FetchQueue} queue
 * @param {string | URL} baseURL
 * @param {string} key
 * @returns {Promise<string>}
 */
async function callKeyProc(queue, baseURL, key) {
    let response = await queue.runFetch(baseURL + key, "GET");

    if (response.ok) {
        let text = await response.text();
        console.log(text);
        return text;
    } else {
        console.error("Fetch error. Status: " + String(response.status));
        console.error(await response.text());
        return undefined;
    }
}

/**
 * @param {FetchQueue} queue
 * @param {string} key
 * @returns {Promise<string>}
 */
async function pressKey(queue, key) {
    return callKeyProc(queue, "/kbd/press/", key);
}

/**
 * @param {FetchQueue} queue
 * @param {string} key
 * @returns {Promise<string>}
 */
async function keyDown(queue, key) {
    return callKeyProc(queue, "/kbd/down/", key);
}

/**
 * @param {FetchQueue} queue
 * @param {string} key
 * @returns {Promise<string>}
 */
async function keyUp(queue, key) {
    return callKeyProc(queue, "/kbd/up/", key);
}


/**
 * @param {FetchQueue} queue
 * @param {string} text - The string to type
 * @returns {Promise<string>}
 */
async function typeString(queue, text) {
    let response = await queue.runFetch("/kbd/type", "GET", text);

    if (response.ok) {
        let text = await response.text();
        console.log(text);
        return text;
    } else {
        console.error("Fetch error. Status: " + String(response.status));
        console.error(await response.text());
        return undefined;
    }
}

/**
 * @param {number} amount
 * @returns {Promise<number>}
 */
async function adjustVolume(amount) {
    var url;
    if (amount > 0) {
        url = "/volume/up/" + String(amount);
    } else {
        url = "/volume/down/" + String(-amount);
    }

    let response = await fetch(url, { method: "GET" })

    if (response.ok) {
        let volume = Number(await response.text());
        updateVolumeText(volume);

        return volume;

    } else if (response.status == 500) {
        console.error("Server volume error. Check backend logs.");
        return -1;
    } else {
        console.error("Error. Status: " + String(response.status));
        return -1;
    }
}

/**
 * @param {number} value
 * @returns {Promise<number>}
 */
async function setVolume(value) {
    const url = "/volume/set/" + String(value);
    let response = await fetch(url, { method: "GET" })

    if (response.ok) {
        let volume = Number(await response.text());
        updateVolumeText(volume);

        return volume;

    } else if (response.status == 500) {
        console.error("Server volume error. Check backend logs.");
        return -1;
    } else {
        console.error("Error. Status: " + String(response.status));
        return -1;
    }
}

/**
 * @param {string} app - App name
 * @returns {Promise<number>}
 */
async function openApp(app) {
    const url = "/app/open/" + String(app);
    let response = await fetch(url, { method: "GET" });

    if (response.ok) {
        return 0;

    } else if (response.status == 500) {
        console.error("Server volume error. Check backend logs.");
        return -1;
    } else {
        console.error("Error. Status: " + String(response.status));
        return -1;
    }
}

/**
 * @returns {Promise<string>} - volume level or "Unkown"
 */
async function getVolume() {
    const url = "/volume/get";
    let response = await fetch(url, { method: "GET" });
    if (response.ok) {
        return await response.text();
    } else if (response.status == 500) {
        console.error("Server volume error. Check backend logs.");
        return "Unknown";
    } else {
        console.error("Error. Status: " + String(response.status));
        return "Unknown";
    }
}

/**
 * @param {RequestInfo | URL} url
 * @returns {Promise<string>} - volume level or "Unkown"
 */
async function callMpris(url) {
    let response = await fetch(url, { method: "GET" })
    if (response.ok) {
        return await response.text();
    } else if (response.status == 500) {
        console.error("Server Mpris error. Check backend logs.");
        return "FAIL";
    } else {
        console.error("Error. Status: " + String(response.status));
        return "FAIL";
    }
}

/**
 * @param {string | number} volume
 */
function updateVolumeText(volume) {
    const textVolume = String(volume);
    document.getElementById("volume-level").innerText = textVolume + "%";
    let slider = /** @type {HTMLInputElement} */ (document.getElementById("volume-slider"));
    slider.value = textVolume;
    fixSliderStyle(slider);
}

async function pollVolume() {
    let volume = await getVolume();
    updateVolumeText(volume);
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
 * Add control/key listeners
 */
function addControlHandlers() {
    var queue = new FetchQueue();
    var keyButtons = document.querySelectorAll(".key-button")
    keyButtons.forEach(keyButton => {
        addListenerIfNotNull(keyButton, "click", function (_) {
            pressKey(queue, this.dataset.key);
        });
        // @ts-ignore
        console.log("Add handler: " + keyButton.dataset.key);
    });
}

/**
 * Add app listeners
 */
function addAppHandlers() {
    var queue = new FetchQueue();
    var appButtons = document.querySelectorAll(".app-btn")
    appButtons.forEach(appButton => {
        addListenerIfNotNull(appButton, "click", function (_) {
            openApp(this.dataset.app);
        });
        // @ts-ignore
        console.log("Add handler: " + appButton.dataset.app);
    });
}

/**
 * Register service worker
 */
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
 * @param {{ value: number|string; style: { background: string; }; }} slider
 */
function fixSliderStyle(slider) {
    const percent = (Number(slider.value) / 100) * 100;
    const gradient = `linear-gradient(90deg, var(--theme-color) ${percent}%, var(--track-background) ${percent}%)`;
    slider.style.background = gradient;
}

function addSliderListener() {
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
        setVolume(Number(value));
    });
}

function setVolumeControlHandlers() {
    addListenerIfNotNull(document.getElementById("volume-down"), "click", function () {
        adjustVolume(-5);
    });
    addListenerIfNotNull(document.getElementById("volume-up"), "click", function () {
        adjustVolume(5);
    });
}

function setMediaControlHandlers() {
    addListenerIfNotNull(document.getElementById("play-button"), "click", function () {
        callMpris("/play");
    });
    addListenerIfNotNull(document.getElementById("pause-button"), "click", function () {
        callMpris("/pause");
    });
    addListenerIfNotNull(document.getElementById("play-pause-button"), "click", function () {
        callMpris("/playpause");
    });
    addListenerIfNotNull(document.getElementById("stop-button"), "click", function () {
        callMpris("/stop");
    });
}


//
// Main
//

function onContentLoad() {
    pollVolume();
    setInterval(pollVolume, 5 * 1000);

    addSliderListener();

    setVolumeControlHandlers();
    setMediaControlHandlers();
    addControlHandlers();
    addAppHandlers();
}

document.addEventListener('DOMContentLoaded', onContentLoad);
window.onload = registerSW

// Prevent scroll on iOS
window.addEventListener("scroll", (e) => {
    e.preventDefault();
    window.scrollTo(0, 0);
});
