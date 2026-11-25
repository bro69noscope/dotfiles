#Include ..\apps\app-launchers.ahk
#Include ..\apps\misc.ahk
#Include ..\windows\chrome-windows.ahk
#Include ..\windows\grouped-apps-manager.ahk
#Include ..\apps\nvim-scratch\scratch.ahk

LeaderCommands := Map(
  ; `.,;` commands are just for more apps starting with the same letter
  ".d", ActivateAutoDuck,
  ",n", ActivateNotepad,
  ".n", ActivateOneNote,
  ".o", (*) => ActivateObsPortable(profile := "vcam"),
  ; regular single-letter commands
  "0", ActivateUngroupedChromeWindow,
  "1", ActivateBrowser1Window,
  "2", ActivateBrowser2Window,
  "3", ActivateBrowser3Window,
  ; "a", activateAgeOfEmpires2,
  "a", ActivateAlacritty,
  "B", ActivateBitwarden,
  "b", ActivateBraveBrowser,
  "c", ActivateLosslessCut,
  "C", ActivateCalculator,
  "d", ActivateDota2,
  "D", ActivateDiscord,
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
  "N", ActivateNeo4j,
  "n", ActivateNeovide,
  "o", (*) => ActivateObsProduction(),
  "O", (*) => ActivateObsPortable(profile := "ftp", moveChat := true),
  "P", ActivateAdminPowerShell,
  "p", ActivatePowerShell,
  ".p", ActivatePaint,
  "r", ActivateStreamDeck,
  "s", ActivateSpotify,
  "S", ActivateNllsMainServer,
  "T", (*) => ActivateStreamerBot(portableVersion := "ftp"),
  "t", (*) => ActivateStreamerBot(portableVersion := "production"),
  "u", ActivateOsu,
  "v", ActivateVLC,
  "V", ActivateVSCode,
  "W", ActivateWezTermSecondary,
  ".w", (*) => ActivateWezTermTertiary(),
  "w", ActivateWezTermPrimary,
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
