local termw, termh = term.getSize()
if termw < 80 or termh < 25 then error("Terminal size must be >= 80x25") end
local keysDown = {}
local lastKey = nil
local crash_on_gfx_fail = false
os.loadAPI("CCKit/CCLog.lua")

band = {}
bor = {}
bxor = {}
bnot = {}
blshift = {}
brshift = {}

setmetatable(band, {__sub = function(lhs)
    local mt = {lhs, __sub = function(self, b) return bit.band(self[1], b) end}
    return setmetatable(mt, mt)
end})

setmetatable(bor, {__sub = function(lhs)
    local mt = {lhs, __sub = function(self, b) return bit.bor(self[1], b) end}
    return setmetatable(mt, mt)
end})

setmetatable(bxor, {__sub = function(lhs)
    local mt = {lhs, __sub = function(self, b) return bit.bxor(self[1], b) end}
    return setmetatable(mt, mt)
end})

setmetatable(blshift, {__sub = function(lhs)
    local mt = {lhs, __sub = function(self, b) return bit.blshift(self[1], b) end}
    return setmetatable(mt, mt)
end})

setmetatable(brshift, {__sub = function(lhs)
    local mt = {lhs, __sub = function(self, b) return bit.blogic_rshift(self[1], b) end}
    return setmetatable(mt, mt)
end})

setmetatable(bnot, {__sub = function(_, rhs) return bit.bnot(rhs) end})

io_seek = {open = function(_sPath, _sMode)

    if _G.type( _sPath ) ~= "string" then
        error( "bad argument #1 (expected string, got " .. _G.type( _sPath ) .. ")", 2 )
    end
    if _sMode ~= nil and _G.type( _sMode ) ~= "string" then
        error( "bad argument #2 (expected string, got " .. _G.type( _sMode ) .. ")", 2 )
    end
	local sMode = _sMode or "r"
	local file, err = fs.open( _sPath, sMode )
	if not file then
		return nil, err
	end
	
	if sMode == "r"then
		return {
			bFileHandle = true,
            bClosed = false,		
            pos = 0,		
			close = function( self )
				file.close()
				self.bClosed = true
			end,
			read = function( self, _sFormat )
                local sFormat = _sFormat or "*l"
				if sFormat == "*l" then
                    local r = file.readLine()
                    self.pos = self.pos + string.len(r)
                    return r
				elseif sFormat == "*a" then
                    local r = file.readAll()
                    self.pos = self.pos + string.len(r)
                    return r
                elseif _G.type( sFormat ) == "number" then
                    self.pos = self.pos + sFormat
                    return file.read( sFormat )
				else
					error( "Unsupported format", 2 )
				end
				return nil
			end,
			lines = function( self )
				return function()
					local sLine = file.readLine()
					if sLine == nil then
						file.close()
						self.bClosed = true
                    end
                    self.pos = self.pos + string.len(sLine)
					return sLine
				end
            end,
            seek = function(self, whence, offset)
                whence = whence or "cur"
                offset = offset or 0
                if whence == "set" then
                    if offset < self.pos then
                        file.close()
                        file = fs.open(_sPath, sMode)
                        self.pos = 0
                    end
                    while self.pos < offset do
                        file.read()
                        self.pos = self.pos + 1
                    end
                elseif whence == "cur" then
                    local lastoff = self.pos
                    if lastoff + offset < self.pos then
                        file.close()
                        file = fs.open(_sPath, sMode)
                        self.pos = 0
                    end
                    while self.pos < lastoff + offset do
                        file.read()
                        self.pos = self.pos + 1
                    end
                elseif whence == "end" then
                    file.close()
                    file = fs.open(_sPath, "rb")
                    local sz = 0
                    while file.read() ~= nil do sz = sz + 1 end
                    file.close()
                    file = fs.open(_sPath, sMode)
                    self.pos = 0
                    while self.pos < sz + offset do
                        file.read()
                        self.pos = self.pos + 1
                    end
                end
                return self.pos
            end
		}
	elseif sMode == "w" or sMode == "a" then
		return {
			bFileHandle = true,
			bClosed = false,				
			close = function( self )
				file.close()
				self.bClosed = true
			end,
			write = function( self, ... )
                local nLimit = select("#", ... )
                for n = 1, nLimit do
				    file.write( select( n, ... ) )
                end
			end,
			flush = function( self )
				file.flush()
			end,
		}
	
	elseif sMode == "rb" then
		return {
			bFileHandle = true,
			bClosed = false,				
			close = function( self )
				file.close()
				self.bClosed = true
			end,
            read = function( self, c )
                if c then
                    local retval = ""
                    local oldpos = self.pos
                    while self.pos < oldpos + c do
                        retval = retval .. string.char(file.read())
                        self.pos = self.pos + 1
                    end
                    return retval
                else
                    self.pos = self.pos + 1
                    return file.read()
                end
            end,
            seek = function(self, whence, offset)
                whence = whence or "cur"
                offset = offset or 0
                if whence == "set" then
                    if offset < self.pos then
                        file.close()
                        file = fs.open(_sPath, sMode)
                        self.pos = 0
                    end
                    while self.pos < offset do
                        file.read()
                        self.pos = self.pos + 1
                    end
                elseif whence == "cur" then
                    local lastoff = self.pos
                    if lastoff + offset < self.pos then
                        file.close()
                        file = fs.open(_sPath, sMode)
                        self.pos = 0
                    end
                    while self.pos < lastoff + offset do
                        file.read()
                        self.pos = self.pos + 1
                    end
                elseif whence == "end" then
                    file.close()
                    file = fs.open(_sPath, "rb")
                    local sz = 0
                    while file.read() ~= nil do sz = sz + 1 end
                    file.close()
                    file = fs.open(_sPath, sMode)
                    self.pos = 0
                    while self.pos < sz + offset do
                        file.read()
                        self.pos = self.pos + 1
                    end
                end
                return self.pos
            end
		}
		
	elseif sMode == "wb" or sMode == "ab" then
		return {
			bFileHandle = true,
			bClosed = false,				
			close = function( self )
				file.close()
				self.bClosed = true
			end,
			write = function( self, ... )
                local nLimit = select("#", ... )
                for n = 1, nLimit do
				    file.write( select( n, ... ) )
                end
			end,
			flush = function( self )
				file.flush()
			end,
		}
	
	else
		file.close()
		error( "Unsupported mode", 2 )
		
    end
end}--]] io_seek = io

