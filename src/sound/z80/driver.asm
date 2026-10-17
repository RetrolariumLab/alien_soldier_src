; Shared JP/EU DAC program, loaded at Z80 RAM zero by Sound_LoadZ80Driver.
; Reconstructed from the hash-pinned image with independent Z80 decoding.
; All 870 executable instructions are assembly; the original tables stay data.
    cpu z80
    page 0
    org 0
    include "src/sound/z80/memory.asm"
    include "src/sound/z80/reset_and_pcm.asm"
    include "src/sound/z80/voice_streams.asm"
    include "src/sound/z80/dpcm_tables.asm"
