const DEFAULT_PERCENT = 100;
const slider = document.getElementById("slider");
const num = document.getElementById("num");

function clamp(v) {
  return Math.min(500, Math.max(25, Number(v) || DEFAULT_PERCENT));
}

function render(percent) {
  slider.value = percent;
  num.value = percent;
}

async function save(percent) {
  percent = clamp(percent);
  render(percent);
  await chrome.storage.sync.set({ zoomPercent: percent });
}

chrome.storage.sync
  .get({ zoomPercent: DEFAULT_PERCENT })
  .then(({ zoomPercent }) => {
    render(zoomPercent);
  });

slider.addEventListener("input", () => save(slider.value));
num.addEventListener("change", () => save(num.value));
document
  .getElementById("reset")
  .addEventListener("click", () => save(DEFAULT_PERCENT));
