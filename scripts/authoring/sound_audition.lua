-- Audition a supported request through the cartridge's ordinary sound queue.
-- Execute hooks observe the initializer before any channel parses an event.

local profile = os.getenv("ALIEN_SOUND_PROFILE")
if profile ~= "jp" and profile ~= "eu" then error("invalid audition profile") end
local request = assert(tonumber(os.getenv("ALIEN_SOUND_REQUEST")))
local frames = assert(tonumber(os.getenv("ALIEN_SOUND_FRAMES")))
local check_only = os.getenv("ALIEN_SOUND_CHECK") == "1"
local contract = dofile(assert(os.getenv("ALIEN_SOUND_CONTRACT")))
local result_path = assert(os.getenv("ALIEN_SOUND_RESULT"))
local stop_path = assert(os.getenv("ALIEN_SOUND_STOP"))
local rom_hash = assert(os.getenv("ALIEN_SOUND_ROM_SHA256"))
if frames < 1 or frames > 3600 then error("invalid audition frame bound") end

local ram = contract.ram
local phase = "title"
local current_frame = 0
local ready = false
local dispatched = false
local dispatch_count, loading_dispatch_count, matching_dispatch_count = 0, 0, 0
local loader_count = 0
local last_selected = -1
local stop_frame, request_frame = 0, 0
local history = {}
local history_dropped = 0
local start_down, story_skip_sent = false, false
local story_skip_frame = 0

