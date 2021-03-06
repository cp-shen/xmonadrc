-- |
module XMonad.MyCfg.Keybindings (myKeys) where

import qualified Data.Map as M
import System.Exit
import XMonad
import XMonad.Actions.CycleRecentWS
import XMonad.Actions.CycleWS
import XMonad.Hooks.ManageDocks
import XMonad.MyCfg.Workspaces
import qualified XMonad.StackSet as W
import XMonad.Util.EZConfig
import XMonad.Util.Types

myKeys :: XConfig Layout -> M.Map (KeyMask, KeySym) (X ())
myKeys conf = M.union keyMap $ mkKeymap conf strKeyMap where

  keyMap = M.fromList $
    [ ((m .|. modMask conf, k), windows $ f i)
    | (i, k) <- zip wsList [xK_1 .. xK_9],
      (f, m) <- [(W.greedyView, 0), (W.shift, shiftMask)] ]
    ++
    [ ((modMask conf, xK_0), windows $ W.greedyView $ last wsList),
      ((modMask conf .|. shiftMask, xK_0), windows $ W.shift $ last wsList) ]
    where wsList = workspaces conf

  strKeyMap =
    [
      -- launch terminal
      ("M-S-<Return>", spawn $ terminal conf)

      -- kill a client
    , ("M-S-q", kill)

      -- change layouts
    , ("M-S-f", sendMessage NextLayout)
    --, ("M-S-f", sendMessage $ JumpToLayout "Fu")

      -- focus movement
    , ("M-j", windows W.focusDown)
    , ("M-k", windows W.focusUp)
    , ("M-<Space>", windows W.focusMaster)

      -- swap clients
    , ("M-S-j", windows W.swapDown)
    , ("M-S-k", windows W.swapUp)
    , ("M-S-<Space>", windows W.swapMaster)

      -- shrink and expand
    , ("M-S-h", sendMessage Shrink)
    , ("M-S-l", sendMessage Expand)

      -- toggle floating mode for clients
    , ("M-t", withFocused $ windows . W.sink)

      -- quit and restart
    , ("M-S-r", spawn $ terminal conf
        ++ " --hold -e sh -c 'xmonad --recompile && xmonad --restart && echo ok! '")
    , ("M-S-e", io exitSuccess )

      -- switch wotkspaces
    , ("M-[", moveTo Prev (Not emptyWS))
    , ("M-]", moveTo Next (Not emptyWS))
    , ("M-p", toggleRecentNonEmptyWS)
    , ("M-<Return>", windows $ W.greedyView wsTerminal)

      -- launch applications
    , ("M-w", spawn "google-chrome-stable")
    , ("M-e", spawn "emacsclient -c")
    , ("M-g", spawn $ terminal conf
        ++ " --class glances,Glances -e glances")

      -- volume control using pulsemixer
    , ("<XF86AudioMute>", spawn "pulsemixer --toggle-mute")
    , ("<XF86AudioLowerVolume>", spawn "pulsemixer --change-volume -5")
    , ("<XF86AudioRaiseVolume>", spawn "pulsemixer --change-volume +5")

      -- toogle status bar
    , ("M-S-b", sendMessage (ToggleStrut U) <+> spawn togglePolybarCmd)

      -- take a screenshot
    , ("M-S-<F1>", spawn "xfce4-screenshooter -r")
    ]
    where
      togglePolybarCmd = "polybar-msg cmd toggle"
      toggleXmobarCmd = "dbus-send"
            ++ " --session"
            ++ " --dest=org.Xmobar.Control"
            ++ " --type=method_call"
            ++ " --print-reply"
            ++ " /org/Xmobar/Control"
            ++ " org.Xmobar.Control.SendSignal"
            ++ " \"string:Toggle 0\""
