-- AwesomeWM config for i3-like workflow with dropdown menus.

pcall(require, "luarocks.loader")

local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
local wibox = require("wibox")
local beautiful = require("beautiful")
local naughty = require("naughty")
local menubar = require("menubar")
local hotkeys_popup = require("awful.hotkeys_popup")
require("awful.hotkeys_popup.keys")

if awesome.startup_errors then
    naughty.notify({
        preset = naughty.config.presets.critical,
        title = "Awesome startup errors",
        text = awesome.startup_errors,
    })
end

do
    local in_error = false
    awesome.connect_signal("debug::error", function(err)
        if in_error then
            return
        end
        in_error = true
        naughty.notify({
            preset = naughty.config.presets.critical,
            title = "Awesome runtime error",
            text = tostring(err),
        })
        in_error = false
    end)
end

local home = os.getenv("HOME") or "/home/user"
local terminal = "alacritty"
local modkey = "Mod4"

-- Wallpaper-derived colours (our own pywal replacement).
-- Falls back to a fixed dark theme if ~/.cache/chuk/colors.txt is missing.
local colors = dofile(home .. "/.config/awesome/colors.lua")

beautiful.init({
    font = "RobotoMono Nerd Font Bold 13",
    bg_normal = colors.bg_normal,
    bg_focus = colors.bg_focus,
    bg_urgent = colors.bg_urgent,
    bg_minimize = colors.bg_minimize,
    fg_normal = colors.fg_normal,
    fg_focus = colors.fg_focus,
    fg_urgent = colors.fg_urgent,
    fg_minimize = colors.fg_minimize,
    useless_gap = 6,
    border_width = 2,
    border_normal = colors.border_normal,
    border_focus = colors.border_focus,
    border_marked = colors.border_marked,
    menu_height = 28,
    menu_width = 260,
})

awful.layout.layouts = {
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.floating,
    awful.layout.suit.max,
}

local function trim_first_line(text)
    if not text then
        return ""
    end
    return text:match("([^\n]+)") or ""
end

local function make_command_widget(command, interval, fallback_markup)
    local widget = wibox.widget({
        align = "center",
        valign = "center",
        widget = wibox.widget.textbox,
    })

    awful.widget.watch(command, interval, function(_, stdout)
        local line = trim_first_line(stdout)
        if line == "" then
            widget.markup = fallback_markup
        else
            widget.markup = line
        end
    end, widget)

    return widget
end

local function run_once(command)
    awful.spawn.with_shell(
        string.format("pgrep -u $USER -fx %q > /dev/null || (%s)", command, command)
    )
end

local app_menu = {
    {"Apps (Rofi)", "rofi -show drun"},
    {"Terminal", terminal},
    {"File Manager", "caja"},
    {"Browser", "xdg-open https://duckduckgo.com"},
    {"Vicinae", home .. "/.local/bin/vicinae open"},
}

local system_menu = {
    {"Lock", home .. "/.local/bin/i3-lock-wrapper"},
    {"Reload Awesome", awesome.restart},
    {"Quit Awesome", function() awesome.quit() end},
}

local power_menu = {
    {"Suspend", "systemctl suspend"},
    {"Reboot", "systemctl reboot"},
    {"Power Off", "systemctl poweroff"},
}

local main_menu = awful.menu({
    items = {
        {"Applications", app_menu},
        {"System", system_menu},
        {"Power", power_menu},
    },
})

local launcher_widget = wibox.widget({
    markup = "<span color='#d1d5db'>MENU</span>",
    align = "center",
    valign = "center",
    widget = wibox.widget.textbox,
})

launcher_widget:buttons(gears.table.join(
    awful.button({}, 1, function()
        main_menu:toggle()
    end)
))

local taglist_buttons = gears.table.join(
    awful.button({}, 1, function(t)
        t:view_only()
    end),
    awful.button({modkey}, 1, function(t)
        if client.focus then
            client.focus:move_to_tag(t)
        end
    end),
    awful.button({}, 3, awful.tag.viewtoggle),
    awful.button({modkey}, 3, function(t)
        if client.focus then
            client.focus:toggle_tag(t)
        end
    end),
    awful.button({}, 4, function(t)
        awful.tag.viewnext(t.screen)
    end),
    awful.button({}, 5, function(t)
        awful.tag.viewprev(t.screen)
    end)
)

local tasklist_buttons = gears.table.join(
    awful.button({}, 1, function(c)
        c:activate({context = "tasklist", action = "toggle_minimization"})
    end),
    awful.button({}, 3, function()
        awful.menu.client_list({theme = {width = 360}})
    end),
    awful.button({}, 4, function()
        awful.client.focus.byidx(1)
    end),
    awful.button({}, 5, function()
        awful.client.focus.byidx(-1)
    end)
)

