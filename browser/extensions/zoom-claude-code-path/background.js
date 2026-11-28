const DEFAULT_PERCENT = 100;
const PATH_MATCH = "/code/";

async function getZoomFactor() {
  const { zoomPercent } = await chrome.storage.sync.get({
    zoomPercent: DEFAULT_PERCENT,
  });
  return zoomPercent / 100;
}

async function applyZoomIfNeeded(tabId, url) {
  if (!isTargetUrl(url)) return;

  try {
    await chrome.tabs.setZoomSettings(tabId, { scope: "per-tab" });
    await chrome.tabs.setZoom(tabId, await getZoomFactor());
  } catch (e) {
    console.warn("zoom failed", tabId, e);
  }
}

function isTargetUrl(url) {
  if (!url) return false;
  try {
    const u = new URL(url);
    return u.hostname === "claude.ai" && u.pathname.startsWith(PATH_MATCH);
  } catch {
    return false;
  }
}

// fires on full navigation
chrome.tabs.onUpdated.addListener((tabId, changeInfo, tab) => {
  if (changeInfo.status === "complete") {
    applyZoomIfNeeded(tabId, tab.url);
  }
});

// fires on client-side SPA navigation (claude.ai/code likely uses history.pushState)
if (chrome.webNavigation) {
  chrome.webNavigation.onHistoryStateUpdated.addListener((details) => {
    applyZoomIfNeeded(details.tabId, details.url);
  });
}

// re-apply to all open matching tabs when the setting changes
chrome.storage.onChanged.addListener(async (changes, area) => {
  if (area !== "sync" || !changes.zoomPercent) return;
  const tabs = await chrome.tabs.query({ url: "https://claude.ai/code*" });
  for (const tab of tabs) applyZoomIfNeeded(tab.id, tab.url);
});
