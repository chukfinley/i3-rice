-- colors.lua — derive an Awesome colour scheme from the wallpaper palette.
-- Reads ~/.cache/chuk/colors.txt (written by scripts/chuk-colors) and maps it
-- onto beautiful theme keys. Falls back to a fixed dark theme if unavailable.
-- Our own minimal pywal replacement; no external theming dependency.

local home = os.getenv("HOME") or "/home/user"
local cache = home .. "/.cache/chuk/colors.txt"

local function rgb(hex)
	return tonumber(hex:sub(2, 3), 16),
	       tonumber(hex:sub(4, 5), 16),
	       tonumber(hex:sub(6, 7), 16)
end

local function luminance(hex)
	local r, g, b = rgb(hex)
	return 0.2126 * r + 0.7152 * g + 0.0722 * b
end

local function saturation(hex)
	local r, g, b = rgb(hex)
	local mx, mn = math.max(r, g, b), math.min(r, g, b)
	if mx == 0 then return 0 end
	return (mx - mn) / mx
end

-- mix hex toward target (0 = hex, 1 = target)
local function mix(hex, target, f)
	local r, g, b = rgb(hex)
	local tr, tg, tb = rgb(target)
	local function m(a, c) return math.floor(a + (c - a) * f + 0.5) end
	return string.format("#%02X%02X%02X", m(r, tr), m(g, tg), m(b, tb))
end

local BLACK, WHITE = "#000000", "#FFFFFF"

local fallback = {
	bg_normal = "#0f1114", bg_focus = "#2a2f38",
	bg_urgent = "#c15c5c", bg_minimize = "#1a1e25",
	fg_normal = "#d1d5db", fg_focus = "#f5f5f5",
	fg_urgent = "#ffffff", fg_minimize = "#9aa1ac",
	border_normal = "#111418", border_focus = "#7d8796",
	border_marked = "#c15c5c", accent = "#7d8796",
	palette = {},
}

local function read_palette()
	local f = io.open(cache, "r")
	if not f then return nil end
	local t = {}
	for line in f:lines() do
		local hex = line:match("#%x%x%x%x%x%x")
		if hex then t[#t + 1] = hex:upper() end
	end
	f:close()
	if #t == 0 then return nil end
	return t
end

local pal = read_palette()
if not pal then return fallback end

table.sort(pal, function(a, b) return luminance(a) < luminance(b) end)
local darkest, lightest = pal[1], pal[#pal]

-- accent = most saturated colour in the palette
local accent, best = pal[1], -1
for _, h in ipairs(pal) do
	local s = saturation(h)
	if s > best then best, accent = s, h end
end

-- Tint the dark backgrounds with the accent hue instead of pure black,
-- so the whole scheme carries the wallpaper's character.
return {
	bg_normal     = mix(accent, BLACK, 0.90),
	bg_focus      = mix(accent, BLACK, 0.55),
	bg_urgent     = "#c15c5c",
	bg_minimize   = mix(accent, BLACK, 0.82),
	fg_normal     = mix(lightest, WHITE, 0.25),
	fg_focus      = "#FFFFFF",
	fg_urgent     = "#FFFFFF",
	fg_minimize   = mix(lightest, BLACK, 0.35),
	border_normal = mix(accent, BLACK, 0.80),
	border_focus  = accent,
	border_marked = "#c15c5c",
	accent        = accent,
	palette       = pal,
}
