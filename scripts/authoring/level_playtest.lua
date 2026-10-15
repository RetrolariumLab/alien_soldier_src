-- Boot an editable Alien Soldier ROM through the cartridge's password path.

local function number_setting(name, minimum, maximum, base)
    local value = tonumber(os.getenv(name) or "", base or 10)
    if value == nil or value < minimum or value > maximum then
        error(name .. " must be in range " .. minimum .. ".." .. maximum)
    end
    return value
end

local profile = os.getenv("ALIEN_PLAYTEST_PROFILE") or ""
if profile ~= "jp" and profile ~= "eu" then
    error("ALIEN_PLAYTEST_PROFILE must be jp or eu")
end

local stage = number_setting("ALIEN_PLAYTEST_STAGE", 1, 25)
local difficulty = number_setting("ALIEN_PLAYTEST_DIFFICULTY", 0, 0)
if difficulty ~= 0 then
    error("ALIEN_PLAYTEST_DIFFICULTY must be 0")
end
local password = number_setting("ALIEN_PLAYTEST_PASSWORD", 0, 0xFFFFFFFF, 16)
local result_path = os.getenv("ALIEN_PLAYTEST_RESULT")
local exit_when_ready = os.getenv("ALIEN_PLAYTEST_EXIT") == "1"
local wanted_index = (stage - 1) * 2

local ram = {
    game_mode = 0xFFA284,
    game_substate = 0xFFA286,
    stage_index = 0xFFA204,
    stage_route = 0xFFA209,
    difficulty = 0xFFFF0E,
    password_digits = 0xFFFF3A,
    password_cursor = 0xFF8068,
    password_cursor_move = 0xFF806E,
    player_type = 0xFFA400,
    palette_fade_status = 0xFF80F4,
    scene_palette_offset = 0xFF0176,
    data_loader_control = 0xFFF720,
    palette_fade_color_offset = 0xFF80F0,
    palette_fade_mode = 0xFF80F2,
    controller_pressed = 0xFFF708,
    controller_held = 0xFFF706,
    setup_index = 0xFFA29C,
    setup_scroll_target = 0xFF812A,
    secondary_camera_y = 0xFFA90C,
    weapon_slot = 0xFFA24E,
}

local phase = "title"
local history = {}
local history_dropped = 0
local story_skip_frame, password_frame, confirm_frame = 0, 0, 0
local start_down, story_skip_sent = false, false
local c_down, setup_start_sent = false, false
local setup_start_frame, setup_c_pulses = 0, 0

