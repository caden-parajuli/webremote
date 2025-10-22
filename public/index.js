/**
 * @param {RequestInfo | URL} url
 */
async function sendRequest(url) {
    fetch(url, {
        method: "GET"
    })
        .then(response => {
            if (response.ok) {
                return response.text();
            } else {
                console.error("Fetch error.")
            }
        })
        .then(data => console.log(data))
        .catch(error => console.error('There was a problem with the fetch operation:', error));;
}

/**
 * @param {string} key
 */
async function pressKey(key) {
    return sendRequest("/kbd/press/" + key);
}

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

document.addEventListener('DOMContentLoaded', addListeners);
window.onload = registerSW