local function remember_state()
    local mode = memory.readword(ram.GameModeIndex)
    local substate = memory.readword(ram.GameSubstateIndex)
    local previous = history[#history]
    if previous == nil or previous.phase ~= phase or previous.mode ~= mode
            or previous.substate ~= substate then
        if #history == 32 then
            table.remove(history, 1)
            history_dropped = history_dropped + 1
        end
        history[#history + 1] = {frame=current_frame, phase=phase,
                                mode=mode, substate=substate}
    end
end

local function diagnostic(reason)
    remember_state()
    local destination = result_path .. ".diagnostic.json"
    local file = assert(io.open(destination .. ".tmp", "w"))
    file:write(string.format(
        '{"reason":"%s","phase":"%s","frame":%d,"emulator_frame":%d,' ..
        '"pc":%d,"mode":%d,"substate":%d,"selected_request":%d,' ..
        '"pcm_flags":%d,"current_priority":%d,"stop_submission_frame":%d,' ..
        '"request_submission_frame":%d,"dispatch_hook_count":%d,' ..
        '"loading_dispatch_count":%d,"matching_dispatch_count":%d,' ..
        '"loader_hook_count":%d,"last_dispatch_selected":%d,' ..
        '"history_dropped":%d,"story_skip_frame":%d,"queue":[',
        reason, phase, current_frame, gens.framecount(),
        memory.getregister("m68k.pc"), memory.readword(ram.GameModeIndex),
        memory.readword(ram.GameSubstateIndex), memory.readbyte(ram.SoundSelectedRequest),
        memory.readbyte(ram.SoundPCMChannelRecord), memory.readbyte(ram.SoundCurrentPriority),
        stop_frame, request_frame, dispatch_count, loading_dispatch_count,
        matching_dispatch_count, loader_count, last_selected, history_dropped, story_skip_frame))
    for slot = 0, 3 do
        if slot > 0 then file:write(",") end
        file:write(string.format("%d", memory.readbyte(ram.SoundRequestQueue + slot)))
    end
    file:write('],"history":[')
    for index, state in ipairs(history) do
        if index > 1 then file:write(",") end
        file:write(string.format('{"frame":%d,"phase":"%s","mode":%d,"substate":%d}',
                                state.frame, state.phase, state.mode, state.substate))
    end
    file:write("]}\n")
    file:close()
    assert(os.rename(destination .. ".tmp", destination))
end

local function read_value(entry)
    if entry[2] == 1 then return memory.readbyte(entry[1]) end
    if entry[2] == 2 then return memory.readword(entry[1]) end
    if entry[2] == 4 then return memory.readlong(entry[1]) end
    error("invalid observation width")
end

local function report(status, observations)
    local file = assert(io.open(result_path .. ".tmp", "w"))
    file:write(string.format(
        '{"status":"%s","profile":"%s","request_id":%d,' ..
        '"rom_sha256":"%s","frame":%d,"observations":[',
        status, profile, request, rom_hash, current_frame))
    for index, value in ipairs(observations) do
        if index > 1 then file:write(",") end
        file:write(string.format("%d", value))
    end
    file:write("]}\n")
    file:close()
    assert(os.rename(result_path .. ".tmp", result_path))
end

memory.registerexec(contract.dispatch_hook, function()
    dispatch_count = dispatch_count + 1
    last_selected = memory.readbyte(ram.SoundSelectedRequest)
    if phase == "loading" then
        loading_dispatch_count = loading_dispatch_count + 1
        dispatched = last_selected == request
        if dispatched then matching_dispatch_count = matching_dispatch_count + 1 end
    end
end)

memory.registerexec(contract.hook, function()
    loader_count = loader_count + 1
    if phase ~= "loading" then return end
    local observations = {}
    local matches = dispatched and memory.readword(ram.GameModeIndex) == 0x0020
    for index, entry in ipairs(contract.checks) do
        observations[index] = read_value(entry)
        if observations[index] ~= entry[3] then matches = false end
    end
    report(matches and "loaded" or "mismatch", observations)
    ready = matches
    phase = matches and "ready" or "failed"
end)

local function queue(value)
    -- Use the ordinary first empty queue slot. No channel RAM is fabricated.
    for slot = 0, 3 do
        if memory.readbyte(ram.SoundRequestQueue + slot) == 0 then
            memory.writebyte(ram.SoundRequestQueue + slot, value)
            return true
        end
    end
    return false
end

for frame = 1, 1800 do
    current_frame = frame
    if start_down then
        joypad.set(1, {start=false})
        start_down = false
    end
    local mode = memory.readword(ram.GameModeIndex)
    remember_state()
    if phase == "title" and mode == 0x0028 and not story_skip_sent
            and memory.readbyte(ram.PaletteFadeMaskStatus) % 2 == 1
            and memory.readword(ram.ScenePaletteFadeOffset) == 0
            and memory.readword(ram.DataLoaderControl) < 0x8000 then
        -- StoryScreen_MainLoop accepts a real Start edge only under these
        -- three source-proved palette/loader gates. Release it next frame.
        joypad.set(1, {start=true})
        start_down, story_skip_sent, story_skip_frame = true, true, frame
    elseif phase == "title" and mode == 0x0018 then
        -- The title selects the real options initializer with mode $1C.
        memory.writeword(ram.GameModeIndex, 0x001C)
        memory.writeword(ram.GameSubstateIndex, 0)
        phase = "options"
    elseif phase == "options" and mode == 0x0020 then
        if queue(4) then phase = "stopping"; stop_frame = frame end
    elseif phase == "stopping" and memory.readlong(ram.SoundRequestQueue) == 0
            and memory.readbyte(ram.SoundSelectedRequest) == 0xFF
            and memory.readbyte(ram.SoundPCMChannelRecord) == 0 then
        if queue(request) then phase = "loading"; request_frame = frame end
    elseif phase == "failed" then
        diagnostic("loader_mismatch")
        memory.registerexec(contract.hook, nil)
        memory.registerexec(contract.dispatch_hook, nil)
        os.exit(1)
    end
    gens.frameadvance()
    if ready then break end
end

memory.registerexec(contract.hook, nil)
memory.registerexec(contract.dispatch_hook, nil)
joypad.set(1, {start=false})
if not ready then
    diagnostic("startup_timeout")
    report("timeout", {})
    os.exit(1)
end

if not check_only then
    for frame = 1, frames do
        local stop = io.open(stop_path, "r")
        if stop then stop:close(); break end
        gens.frameadvance()
    end
end
queue(4)
gens.frameadvance()
gens.frameadvance()
os.exit(0)
