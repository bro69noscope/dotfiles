#Include app-launchers.ahk
#Include misc.ahk
#Include chrome-windows.ahk
#Include grouped-apps-manager.ahk

global LeaderCommands := Map(
  ; `., ,, ;,` commands are just for more apps starting with the same letter
  ",n", ActivateNotepad,
  ".m", WriteMessageDontResendAllCode,
  ".n", ActivateOneNote,
  ".o", (*) => ActivateOBSPortable(profile := "vcam"),
  ; regular single-letter commands
  "0", ActivateUngroupedChromeWindow,
  "1", ActivateBrowser1Window,
  "2", ActivateBrowser2Window,
  "3", ActivateBrowser3Window,
  "a", activateAgeOfEmpires2,
  "A", ActivateAlacritty,
  "B", ActivateBitwarden,
  "b", ActivateBraveBrowser,
  "c", ActivateLosslessCut,
  "D", ActivateAutoDuck,
  "d", ActivateDiscord,
  "f", ActivateSreamFeedApp,
  "F", ActivateSreamFeedAppDebug,
  "g", ActivateSteam,
  "G", ActivateTobiiGhost,
  "k", ActivateKovaaks,
  "l", ActivateDeadlock,
  "m", ActivateMailClient,
  "N", ActivateNeo4j,
  "n", ActivateNeovide,
  "o", (*) => ActivateOBS(),
  "O", (*) => ActivateOBSPortable(profile := "ftp", moveChat := true),
  "P", ActivateAdminPowerShell,
  "p", ActivatePowerShell,
  "r", ActivateStreamDeck,
  "s", ActivateSpotify,
  "T", (*) => ActivateStreamerBot(portableVersion := "ftp"),
  "t", (*) => ActivateStreamerBot(portableVersion := "production"),
  "u", ActivateOsu,
  "v", ActivateVLC,
  "V", ActivateVSCode,
  "W", (*) => ActivateWezTermTitled("WezTerm - secondary"),
  "w", ActivateWezTerm,
  "x", ActivateExplorer,
  "y", ActivatePyCharm,
  "z", ActivateZoom,
  ; special case script Reload command
  "RR", Reload,
  ; `Space` leader commands for manually changing program state
  "Space1", (*) => CaptureCurrentChromeWindow(1),
  "Space2", (*) => CaptureCurrentChromeWindow(2),
  "Space3", (*) => CaptureCurrentChromeWindow(3),
  "Space]", ResetChromeWindowList,
  ; `/` leader commands for utility functions
  "//", (*) => ReplaceClipboardSlashes("/"),
  "/\", (*) => ReplaceClipboardSlashes("\"),
  ; ``` leader commands for handling more than one app at once
  "``ca", (*) => CloseStreamApps(group := "all"),
  "``cd", (*) => QuitStreamDeck(),
  "``cp", (*) => CloseStreamApps(group := "production"),
  "``sa", (*) => StartStreamApps(group := "all"),
  "``sp", (*) => StartStreamApps(group := "production"),
  "``Spacef", (*) => QuickSetup(mode := "full"),
  "``Spaces", (*) => QuickSetup(mode := "simple"),
)