function platform_sleep(t)
    -- for what pvrpose
    platform_kbd_tick()
	os.sleep(t)
end

function platform_beep(freq)
    -- do nothing
    emu_debug(2, "BEEP " .. freq)
end

function platform_key_down(v)
    return false
end

local debugger = peripheral.wrap("left")
local dw, dh

function emu_debug(level, s, tb)
    if debugger then
        if not dw then dw, dh = debugger.getSize() end
        local x, y = debugger.getCursorPos()
        if y >= dh then
            debugger.scroll(y - dh + 1)
            y = dh - 1
        end
        debugger.setCursorPos(1, y + 1)
        debugger.write(s)
	end
end

local last_key = nil
local keys_to_char = {
    [keys.enter] = 0x0D,
    [keys.backspace] = 0x7F
}

-- non-blocking, returns (ascii char, bios scan code) or nil on none
local nb = 0
function platform_getc(queue)
    if queue then
        os.queueEvent("noblock")
        nb = nb + 1
    end
    local ev, c = os.pullEvent()
    emu_debug(2, "nb: " .. nb .. ", Event: " .. ev)
    if ev == "key" then
        if c >= 0x80 then return nil end
        emu_debug(2, string.format("key %d %d", c, keys_to_char[c] or 0))
        last_key = c
        if keys_to_char[c] then return keys_to_char[c], c else return nil end
    elseif ev == "char" then
        emu_debug(2, string.format("char %s %d", c, string.byte(c)))
        return string.byte(c), last_key
    elseif ev == "key_up" then
        last_key = nil
    elseif ev == "noblock" then
        nb = nb - 1
        return -1
    end
    return nil
end

function platform_error(msg)
    platform_finish()
    term.clear()
    term.setCursorPos(1, 1)
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.red)
    if CCLog then CCLog.default:traceback("lunatic86", msg) end
    if CCLog then CCLog.default:close() end
    printError(msg)
    error(msg, 2)
end

function platform_kbd_tick()
    emu_debug(2, "Keyboard tick")
    local getmore = true
    local first = true
    repeat
		local ch, code = platform_getc(first)
		if ch ~= nil and ch ~= -1 then
            kbd_send_ibm(code, ch)
            getmore = true
        elseif ch == -1 then getmore = false 
        else getmore = true end
        first = false
	until not getmore
end

function platform_render_cga_mono(vram, addr)
	platform_kbd_tick()
    emu_debug(2, "Graphics mode: CGA Mono")
    if not term.getGraphicsMode then if crash_on_gfx_fail then error("Graphics modes require CraftOS-PC v1.2 or later.") else return end end
    --term.setGraphicsMode(true)
end

local cga_palettes = {
    [0] = {[0] = 1, 4, 16, 64},
    {[0] = 1, 1024, 4096, 16384},
    {[0] = 1, 8, 32, 128},
    {[0] = 1, 2048, 8192, 32768},
    {[0] = 1, 8, 16, 128},
    {[0] = 1, 2048, 4096, 32768}
}

