#Include ..\apps\app-launchers.ahk
#Include ..\apps\misc.ahk
#Include ..\windows\chrome-windows.ahk
#Include ..\windows\grouped-apps-manager.ahk
#Include ..\apps\nvim-scratch\scratch.ahk

LeaderCommands := Map(
  "0", ActivateUngroupedChromeWindow,
  "1", ActivateBrowser1Window,
  "2", ActivateBrowser2Window,
  "3", ActivateBrowser3Window,
  ; "a", activateAgeOfEmpires2,
  "a", ActivateAlacritty,
  "b", ActivateBraveBrowser,
  "B", ActivateBitwarden,
  "c", ActivateLosslessCut,
  "C", ActivateCalculator,
  "d", ActivateDota2,
  "D", ActivateDiscord,
  ".d", ActivateAutoDuck,
  "e", ActivateObsidian,
  "f", ActivateStreamFeedApp,
  "F", ActivateStreamFeedAppDebug,
  ".f", (*) => ActivateStreamFeedApp("center"),
  "g", ActivateSteam,
  "G", ActivateTobiiGhost,
  "h", ActivateGitBash,
  "i", ActivateImageGlass,
  "k", ActivateKovaaks,
  "l", ActivateDeadlock,
  "m", ActivateMailClient,
  "n", ActivateNeovide,
  "N", ActivateNeo4j,
  ".n", ActivateOneNote,
  ",n", ActivateNotepad,
  "o", (*) => ActivateObsProduction(),
  "O", (*) => ActivateObsPortable(profile := "ftp", moveChat := true),
  ".o", (*) => ActivateObsPortable(profile := "vcam"),
  "p", ActivatePowerShell,
  "P", ActivateAdminPowerShell,
  ".p", ActivatePaint,
  "r", ActivateStreamDeck,
  "s", ActivateSpotify,
  "S", ActivateNllsMainServer,
  "t", (*) => ActivateStreamerBot(portableVersion := "production"),
  "T", (*) => ActivateStreamerBot(portableVersion := "ftp"),
  "u", ActivateOsu,
  "v", ActivateVLC,
  "V", ActivateVSCode,
  "w", ActivateWezTermPrimary,
  "W", ActivateWezTermSecondary,
  ".w", (*) => ActivateWezTermTertiary(),
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
  ; `\` leader commands for script management
  "\qs", (*) => StopNvimScratch(),
  ; ``` leader commands for handling more than one app at once
  ; show grouped apps status
  "````", (*) => ShowOpenStreamApps(),
  ; close targeted groups with `c
  "``ca", (*) => CloseStreamApps(group := "all"),
  "``cA", (*) => CloseStreamApps(group := "all-but-obs-ftp"),
  "``cd", (*) => QuitStreamDeck(),
  "``co", (*) => CloseStreamApps(group := "obs"),
  "``cp", (*) => CloseStreamApps(group := "production"),
  "``cb", (*) => CloseStreamApps(group := "sbot"),
  ; start targeted groups with `s
  "``sa", (*) => StartStreamApps(group := "all"),
  "``sA", (*) => StartStreamApps(group := "all-but-obs-ftp"),
  "``so", (*) => StartStreamApps(group := "obs"),
  "``sp", (*) => StartStreamApps(group := "production"),
  "``sb", (*) => StartStreamApps(group := "sbot"),
  ; run every damn program at once with `Space
  "``Spacef", (*) => QuickSetup(mode := "full"),
  "``Spaces", (*) => QuickSetup(mode := "simple"),
)
