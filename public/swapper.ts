const dom_parser = new DOMParser()

export async function htmx(url: URL | string, method: string, targetSelector: string) {
    const target = document.querySelector(targetSelector) as HTMLElement;
    if (!target) {
        console.log("Target not found");
        return;
    }

    const request = await fetch(url, { method })
    if (!request.ok || request.status === 204) {
        return // don't swap on NO CONTENT or error
    }

    const html = await request.text();
    const doc = dom_parser.parseFromString(`<template>${html}</template>`, "text/html");
    const content = doc.querySelector('template').content;

    swap(target, content);
}

function swap(target: HTMLElement, content: any) {
    target.replaceWith(content);
}