local cpu_widget = make_command_widget(
    "/usr/share/i3xrocks/scripts/cpu-usage",
    2,
    "<span color='#7b8394'>CPU --</span>"
)

local memory_widget = make_command_widget(
    "/usr/share/i3xrocks/scripts/memory",
    5,
    "<span color='#7b8394'>MEM --</span>"
)

local battery_widget = make_command_widget(
    "/usr/share/i3xrocks/scripts/battery",
    15,
    "<span color='#7b8394'>BAT --</span>"
)

local microphone_widget = make_command_widget(
    "/usr/share/i3xrocks/scripts/microphone",
    2,
    "<span color='#7b8394'>MIC --</span>"
)

local clock_widget = wibox.widget.textclock(
    "<span color='#d1d5db'>%d.%m %H:%M</span>",
    30
)

-- VPN (Tailscale) status button: green when up, red when down. Click = menu.
local vpn_widget = wibox.widget({
    align = "center",
    valign = "center",
    widget = wibox.widget.textbox,
    markup = "<span color='#7b8394'>VPN</span>",
})

local function vpn_update()
    awful.spawn.easy_async_with_shell(
        "tailscale status >/dev/null 2>&1 && echo up || echo down",
        function(out)
            if out:match("up") then
                vpn_widget.markup = "<span color='" .. colors.accent .. "'> VPN</span>"
            else
                vpn_widget.markup = "<span color='#c15c5c'> VPN</span>"
            end
        end
    )
end

vpn_widget:buttons(gears.table.join(
    awful.button({}, 1, function()
        awful.spawn.with_shell(home .. "/.local/bin/tailscale-menu")
        gears.timer.start_new(1.5, function() vpn_update(); return false end)
    end)
))

gears.timer({timeout = 10, autostart = true, call_now = true, callback = vpn_update})

-- Wallpaper: keep the shown image in sync with the palette colours were
-- derived from (~/.cache/chuk/wallpaper, written by chuk-colors).
local wall_dir = home .. "/pic/wal"

-- feh's ~/.fehbg is the single source of truth for the wallpaper path.
local function current_wallpaper()
    local f = io.open(home .. "/.fehbg", "r")
    if f then
        local body = f:read("*a")
        f:close()
        local w = body and body:match("'([^']+%.[jJpPgGeEnN]+)'")
        if w and gears.filesystem.file_readable(w) then
            return w
        end
    end
    -- fallback: whatever chuk-colors last cached
    local c = io.open(home .. "/.cache/chuk/wallpaper", "r")
    if c then
        local w = c:read("*l")
        c:close()
        if w and gears.filesystem.file_readable(w) then
            return w
        end
    end
    return nil
end

local function set_wallpaper(s)
    local w = current_wallpaper()
    if w then
        gears.wallpaper.maximized(w, s, false)
    end
end

-- Watch ~/.fehbg: when you change the wallpaper via feh, regenerate the
-- palette and reload so the whole theme follows the new wallpaper.
do
    local fehbg = home .. "/.fehbg"
    local last_mtime = nil
    gears.timer({
        timeout = 3,
        autostart = true,
        callback = function()
            -- cheap mtime check via `stat`
            awful.spawn.easy_async_with_shell(
                "stat -c %Y " .. fehbg .. " 2>/dev/null",
                function(out)
                    local m = tonumber(out)
                    if not m then return end
                    if last_mtime == nil then
                        last_mtime = m
                        return
                    end
                    if m ~= last_mtime then
                        last_mtime = m
                        awful.spawn.easy_async(
                            home .. "/.local/bin/chuk-colors",
                            function() awesome.restart() end
                        )
                    end
                end
            )
        end,
    })
end

awful.screen.connect_for_each_screen(function(s)
    set_wallpaper(s)
    awful.tag({"1", "2", "3", "4", "5", "6", "7", "8", "9"}, s, awful.layout.layouts[1])

    s.promptbox = awful.widget.prompt()
    s.layoutbox = awful.widget.layoutbox(s)
    s.layoutbox:buttons(gears.table.join(
        awful.button({}, 1, function()
            awful.layout.inc(1)
        end),
        awful.button({}, 3, function()
            awful.layout.inc(-1)
        end),
        awful.button({}, 4, function()
            awful.layout.inc(1)
        end),
        awful.button({}, 5, function()
            awful.layout.inc(-1)
        end)
    ))

    s.taglist = awful.widget.taglist({
        screen = s,
        filter = awful.widget.taglist.filter.all,
        buttons = taglist_buttons,
    })

    s.tasklist = awful.widget.tasklist({
        screen = s,
        filter = awful.widget.tasklist.filter.currenttags,
        buttons = tasklist_buttons,
    })

    s.wibar = awful.wibar({
        position = "top",
        screen = s,
        height = 32,
        bg = colors.bg_normal .. "dd",
        fg = colors.fg_normal,
    })

    local right_widgets = {
        layout = wibox.layout.fixed.horizontal,
        spacing = 8,
    }

    if s == screen.primary then
        table.insert(right_widgets, wibox.widget.systray())
    end

    table.insert(right_widgets, vpn_widget)
    table.insert(right_widgets, microphone_widget)
    table.insert(right_widgets, battery_widget)
    table.insert(right_widgets, memory_widget)
    table.insert(right_widgets, cpu_widget)
    table.insert(right_widgets, clock_widget)
    table.insert(right_widgets, s.layoutbox)

    s.wibar:setup({
        layout = wibox.layout.align.horizontal,
        {
            layout = wibox.layout.fixed.horizontal,
            spacing = 8,
            launcher_widget,
            s.taglist,
            s.promptbox,
        },
        s.tasklist,
        right_widgets,
    })
end)

