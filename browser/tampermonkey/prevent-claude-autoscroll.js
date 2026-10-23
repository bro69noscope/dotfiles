// ==UserScript==
// @name         Claude no auto-scroll
// @match        https://claude.ai/*
// @run-at       document-start
// @grant        none
// ==/UserScript==
(() => {
  let enabled = true;
  let lastUser = 0;
  const mark = () => {
    lastUser = performance.now();
  };
  for (const ev of ["wheel", "touchstart", "keydown", "pointerdown"])
    addEventListener(ev, mark, { capture: true, passive: true });

  // Alt+S toggles the block
  addEventListener(
    "keydown",
    (e) => {
      if (e.altKey && e.key.toLowerCase() === "s") {
        enabled = !enabled;
        console.log("[no-autoscroll]", enabled ? "ON" : "OFF");
      }
    },
    true,
  );

  // Programmatic scrolls only pass within 300 ms of a user input
  const allowed = () => !enabled || performance.now() - lastUser < 300;

  const wrap = (obj, name) => {
    const orig = obj[name];
    if (typeof orig !== "function") return;
    obj[name] = function (...a) {
      if (allowed()) return orig.apply(this, a);
    };
  };
  for (const n of ["scrollTo", "scroll", "scrollBy", "scrollIntoView"])
    wrap(Element.prototype, n);
  for (const n of ["scrollTo", "scroll", "scrollBy"]) wrap(window, n);

  const d = Object.getOwnPropertyDescriptor(Element.prototype, "scrollTop");
  Object.defineProperty(Element.prototype, "scrollTop", {
    ...d,
    set(v) {
      if (allowed()) d.set.call(this, v);
    },
  });
})();
