-- @path: sys/tags.lua
-- @author: redskaber
-- @date: 2026-08-20
-- @description: Tag registry — single source of truth for window tags

hl.window_rule({
	match = { class = "^([Ff]irefox|org.mozilla.firefox|[Ff]irefox-esr|[Ff]irefox-bin)$" },
	tag = "browser",
})
hl.window_rule({
	match = { class = "^([Gg]oogle-chrome(-beta|-dev|-stable|-unstable)?)$" },
	tag = "browser",
})
hl.window_rule({
	match = { class = "^(chrome-.+-Default)$" },
	tag = "browser",
})
hl.window_rule({
	match = { class = "^([Cc]hromium)$" },
	tag = "browser",
})
hl.window_rule({
	match = { class = "^([Mm]icrosoft-edge(-stable|-beta|-dev|-unstable))$" },
	tag = "browser",
})
hl.window_rule({
	match = { class = "^(Brave-browser(-beta|-dev|-unstable)?)$" },
	tag = "browser",
})
hl.window_rule({
	match = { class = "^([Tt]horium-browser|[Cc]achy-browser)$" },
	tag = "browser",
})
hl.window_rule({
	match = { class = "^(zen-alpha|zen|zen-browser)$" },
	tag = "browser",
})
hl.window_rule({
	match = { class = "^([Qq]utebrowser)$" },
	tag = "browser",
})
hl.window_rule({
	match = { class = "^(Alacritty|kitty|kitty-dropterm|wezterm|foot|ghostty)$" },
	tag = "terminal",
})
hl.window_rule({
	match = { class = "^([Dd]iscord|[Ww]ebCord|[Vv]esktop)$" },
	tag = "im",
})
hl.window_rule({
	match = { class = "^([Ff]erdium)$" },
	tag = "im",
})
hl.window_rule({
	match = { class = "^([Ww]hatsapp-for-linux|wechat|qq)$" },
	tag = "im",
})
hl.window_rule({
	match = { class = "^(ZapZap|com.rtosta.zapzap)$" },
	tag = "im",
})
hl.window_rule({
	match = { class = "^(org.telegram.desktop|io.github.tdesktop_x64.TDesktop)$" },
	tag = "im",
})
hl.window_rule({
	match = { class = "^(teams-for-linux|slack)$" },
	tag = "im",
})
hl.window_rule({
	match = { class = "^(im.riot.Riot|Element)$" },
	tag = "im",
})
hl.window_rule({
	match = { class = "^([Tt]hunderbird|org.gnome.Evolution)$" },
	tag = "email",
})
hl.window_rule({
	match = { class = "^(eu.betterbird.Betterbird)$" },
	tag = "email",
})
hl.window_rule({
	match = { class = "^(codium|codium-url-handler|VSCodium)$" },
	tag = "projects",
})
hl.window_rule({
	match = { class = "^(VSCode|code|code-url-handler|zeditor)$" },
	tag = "projects",
})
hl.window_rule({
	match = { class = "^(jetbrains-.+)$" },
	tag = "projects",
})
hl.window_rule({
	match = { class = "^([Tt]hunar|org.gnome.Nautilus|[Pp]cmanfm-qt|nemo)$" },
	tag = "file-manager",
})
hl.window_rule({
	match = { class = "^(app.drey.Warp)$" },
	tag = "file-manager",
})
hl.window_rule({
	match = { class = "^([Aa]udacious|ncspot|listen1|lx-music-desktop)$" },
	tag = "multimedia",
})
hl.window_rule({
	match = { class = "^([Mm]pv|vlc|com.github.rafostar.Clapper)$" },
	tag = "multimedia-video",
})
hl.window_rule({
	match = { class = "^([Oo]bs|[Kk]azumi|com.obsproject.Studio)$" },
	tag = "screenshare",
})
hl.window_rule({
	match = { class = "^(easyeffects|com.github.wwmm.easyeffects)$" },
	tag = "screenshare",
})
hl.window_rule({
	match = { class = "^(gamescope)$" },
	tag = "games",
})
hl.window_rule({
	match = { class = "^(steam_app_\\d+)$" },
	tag = "games",
})
hl.window_rule({
	match = { class = "^(prismlauncher)$" },
	tag = "games",
})
hl.window_rule({
	match = { class = "^([Ss]team)$" },
	tag = "gamestore",
})
hl.window_rule({
	match = { class = "^(lutris)$" },
	tag = "gamestore",
})
hl.window_rule({
	match = { class = "^(com.heroicgameslauncher.hgl)$" },
	tag = "gamestore",
})
hl.window_rule({
	match = { class = "^(evince|eog|org.gnome.Loupe|org.gnome.Evince)$" },
	tag = "viewer",
})
hl.window_rule({
	match = { class = "^(gnome-system-monitor|org.gnome.SystemMonitor|io.missioncenter.MissionCenter)$" },
	tag = "viewer",
})
hl.window_rule({
	match = { class = "^(org.gnome.TextEditor|mousepad|gedit|xed|kate)$" },
	tag = "text-editor",
})
hl.window_rule({
	match = { class = "^([Oo]bsidian|logseq|org.gnome.Gnote)$" },
	tag = "notes",
})
hl.window_rule({
	match = { class = "^(rbw|seahorse)$" },
	tag = "utils",
})
hl.window_rule({
	match = { class = "^(clash-verge|qbittorrent)$" },
	tag = "utils",
})
hl.window_rule({
	match = { class = "^(virt-manager)$" },
	tag = "utils",
})
hl.window_rule({
	match = { class = "^(fcitx5-config-qt|fcitx5)$" },
	tag = "utils",
})
hl.window_rule({
	match = { class = "^(deluge|transmission-gtk|transmission-qt)$" },
	tag = "utils",
})
hl.window_rule({
	match = { class = "^(org.gnome.Calculator|[Qq]alculate-gtk|galculator)$" },
	tag = "calculator",
})
hl.window_rule({
	match = { class = "^(nm-applet|nm-connection-editor|blueman-manager)$" },
	tag = "settings",
})
hl.window_rule({
	match = { class = "^(qt5ct|qt6ct)$" },
	tag = "settings",
})
hl.window_rule({
	match = { class = "^([Bb]aobab|org.gnome.[Bb]aobab)$" },
	tag = "settings",
})
hl.window_rule({
	match = { class = "^(gnome-disks|wihotspot(-gui)?)$" },
	tag = "settings",
})
hl.window_rule({
	match = { class = "^(file-roller|org.gnome.FileRoller)$" },
	tag = "settings",
})
hl.window_rule({
	match = { class = "^(org.kde.polkit-kde-authentication-agent-1)$" },
	tag = "settings",
})
hl.window_rule({
	match = { class = "^(nwg-displays|nwg-look)$" },
	tag = "settings",
})
hl.window_rule({
	match = { class = "^(xdg-desktop-portal-gtk)$" },
	tag = "settings",
})
hl.window_rule({
	match = { class = "" },
	tag = "settings",
})
hl.window_rule({
	match = { class = "" },
	tag = "settings",
})
hl.window_rule({
	match = { class = "^(pavucontrol|org.pulseaudio.pavucontrol|com.saivert.pwvucontrol)$" },
	tag = "audio-mixer",
})
hl.window_rule({
	match = { class = "^([Ww]aytrogen|waypaper)$" },
	tag = "wallpaper",
})
hl.window_rule({
	match = { class = "^(swaync-control-center|swaync-notification-window|swaync-client)$" },
	tag = "notif",
})
hl.window_rule({
	match = { class = "" },
	tag = "pip",
})
hl.window_rule({
	match = { class = "" },
	tag = "auth-dialog",
})
hl.window_rule({
	match = { class = "" },
	tag = "auth-dialog",
})
hl.window_rule({
	match = { class = "" },
	tag = "file-dialog",
})
hl.window_rule({
	match = { class = "" },
	tag = "file-dialog",
})
hl.window_rule({
	match = { class = "" },
	tag = "file-dialog",
})
hl.window_rule({
	match = { class = "^(wechat|qq)$" },
	tag = "no-steal-focus",
})
hl.window_rule({
	match = { class = "^(jetbrains-.+)$" },
	tag = "no-steal-focus",
})
hl.window_rule({
	match = { class = "" },
	tag = "no-steal-focus",
})
hl.window_rule({
	match = { class = "^(vesktop)$" },
	tag = "suppress-activate",
})
hl.window_rule({
	match = { title = "^(Quick Cheat Sheet)$" },
	tag = "Help_Cheat",
})
hl.window_rule({
	match = { title = "^(Hyprland Settings)$" },
	tag = "Help_Settings",
})
hl.window_rule({
	match = { class = "" },
	tag = "keybindings",
})
