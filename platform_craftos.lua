local keysDown = {}
local lastKey = nil

function platform_event_loop()
    while true do
        local e = {os.pullEvent()}
        if e[1] == "key" then 
            keysDown[e[2]] = true
            lastKey = e[2]
        elseif e[1] == "char" then
            lastKey = e[2]
        elseif e[1] == "key_up" then
            keysDown[e[2]] = nil
            lastKey = nil
        end
    end
end

function platform_sleep(t)
	-- for what pvrpose
	os.sleep(t)
end

function platform_beep(freq)
	-- do nothing
end

function platform_key_down(v)
	return keysDown[v]
end

function emu_debug(level, s, tb)
	--[[if level >= 1 then
		io.stderr:write(s .. "\n")
		if tb then debug.traceback() end
		io.stderr:flush()
	end]]
end

local queued_up = {}

-- non-blocking, returns (ascii char, bios scan code) or nil on none
function platform_getc()
	local c = lastKey
	if type(c) == "string" then c = string.byte() end
	if c == 263 then c = 8 end
	emu_debug(2, string.format("getc %d", c))
	if c then
		if c >= 0 and c < 128 then return c,c
		else return 0,c end
	end
	return nil
end

function platform_error(msg)
    term.setGraphicsMode(false)
	error(msg, 2)
end

function platform_render_cga_mono(vram, addr)
	os.queueEvent("noblock")
    os.pullEvent()
    --term.setGraphicsMode(true)
end

function platform_render_mcga_13h(vram, addr)
	os.queueEvent("noblock")
    os.pullEvent()
    --term.setGraphicsMode(true)
end

function platform_render_pcjr_160(vram, addr)
	os.queueEvent("noblock")
    os.pullEvent()
    --term.setGraphicsMode(true)
end

function platform_render_pcjr_320(vram, addr)
	os.queueEvent("noblock")
    os.pullEvent()
    --term.setGraphicsMode(true)
end

function platform_render_text(vram, addr, width, height, pitch)
	os.queueEvent("noblock")
	os.pullEvent()
    term.setGraphicsMode(false)
	local dlines = video_pop_dirty_lines()
	for y,v in pairs(dlines) do
		local base = addr + (y * pitch)
		for x=0,width-1 do
			local chr = vram[base + x*2] or 0
            local atr = vram[base + x*2 + 1] or 0
            local fg = bit.band(atr, 0x0F)
            local bg = bit.brshift(atr, 4)
            term.setCursorPos(x+1, y+1)
            term.blit(string.char(chr), string.sub("0123456789abcdef", fg+1, fg+1), string.sub("0123456789abcdef", bg+1, bg+1))
		end
	end
end

function platform_finish()
    term.setGraphicsMode(false)
    term.clear()
    term.setCursorPos(1, 1)
end

dofile("emu_core.lua")
