// ==UserScript==
// @name         Prevent PageLoadStop with ESC (C-q instead)
// @namespace    http://tampermonkey.net/
// @version      0.1
// @description  Prevents ESC key from stopping page loads but allows Ctrl+Q to send ESC
// @author       Loïc Villet
// @match        *://*/*
// @run-at       document-start
// @grant        none
// ==/UserScript==

(function() {
    'use strict';

    // Log when the script is first loaded with URL information
    const now = new Date();
    const time24h = now.toLocaleTimeString([], {hour12: false});
    const ms = now.getMilliseconds().toString().padStart(3, '0');
    const timestamp = time24h + '.' + ms;
    const pageUrl = window.location.href;
    const frameType = (window.top === window) ? 'main frame' : 'iframe';
    console.log(`ESC Key Blocker loaded: ${timestamp} | ${frameType} | ${pageUrl}`);

    // Flag to track if we're currently processing our own synthetic ESC event
    let processingOurEvent = false;

    function handleKeys(e) {
        // If we're currently processing our own event, don't do anything
        if (processingOurEvent) {
            return true; // Let it pass through
        }

        // Block normal ESC key
        if ((e.key === 'Escape' || e.keyCode === 27) && !e.ctrlKey && !e.altKey && !e.shiftKey) {
            e.stopPropagation();
            e.preventDefault();
            console.log('ESC key intercepted - default behavior prevented');
            return false;
        }

        // Detect Ctrl+Q and trigger a proper browser ESC function
        if (e.ctrlKey && (e.key === 'q' || e.keyCode === 81)) {
            console.log('Ctrl+Q detected - sending ESC key');
            e.stopPropagation();
            e.preventDefault();

            try {
                processingOurEvent = true;

                // Create a synthetic keyboard event
                const escEvent = new KeyboardEvent('keydown', {
                    key: 'Escape',
                    code: 'Escape',
                    keyCode: 27,
                    which: 27,
                    bubbles: true,
                    cancelable: true
                });

                // Target the appropriate element
                let target = document.activeElement || document.body || document;

                // Dispatch the ESC key event
                target.dispatchEvent(escEvent);
                console.log('Synthetic ESC key dispatched');

                // Reset processing flag after a small delay
                setTimeout(() => {
                    processingOurEvent = false;
                }, 150);

            } catch (err) {
                console.error('Failed to dispatch synthetic ESC key:', err);
                processingOurEvent = false; // Reset flag on error
            }

            return false;
        }

        // Let all other keys pass through normally
        return true;
    }

    // Single event listener is sufficient
    window.addEventListener('keydown', handleKeys, true);
})();
