module Lib (entryPoint) where

import XMonad
import qualified XMonad.StackSet as W
import XMonad.Actions.CycleWS
import XMonad.Actions.CycleRecentWS
import XMonad.Util.EZConfig
import XMonad.Layout.ThreeColumns
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.EwmhDesktops
import System.Exit
import XMonad.Hooks.StatusBar
import XMonad.Hooks.StatusBar.PP
import XMonad.Hooks.DynamicLog
import XMonad.Util.Loggers
import XMonad.Hooks.ManageHelpers
import XMonad.Layout.NoBorders
import qualified ColorSchemes.OneDark as Cs

entryPoint :: IO ()
entryPoint = xmonad
-- $ ewmhFullscreen
  $ ewmh
  $ withEasySB (statusBarProp "xmobar" (pure myXmobarPP)) toggleStrutsKey
  $ myConfig
  where toggleStrutsKey XConfig { modMask = m } = (shiftMask + m , xK_b)

myManageHook :: ManageHook
myManageHook = composeAll
    [ className =? "Gimp" --> doFloat
    , isDialog            --> doFloat
    ]

myXmobarPP :: PP
myXmobarPP = def
    {
      ppSep             = magenta " • "
    , ppTitleSanitize   = xmobarStrip

    , ppCurrent         = white . wrap " " "" . xmobarBorder "Top" "#8be9fd" 2
    , ppVisible         = white . wrap " " ""
    , ppHidden          = white . wrap " " ""
    , ppHiddenNoWindows = lowWhite . wrap " " ""
    , ppUrgent          = red . wrap (yellow "!") (yellow "!")

    , ppOrder           = \(ws : l : cur_win : wins : _) -> [ws, l, wins]
    , ppExtras          = [logTitles formatFocused formatUnfocused]
    }
  where
    formatFocused   = wrap (white    "[") (white    "]") . magenta . ppWindow
    formatUnfocused = wrap (lowWhite "[") (lowWhite "]") . blue    . ppWindow

    -- | Windows should have *some* title, which should not not exceed a
    -- sane length.
    ppWindow :: String -> String
    ppWindow = xmobarRaw . (\w -> if null w then "untitled" else w) . shorten 30

    blue, lowWhite, magenta, red, white, yellow :: String -> String
    magenta  = xmobarColor Cs.magenta ""
    blue     = xmobarColor Cs.blue ""
    white    = xmobarColor Cs.white ""
    yellow   = xmobarColor Cs.yellow ""
    red      = xmobarColor Cs.red ""
    lowWhite = xmobarColor Cs.lowWhite ""


myConfig = def
  {
    modMask = mod4Mask
  , terminal = "alacritty"
  , layoutHook = myLayouts
  , manageHook = myManageHook
  , normalBorderColor = Cs.lowWhite
  , focusedBorderColor = Cs.magenta
  }

  `additionalKeysP`
  [
    -- launch terminal
    ("M-S-<Return>", spawn $ terminal myConfig)

    -- kill a client
  , ("M-S-q", kill)

    -- change layouts
  , ("M-<Space>", sendMessage NextLayout)
  --, ("M-S-<Space>", setLayout myLayouts)

    -- focus movement
  , ("M-j", windows W.focusDown)
  , ("M-k", windows W.focusUp)
  , ("M-m", windows W.focusMaster)

    -- swap clients
  , ("M-S-j", windows W.swapDown)
  , ("M-S-k", windows W.swapUp)
  , ("M-S-m", windows W.swapMaster)

    -- shrink and expand
  , ("M-S-h", sendMessage Shrink)
  , ("M-S-l", sendMessage Expand)

    -- toggle floating mode for clients
  , ("M-t", withFocused $ windows . W.sink)

    -- quit and restart
  , ("M-S-r", spawn $ terminal myConfig ++ " --hold -e sh -c 'xmonad --recompile && xmonad --restart && echo ok! '")
  , ("M-S-e", io (exitWith ExitSuccess))

    -- switch wotkspaces
  , ("M-[", moveTo Prev (Not emptyWS))
  , ("M-]", moveTo Next (Not emptyWS))
  , ("M-p", toggleRecentNonEmptyWS)

    -- launch applications
  , ("M-w", spawn "firefox")
  , ("M-e", spawn "emacsclient -c")

    -- volume control using pulsemixer
  , ("<XF86AudioMute>", spawn "pulsemixer --toggle-mute")
  , ("<XF86AudioLowerVolume>", spawn "pulsemixer --change-volume -5")
  , ("<XF86AudioRaiseVolume>", spawn "pulsemixer --change-volume +5")

    -- other misc key bindings
  -- , ("M-S-s", shellPrompt def)
  ]

  -- mod-[1..9] %! Switch to workspace N
  -- mod-shift-[1..9] %! Move client to workspace N
  `additionalKeys`
    [((m .|. modMask myConfig, k), windows $ f i)
        | (i, k) <- zip (XMonad.workspaces myConfig) [xK_1 .. xK_9]
        , (f, m) <- [(W.greedyView, 0), (W.shift, shiftMask)]]

  -- mod-{w,e,r} %! Switch to physical/Xinerama screens 1, 2, or 3
  -- mod-shift-{w,e,r} %! Move client to screen 1, 2, or 3
  -- `additionalKeys`
  --   [((m .|. modMask myConfig, key), screenWorkspace sc >>= flip whenJust (windows . f))
  --       | (key, sc) <- zip [xK_w, xK_e, xK_r] [0..]
  --       , (f, m) <- [(W.view, 0), (W.shift, shiftMask)]]

myLayouts =
  smartBorders tiled
  ||| smartBorders (Mirror tiled)
  ||| smartBorders threeCol
  ||| noBorders Full
  where
    threeCol = ThreeColMid nmaster delta ratio
    tiled = Tall nmaster delta ratio
    nmaster = 1
    ratio = 1/2
    delta = 3/100