local function remember_state(frame)
    local mode = memory.readword(ram.game_mode)
    local substate = memory.readword(ram.game_substate)
    local previous = history[#history]
    if previous == nil or previous.phase ~= phase or previous.mode ~= mode
            or previous.substate ~= substate or (mode == 0x0074
                and (previous.setup_index ~= memory.readword(ram.setup_index)
                    or previous.weapon_slot ~= memory.readword(ram.weapon_slot))) then
        if #history == 32 then
            table.remove(history, 1)
            history_dropped = history_dropped + 1
        end
        history[#history + 1] = {frame=frame, phase=phase, mode=mode, substate=substate,
                                pressed=memory.readbyte(ram.controller_pressed),
                                held=memory.readbyte(ram.controller_held),
                                cursor=memory.readword(ram.password_cursor),
                                digits=memory.readlong(ram.password_digits),
                                setup_index=memory.readword(ram.setup_index),
                                weapon_slot=memory.readword(ram.weapon_slot)}
    end
end

local function write_diagnostic(status, frame)
    local destination = result_path .. ".diagnostic.json"
    local diagnostic = assert(io.open(destination .. ".tmp", "w"))
    remember_state(frame)
    diagnostic:write(string.format(
        '{"status":"%s","profile":"%s","stage":%d,"difficulty":%d,' ..
        '"route":%d,"phase":"%s","frame":%d,"emulator_frame":%d,' ..
        '"pc":%d,"mode":%d,"substate":%d,"stage_index":%d,' ..
        '"player_type":%d,"story_skip_frame":%d,"password_frame":%d,' ..
        '"confirm_frame":%d,"password_cursor":%d,"password_digits":%d,' ..
        '"setup_start_frame":%d,"setup_c_pulses":%d,' ..
        '"history_dropped":%d,"history":[',
        status, profile, stage, memory.readword(ram.difficulty),
        memory.readbyte(ram.stage_route), phase, frame, gens.framecount(),
        memory.getregister("m68k.pc"),
        memory.readword(ram.game_mode), memory.readword(ram.game_substate),
        memory.readword(ram.stage_index), memory.readword(ram.player_type),
        story_skip_frame, password_frame, confirm_frame,
        memory.readword(ram.password_cursor), memory.readlong(ram.password_digits),
        setup_start_frame, setup_c_pulses, history_dropped))
    for index, state in ipairs(history) do
        if index > 1 then diagnostic:write(",") end
        diagnostic:write(string.format(
            '{"frame":%d,"phase":"%s","mode":%d,"substate":%d,' ..
            '"pressed":%d,"held":%d,"cursor":%d,"digits":%d,' ..
            '"setup_index":%d,"weapon_slot":%d}',
            state.frame, state.phase, state.mode, state.substate, state.pressed,
            state.held, state.cursor, state.digits, state.setup_index, state.weapon_slot))
    end
    diagnostic:write("]}\n")
    diagnostic:close()
    assert(os.rename(destination .. ".tmp", destination))
end

local function write_result(status, frame)
    if result_path == nil or result_path == "" then
        return
    end
    write_diagnostic(status, frame)
    local result = assert(io.open(result_path .. ".tmp", "w"))
    result:write(string.format(
        "status=%s profile=%s stage=%d stage_index=%04X difficulty=%d " ..
        "mode=%04X player_type=%04X route=%02X frame=%d\n",
        status,
        profile,
        stage,
        memory.readword(ram.stage_index),
        memory.readword(ram.difficulty),
        memory.readword(ram.game_mode),
        memory.readword(ram.player_type),
        memory.readbyte(ram.stage_route),
        frame
    ))
    result:close()
    assert(os.rename(result_path .. ".tmp", result_path))
end

local ready = false
local last_frame = 0
for frame = 1, 4200 do
    last_frame = frame
    local released_c = c_down
    if c_down then
        joypad.set(1, {C=false})
        c_down = false
    end
    if start_down then
        joypad.set(1, {start=false})
        start_down = false
    end
    local mode = memory.readword(ram.game_mode)
    remember_state(frame)
    if phase == "title" and mode == 0x0028 and not story_skip_sent
            and memory.readbyte(ram.palette_fade_status) % 2 == 1
            and memory.readword(ram.scene_palette_offset) == 0
            and memory.readword(ram.data_loader_control) < 0x8000 then
        -- StoryScreen_MainLoop consumes a real Start edge only after the
        -- palette/loader guards pass. Never fabricate an intro exit state.
        joypad.set(1, {start=true})
        start_down, story_skip_sent, story_skip_frame = true, true, frame
    elseif phase == "title" and mode == 0x0018
            and memory.readword(ram.palette_fade_color_offset) == 0 then
        -- Title initialization has completed. Enter the game's own password
        -- initializer instead of fabricating its session state in Lua.
        memory.writeword(ram.game_mode, 0x0044)
        memory.writeword(ram.game_substate, 0)
        phase = "password"
        password_frame = frame
    elseif phase == "password" and mode == 0x0048
            and memory.readword(ram.palette_fade_mode) == 0
            and memory.readword(ram.palette_fade_color_offset) == 0 then
        -- Select the real confirm field and submit a real table password. The
        -- game then sets StageTableIndex/DifficultyMode and calls
        -- Password_InitializeSelectedStage itself. Wait for the entry fade:
        -- mode $48 is assigned before PasswordMenu_Activate resets the cursor.
        memory.writelong(ram.password_digits, password)
        memory.writeword(ram.password_cursor, 8)
        memory.writeword(ram.password_cursor_move, 0)
        -- PasswordValidation_RenderMatch tests raw controller bit 5. In the
        -- front end that is physical C, not the emulator's condensed B bit.
        joypad.set(1, {C=true})
        c_down = true
        phase = "release"
        confirm_frame = frame
    elseif phase == "release" then
        joypad.set(1, {C=false})
        phase = "gameplay"
    elseif phase == "gameplay" and mode == 0x0074
            and memory.readword(ram.game_substate) == 2
            and memory.readword(ram.palette_fade_mode) == 0 then
        local setup_index = memory.readword(ram.setup_index)
        if not released_c and (setup_index == 0 or setup_index == 2 or setup_index == 4)
                and memory.readword(ram.secondary_camera_y)
                    == memory.readword(ram.setup_scroll_target) then
            -- Accept the four original loadout slots, control layout, and
            -- exit page through their handlers. Never write loadout RAM.
            joypad.set(1, {C=true})
            c_down = true
            setup_c_pulses = setup_c_pulses + 1
        elseif setup_index == 0x000A and not setup_start_sent then
            -- WeaponSetup_WaitForConfirmInput consumes Start at state $A.
            joypad.set(1, {start=true})
            start_down, setup_start_sent, setup_start_frame = true, true, frame
        end
    elseif phase == "gameplay" and mode == 0x0010 then
        ready = memory.readword(ram.stage_index) == wanted_index
            and memory.readword(ram.difficulty) == difficulty
            and memory.readword(ram.player_type) == 0x0008
        if ready then
            write_result("ready", frame)
            break
        end
    end
    gens.frameadvance()
end

joypad.set(1, {C=false})
joypad.set(1, {start=false})
if not ready then
    write_result("timeout", last_frame)
    if exit_when_ready then
        os.exit(1)
    end
    error("Alien Soldier playtest did not reach the selected stage")
end

if exit_when_ready then
    os.exit(0)
end