menubar.utils.terminal = terminal

local function move_client_to_relative_screen(delta)
    local c = client.focus
    if not c then
        return
    end

    local count = screen.count()
    if count < 2 then
        return
    end

    local current = c.screen.index
    local target = ((current - 1 + delta) % count) + 1
    local target_screen = screen[target]
    if not target_screen then
        return
    end

    c:move_to_screen(target_screen)
    c:raise()
    c:activate({context = "key.unminimize"})
end

local globalkeys = gears.table.join(
    awful.key({modkey}, "s", hotkeys_popup.show_help,
        {description = "show hotkeys", group = "awesome"}),

    awful.key({modkey}, "Left", function()
        awful.screen.focus_relative(-1)
    end, {description = "focus previous screen", group = "screen"}),

    awful.key({modkey}, "Right", function()
        awful.screen.focus_relative(1)
    end, {description = "focus next screen", group = "screen"}),

    awful.key({modkey}, "Return", function()
        awful.spawn(terminal)
    end, {description = "open terminal", group = "launcher"}),

    awful.key({modkey, "Shift"}, "d", function()
        awful.spawn.with_shell(home .. "/.local/bin/vicinae open")
    end, {description = "vicinae launcher", group = "launcher"}),

    awful.key({modkey}, "w", function()
        awful.spawn.with_shell(home .. "/.local/bin/i3-lock-wrapper")
    end, {description = "lock screen", group = "system"}),

    awful.key({modkey}, "q", function()
        if client.focus then
            client.focus:kill()
        end
    end, {description = "close focused window", group = "client"}),

    awful.key({modkey, "Shift"}, "space", function()
        if client.focus then
            client.focus.floating = not client.focus.floating
            client.focus:raise()
        end
    end, {description = "toggle floating", group = "layout"}),

    awful.key({modkey, "Shift"}, "Left", function()
        move_client_to_relative_screen(-1)
    end, {description = "move window to left screen", group = "client"}),

    awful.key({modkey, "Shift"}, "Right", function()
        move_client_to_relative_screen(1)
    end, {description = "move window to right screen", group = "client"}),

    awful.key({modkey, "Shift"}, "v", function()
        awful.spawn.with_shell(home .. "/.local/bin/tailscale-menu")
    end, {description = "open tailscale menu", group = "launcher"}),

    awful.key({modkey}, "r", function()
        awful.spawn.with_shell(home .. "/.local/bin/plauder")
    end, {description = "voice input", group = "launcher"}),

    awful.key({modkey}, "e", function()
        awful.spawn.with_shell("skippy-xd --expose --desktop -1 --toggle")
    end, {description = "window expose (skippy)", group = "launcher"}),

    awful.key({modkey}, "o", function()
        awful.spawn.with_shell(home .. "/git/linux-ocr/capture.sh")
    end, {description = "screen region OCR", group = "launcher"}),

    awful.key({modkey}, "space", function()
        awful.layout.inc(1)
    end, {description = "next layout", group = "layout"}),

    awful.key({modkey, "Control"}, "space", function()
        awful.layout.inc(-1)
    end, {description = "previous layout", group = "layout"}),

    awful.key({modkey}, "equal", function()
        awful.tag.incmwfact(0.05)
    end, {description = "grow master width", group = "layout"}),

    awful.key({modkey}, "minus", function()
        awful.tag.incmwfact(-0.05)
    end, {description = "shrink master width", group = "layout"}),

    awful.key({modkey}, "Tab", function()
        awful.client.focus.history.previous()
        if client.focus then
            client.focus:raise()
        end
    end, {description = "focus previous client", group = "client"})
)

