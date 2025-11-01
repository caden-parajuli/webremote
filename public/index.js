/**
 * @param {string} key
 * @returns {Promise<string>}
 */
async function pressKey(key) {
    return await fetch("/kbd/press/" + key, {
        method: "GET"
    })
        .then(response => {
            if (response.ok) {
                return response.text();
            } else {
                console.error("Fetch error.")
            }
        })
        .then(data => {
            console.log(data);
            return data;
        })
        .catch(error => {
            console.error('fetch error: ', error);
            return undefined;
        });
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
 * @returns {Promise<string>} - volume level or "Unkown"
 */
async function getVolume() {
    const url = "/volume/get";
    let response = await fetch(url, { method: "GET" })
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
 * Adds key button listeners
 */
function addListeners() {
    var keyButtons = document.querySelectorAll(".key-button")
    keyButtons.forEach(keyButton => {
        keyButton.addEventListener("click", function (_) {
            pressKey(this.dataset.key);
        });
        // @ts-ignore
        console.log("Add handler: " + keyButton.dataset.key);
    });
}

/**
 * Registers service worker
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
        rangeInput.addEventListener('input', function () { fixSliderStyle(this) });
    });
    const volumeSlider = document.getElementById("volume-slider");
    volumeSlider.addEventListener("change", (event) => {
        // @ts-ignore
        let value = event.target.value;
        setVolume(Number(value));
    });
}

function setVolumeControlHandlers() {
    document.getElementById("volume-down").addEventListener("click", function () {
        adjustVolume(-5);
    });
    document.getElementById("volume-up").addEventListener("click", function () {
        adjustVolume(5);
    });
}

function onContentLoad() {
    pollVolume();
    setInterval(pollVolume, 5 * 1000);

    addSliderListener();

    setVolumeControlHandlers();
    addListeners();
}

document.addEventListener('DOMContentLoaded', onContentLoad);
window.onload = registerSW

// Prevent scroll on iOS
window.addEventListener("scroll", (e) => {
    e.preventDefault();
    window.scrollTo(0, 0);
});
