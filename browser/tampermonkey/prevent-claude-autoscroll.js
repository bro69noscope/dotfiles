// ==UserScript==
// @name         Claude no auto-scroll
// @match        https://claude.ai/*
// @run-at       document-start
// @grant        none
// ==/UserScript==
(() => {
  let enabled = true;
  let until = 0;

  const SEND_WINDOW_MS = 1500;
  const open = () => {
    until = performance.now() + SEND_WINDOW_MS;
  };
  const allowed = () => !enabled || performance.now() < until;

  // Send detection: Enter in composer, or click on send button
  addEventListener(
    "keydown",
    (e) => {
      if (e.altKey && e.key.toLowerCase() === "s") {
        enabled = !enabled;
        console.log("[no-autoscroll]", enabled ? "ON" : "OFF");
        return;
      }
      if (
        e.key === "Enter" &&
        !e.shiftKey &&
        e.target instanceof Element &&
        e.target.closest('[contenteditable="true"], textarea')
      )
        open();
    },
    true,
  );
  addEventListener(
    "pointerdown",
    (e) => {
      if (
        e.target instanceof Element &&
        e.target.closest('button[aria-label*="send" i]')
      )
        open();
    },
    true,
  );

  const wrap = (obj, name) => {
    const orig = obj[name];
    if (typeof orig !== "function") return;
    obj[name] = function (...a) {
      if (allowed()) return orig.apply(this, a);
    };
  };
  for (const n of [
    "scrollTo",
    "scroll",
    "scrollBy",
    "scrollIntoView",
    "scrollIntoViewIfNeeded",
  ])
    wrap(Element.prototype, n);
  for (const n of ["scrollTo", "scroll", "scrollBy"]) wrap(window, n);

  for (const prop of ["scrollTop", "scrollLeft"]) {
    const d = Object.getOwnPropertyDescriptor(Element.prototype, prop);
    Object.defineProperty(Element.prototype, prop, {
      ...d,
      set(v) {
        if (allowed()) d.set.call(this, v);
      },
    });
  }

  const focus = HTMLElement.prototype.focus;
  HTMLElement.prototype.focus = function (o) {
    return focus.call(this, allowed() ? o : { ...o, preventScroll: true });
  };

  try {
    history.scrollRestoration = "manual";
  } catch {}

  const style = document.createElement("style");
  style.textContent = "* { overflow-anchor: none !important; }";
  (document.head || document.documentElement).appendChild(style);
})();
