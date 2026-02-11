const dom_parser = new DOMParser()
const state_prop = Symbol();

const verbs: Array<string> = ["get", "post"];
// Matches element with any verb
const verbSelector = verbs.map(verb => `[hx-${verb}]`).join(',')

async function htmx(elmt: HTMLElement, method: string) {
    const url = elmt.getAttribute(`hx-${method}`);
    if (!url) {
        return;
    }

    const target = getTarget(elmt);
    if (!target) {
        return;
    }

    const body = method !== 'get'
        ? getBody(elmt)
        : undefined

    const request = await fetch(url, { method, body })
    if (!request.ok || request.status === 204) {
        return // don't swap on NO CONTENT or error
    }

    const html = await request.text();
    const content = dom_parser.parseFromString(html, "text/html");

    swap(target, content);
}

function getBody(elmt: HTMLElement) {
    return "";
}

function getTarget(elmt: HTMLElement): HTMLElement | null {
    const targetSelector = elmt.getAttribute("hx-target");
    return document.querySelector(targetSelector);
}

function swap(target: HTMLElement, content: Document) {
    deinit(target);
    init(target);

    target.replaceWith(content);
}

/// Triggers HTMX action, called when an element event occurs
function trigger(event: Event) {
    const elmt = event.currentTarget as HTMLElement;

    const verb = verbs.find(verb => elmt.hasAttribute(`hx-${verb}`));
    if (!verb) {
        return;
    }

    event.preventDefault();
    htmx(elmt, verb);
}


//
// Connecting
//

function connect(elmt: HTMLElement) {
    if (elmt[state_prop]) {
        return; // Already initialized
    }

    const event_name = elmt.getAttribute("hx-trigger").trim() ?? "click";
    elmt.addEventListener(event_name, trigger);

    elmt[state_prop] = { cleanup: () => elmt.removeEventListener(event_name, trigger) }
}

function disconnect(elmt: HTMLElement) {
    const state = elmt[state_prop]
    if (!state) {
        return // Not initialized
    }

    elmt[state_prop] = null
    state.cleanup();
}


//
// Initialization
//

function* queryAllAndSelf(selector: string, ...elmts: any[]) {
    for (const elt of elmts) {
        if (elt.nodeType !== Node.ELEMENT_NODE) {
            continue
        }

        if (elt.matches(selector)) {
            yield elt
        }

        yield* elt.querySelectorAll(selector)
    }
}

function init(...elts: any[]) {
    for (const elt of queryAllAndSelf(verbSelector, ...elts)) {
        connect(elt)
    }
}

function deinit(...elts: any[]) {
    for (const elt of queryAllAndSelf(verbSelector, ...elts)) {
        disconnect(elt)
    }
}

if (document.readyState !== 'loading') {
    init(document.body)
} else {
    document.addEventListener('DOMContentLoaded', () => init(document.body))
}
