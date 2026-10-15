-- Neutral full-frame replay glue. The authenticated movie owns all input.
-- No controller, RAM, CPU register, savestate, or VDP writes occur here.
local stop_frame = tonumber(os.getenv("ALIEN_RUNTIME_CAPTURE_STOP_FRAME") or "")
if stop_frame == nil or stop_frame % 1 ~= 0 or stop_frame < 2 or stop_frame > 100001 then
    error("ALIEN_RUNTIME_CAPTURE_STOP_FRAME must be an integer in 2..100001")
end
-- CLI turbo forces render skips even with frameskip zero. Native nothrottle
-- without turbo instead uses gens_emulateframefastnoskipping for each advance.
gens.speedmode("nothrottle")
for frame = 1, stop_frame do
    gens.frameadvance()
end
os.exit(0)