for i = 1, 9 do
    globalkeys = gears.table.join(globalkeys,
        awful.key({modkey}, "#" .. i + 9, function()
            local s = awful.screen.focused()
            local tag = s.tags[i]
            if tag then
                tag:view_only()
            end
        end, {description = "view workspace " .. i, group = "workspace"}),

        awful.key({modkey, "Shift"}, "#" .. i + 9, function()
            if not client.focus then
                return
            end
            local tag = client.focus.screen.tags[i]
            if tag then
                client.focus:move_to_tag(tag)
                tag:view_only()
            end
        end, {description = "move window to workspace " .. i, group = "workspace"})
    )
end

local clientkeys = gears.table.join(
    awful.key({modkey}, "f", function(c)
        c.fullscreen = not c.fullscreen
        c:raise()
    end, {description = "toggle fullscreen", group = "client"}),

    awful.key({modkey, "Control"}, "space", awful.client.floating.toggle,
        {description = "toggle floating", group = "client"}),

    awful.key({modkey}, "n", function(c)
        c.minimized = true
    end, {description = "minimize", group = "client"}),

    awful.key({modkey}, "m", function(c)
        c.maximized = not c.maximized
        c:raise()
    end, {description = "maximize", group = "client"})
)

local clientbuttons = gears.table.join(
    awful.button({}, 1, function(c)
        c:activate({context = "mouse_click"})
    end),
    awful.button({modkey}, 1, function(c)
        c:activate({context = "mouse_click", action = "mouse_move"})
    end),
    awful.button({modkey}, 3, function(c)
        c:activate({context = "mouse_click", action = "mouse_resize"})
    end)
)

root.buttons(gears.table.join(
    awful.button({}, 3, function()
        main_menu:toggle()
    end),
    awful.button({}, 4, awful.tag.viewnext),
    awful.button({}, 5, awful.tag.viewprev)
))

root.keys(globalkeys)

awful.rules.rules = {
    {
        rule = {},
        properties = {
            border_width = beautiful.border_width,
            border_color = beautiful.border_normal,
            focus = awful.client.focus.filter,
            raise = true,
            keys = clientkeys,
            buttons = clientbuttons,
            screen = awful.screen.preferred,
            placement = awful.placement.no_overlap + awful.placement.no_offscreen,
        },
    },
    {
        rule_any = {
            instance = {
                "copyq",
                "pinentry",
            },
            class = {
                "Arandr",
                "Blueman-manager",
                "Nm-connection-editor",
                "Pavucontrol",
                "feh",
            },
            name = {
                "Event Tester",
            },
            role = {
                "pop-up",
            },
        },
        properties = {floating = true},
    },

    -- Browser (Zen) always on tag 1
    {
        rule = {class = "zen"},
        properties = {tag = "1"},
    },

    -- Spotify always on tag 9
    {
        rule_any = {class = {"Spotify", "spotify"}},
        properties = {tag = "9"},
    },

    -- Signal autostarts minimized (to tray)
    {
        rule = {class = "Signal"},
        properties = {minimized = true},
    },
}

client.connect_signal("manage", function(c)
    if awesome.startup and not c.size_hints.user_position and not c.size_hints.program_position then
        awful.placement.no_offscreen(c)
    end
end)

client.connect_signal("request::titlebars", function(c)
    local buttons = gears.table.join(
        awful.button({}, 1, function()
            c:activate({context = "titlebar", action = "mouse_move"})
        end),
        awful.button({}, 3, function()
            c:activate({context = "titlebar", action = "mouse_resize"})
        end)
    )

    awful.titlebar(c):setup({
        {awful.titlebar.widget.iconwidget(c), buttons = buttons, layout = wibox.layout.fixed.horizontal},
        {align = "center", widget = awful.titlebar.widget.titlewidget(c)},
        {
            awful.titlebar.widget.floatingbutton(c),
            awful.titlebar.widget.maximizedbutton(c),
            awful.titlebar.widget.stickybutton(c),
            awful.titlebar.widget.ontopbutton(c),
            awful.titlebar.widget.closebutton(c),
            layout = wibox.layout.fixed.horizontal,
        },
        layout = wibox.layout.align.horizontal,
    })
end)

client.connect_signal("mouse::enter", function(c)
    c:activate({context = "mouse_enter", raise = false})
end)

client.connect_signal("focus", function(c)
    c.border_color = beautiful.border_focus
end)

client.connect_signal("unfocus", function(c)
    c.border_color = beautiful.border_normal
end)

awful.spawn.with_shell(home .. "/.local/bin/picom-restart")
run_once("flameshot")
run_once("dunst")
run_once("signal-desktop --start-in-tray")
run_once("redshift")
run_once("vicinae server")
run_once("skippy-xd --start-daemon")
-- dropped: conky (unused), greenclip (557MB RAM leak; vicinae clipboard instead)