function platform_render_cga_color(vram, addr, mode)
    platform_kbd_tick()
    emu_debug(2, "Graphics mode: CGA Color")
    if not term.getGraphicsMode then if crash_on_gfx_fail then error("Graphics modes require CraftOS-PC v1.2 or later.") else return end end
    if not term.getGraphicsMode() then term.setGraphicsMode(true) end
    local pnum = ((cga_get_palette() -band- 0x30) -brshift- 4) + (mode == 5 and 2 or 0)
    emu_debug(2, "using palette " .. pnum)
    local palette = cga_palettes[pnum]
    local dlines = video_pop_dirty_lines()
	for y,v in pairs(dlines) do
		local base = addr + (y * 80)
		for x=0,79 do
            local chr = vram[base + x] or 0
            term.setPixel(x*4, y, palette[(chr -brshift- 6) -band- 3])
            term.setPixel(x*4+1, y, palette[(chr -brshift- 4) -band- 3])
            term.setPixel(x*4+2, y, palette[(chr -brshift- 2) -band- 3])
            term.setPixel(x*4+3, y, palette[(chr -brshift- 0) -band- 3])
		end
	end
end

function platform_render_mcga_13h(vram, addr)
	platform_kbd_tick()
    emu_debug(2, "Graphics mode: MCGA")
    if not term.getGraphicsMode then if crash_on_gfx_fail then error("Graphics modes require CraftOS-PC v1.2 or later.") else return end end
    --term.setGraphicsMode(true)
end

function platform_render_pcjr_160(vram, addr)
	platform_kbd_tick()
    emu_debug(2, "Graphics mode: PCjr 160x200")
    if not term.getGraphicsMode then if crash_on_gfx_fail then error("Graphics modes require CraftOS-PC v1.2 or later.") else return end end
    --term.setGraphicsMode(true)
end

function platform_render_pcjr_320(vram, addr)
	platform_kbd_tick()
    emu_debug(2, "Graphics mode: PCjr 320x200")
    if not term.getGraphicsMode then if crash_on_gfx_fail then error("Graphics modes require CraftOS-PC v1.2 or later.") else return end end
    --term.setGraphicsMode(true)
end

function platform_render_text(vram, addr, width, height, pitch)
	platform_kbd_tick()
    if term.getGraphicsMode and term.getGraphicsMode() then term.setGraphicsMode(false) end
    local dlines = video_pop_dirty_lines()
    local cx, cy = term.getCursorPos()
    term.setCursorBlink(false)
    for y,v in pairs(dlines) do
    --for y = 0,height-1 do
		local base = addr + (y * pitch)
		for x=0,width-1 do
			local chr = vram[base + x*2] or 0
            local atr = vram[base + x*2 + 1] or 0
            local fg = bit.band(atr, 0x0F)
            local bg = bit.band(bit.blogic_rshift(atr, 4), 0x0F)
            term.setCursorPos(x+1, y+1)
            term.blit(string.char(chr), string.sub("0123456789abcdef", fg+1, fg+1), string.sub("0123456789abcdef", bg+1, bg+1))
		end
    end
    term.setCursorPos(cx, cy)
    term.setCursorBlink(true)
end

local cmap = {}
for k,v in pairs(colors) do if type(v) == "number" then
    cmap[k] = {}
    cmap[k].r, cmap[k].g, cmap[k].b = term.getPaletteColor(v)
    cmap[k].r = cmap[k].r * 255
    cmap[k].g = cmap[k].g * 255
    cmap[k].b = cmap[k].b * 255
end end

function platform_finish()
    for k,v in pairs(cmap) do term.setPaletteColor(colors[k], v.r / 255, v.g / 255, v.b / 255) end
    if term.getGraphicsMode and term.getGraphicsMode() then term.setGraphicsMode(false) end
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    --term.clear()
    --term.setCursorPos(1, 1)
end

function setEGAColors()
    term.setPaletteColor(1, 0, 0, 0)
    term.setPaletteColor(2, 0, 0, 0.625)
    term.setPaletteColor(4, 0, 0.625, 0)
    term.setPaletteColor(8, 0, 0.625, 0.625)
    term.setPaletteColor(16, 0.625, 0, 0)
    term.setPaletteColor(32, 0.625, 0, 0.625)
    term.setPaletteColor(64, 0.625, 0.3125, 0)
    term.setPaletteColor(128, 0.625, 0.625, 0.625)
    term.setPaletteColor(256, 0.3125, 0.3125, 0.3125)
    term.setPaletteColor(512, 0.3125, 0.3125, 1)
    term.setPaletteColor(1024, 0.3125, 1, 0.3125)
    term.setPaletteColor(2048, 0.3125, 1, 1)
    term.setPaletteColor(4096, 1, 0.3125, 0.3125)
    term.setPaletteColor(8192, 1, 0.3125, 1)
    term.setPaletteColor(16384, 1, 1, 0.3125)
    term.setPaletteColor(32768, 1, 1, 1)
    term.setBackgroundColor(1)
    term.setTextColor(128)
    term.clear()
    term.setCursorPos(1, 1)
end

dofile(pwd .. "emu_core.lua")

