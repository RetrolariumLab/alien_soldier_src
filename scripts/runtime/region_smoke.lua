-- Cold boot and natural attract playback. No memory/register/VDP/state writes.
local contract = dofile(assert(os.getenv("ALIEN_REGION_SMOKE_CONTRACT")))
local path = assert(os.getenv("ALIEN_REGION_SMOKE_TRACE"))
local trace = assert(io.open(path, "w"))
local r, skipped, demo_count, complete = contract.ram, false, 0, false
gens.speedmode("nothrottle")

local function release(port)
    joypad.set(port, {up=false, down=false, left=false, right=false,
        A=false, B=false, C=false, X=false, Y=false, Z=false, start=false, mode=false})
end

gens.registerafter(function()
    local values = {}
    for _, item in ipairs(contract.observations) do
        values[#values + 1] = item[2] == 1 and memory.readbyte(item[1]) or memory.readword(item[1])
    end
    trace:write(tostring(gens.framecount()) .. "," .. table.concat(values, ",") .. "\n")
    if memory.readword(r.GameModeIndex) == 0x10
            and memory.readword(r.DemoPlaybackActive) == 1
            and memory.readword(r.DemoPlaybackState) == 4
            and memory.readword(r.PlayerObjectType) == 8 then
        demo_count = demo_count + 1
    else
        demo_count = 0
    end
    if demo_count >= contract.demo_stable_frames then complete = true end
end)

local skip_frame = 0
for frame = 1, contract.max_frames do
    release(1)
    release(2)
    if not skipped and memory.readword(r.GameModeIndex) == 0x28
            and memory.readbyte(r.PaletteFadeMaskStatus) % 2 == 1
            and memory.readword(r.ScenePaletteFadeOffset) == 0
            and memory.readword(r.DataLoaderControl) < 0x8000 then
        joypad.set(1, {start=true})
        skipped, skip_frame = true, gens.framecount()
    end
    gens.frameadvance()
    if complete then break end
end
gens.registerafter(nil)
release(1)
release(2)
trace:close()
local result = assert(io.open(path .. ".result.json", "w"))
result:write(string.format('{"schema_version":1,"status":"%s","frame":%d,"story_start_frame":%d}\n',
    complete and "complete" or "timeout", gens.framecount(), skip_frame))
result:close()
if not complete then error("regional smoke did not reach natural attract gameplay") end
os.exit(0)
