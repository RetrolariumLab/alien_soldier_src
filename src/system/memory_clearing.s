Sys_ClearVDPCommandBuffer:                              ; was: sub_3134
                lea     (VDPCommand).w,a0
                moveq   #0,d0
                move.w  #$C,d1
Sys_ClearVDPCommandBuffer_Loop:                         ; was: loc_313E
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                dbf     d1,Sys_ClearVDPCommandBuffer_Loop
                rts
; End of function Sys_ClearVDPCommandBuffer
; Clears all 64KB of VRAM to zero
Gfx_ClearFullVRAM:
                move    sr,-(sp)                        ; was: sub_314C
                move    #$2700,sr
                lea     (VDP_DATA).l,a0
                move.w  #$8F02,(VDP_CTRL).l
                move.l  #$40000000,(VDP_CTRL).l
                move.w  #$7FFF,d0
                move.w  #0,d1
Gfx_ClearFullVRAM_Loop:                                 ; was: loc_3172
                move.w  d1,(a0)
                dbf     d0,Gfx_ClearFullVRAM_Loop
                move    (sp)+,sr
                rts
; End of function Gfx_ClearFullVRAM
; Clears VRAM $0000-$BFFF with interrupts disabled
Gfx_ClearVRAMFirst48KiB:                                ; was: sub_317C
                move    sr,-(sp)
                move    #$2700,sr
                lea     (VDP_DATA).l,a0
                move.w  #$8F02,(VDP_CTRL).l
                move.l  #$40000000,(VDP_CTRL).l
                move.w  #$5FFF,d0
                move.w  #0,d1
Gfx_ClearVRAMFirst48KiB_Loop:                           ; was: loc_31A2
                move.w  d1,(a0)
                dbf     d0,Gfx_ClearVRAMFirst48KiB_Loop
                move    (sp)+,sr
                rts
; End of function Gfx_ClearVRAMFirst48KiB
; Clears first 24KB of VRAM to zero
Gfx_ClearVRAM24KB:
                move    sr,-(sp)                        ; was: sub_31AC
                move    #$2700,sr
                lea     (VDP_DATA).l,a0
                move.w  #$8F02,(VDP_CTRL).l
                move.l  #$40000000,(VDP_CTRL).l
                move.w  #$2FFF,d0
                move.w  #0,d1
Gfx_ClearVRAM24KB_Loop:                                 ; was: loc_31D2
                move.w  d1,(a0)
                dbf     d0,Gfx_ClearVRAM24KB_Loop
                move    (sp)+,sr
                rts
; End of function Gfx_ClearVRAM24KB
; Clears the middle 24 KiB VRAM range $6000-$BFFF
Gfx_ClearVRAMMiddle24KiB:
                move    sr,-(sp)                        ; was: sub_31DC
                move    #$2700,sr
                lea     (VDP_DATA).l,a0
                move.w  #$8F02,(VDP_CTRL).l
                move.l  #$60000001,(VDP_CTRL).l
                move.w  #$2FFF,d0
                move.w  #0,d1
Gfx_ClearVRAMMiddle24KiB_Loop:                          ; was: loc_3202
                move.w  d1,(a0)
                dbf     d0,Gfx_ClearVRAMMiddle24KiB_Loop
                move    (sp)+,sr
                rts
; End of function Gfx_ClearVRAMMiddle24KiB
; Clears the Plane A tilemap VRAM range $C000-$CFFF
Gfx_ClearPlaneATilemapVRAM:                             ; was: sub_320C
                move    sr,-(sp)
                move    #$2700,sr
                lea     (VDP_DATA).l,a0
                move.w  #$8F02,(VDP_CTRL).l
                move.l  #$40000003,(VDP_CTRL).l
                move.w  #$7FF,d0
                move.w  #0,d1
Gfx_ClearPlaneATilemapVRAM_Loop:                        ; was: loc_3232
                move.w  d1,(a0)
                dbf     d0,Gfx_ClearPlaneATilemapVRAM_Loop
                move    (sp)+,sr
                rts
; End of function Gfx_ClearPlaneATilemapVRAM
; Clears the window tilemap VRAM range $D000-$DFFF
Gfx_ClearWindowTilemapVRAM:
                move    sr,-(sp)                        ; was: sub_323C
                move    #$2700,sr
                lea     (VDP_DATA).l,a0
                move.w  #$8F02,(VDP_CTRL).l
                move.l  #$50000003,(VDP_CTRL).l
                move.w  #$7FF,d0
                move.w  #0,d1
Gfx_ClearWindowTilemapVRAM_Loop:                        ; was: loc_3262
                move.w  d1,(a0)
                dbf     d0,Gfx_ClearWindowTilemapVRAM_Loop
                move    (sp)+,sr
                rts
; End of function Gfx_ClearWindowTilemapVRAM
; Clears the Plane B tilemap VRAM range $E000-$EFFF
Gfx_ClearPlaneBTilemapVRAM:                             ; was: sub_326C
                move    sr,-(sp)
                move    #$2700,sr
                lea     (VDP_DATA).l,a0
                move.w  #$8F02,(VDP_CTRL).l
                move.l  #$60000003,(VDP_CTRL).l
                move.w  #$7FF,d0
                move.w  #0,d1
Gfx_ClearPlaneBTilemapVRAM_Loop:                        ; was: loc_3292
                move.w  d1,(a0)
                dbf     d0,Gfx_ClearPlaneBTilemapVRAM_Loop
                move    (sp)+,sr
                rts
; End of function Gfx_ClearPlaneBTilemapVRAM
; Clears the HScroll table VRAM range $F000-$F3FF
Gfx_ClearHScrollTableVRAM:                              ; was: sub_329C
                move    sr,-(sp)
                move    #$2700,sr
                lea     (VDP_DATA).l,a0
                move.w  #$8F02,(VDP_CTRL).l
                move.l  #$70000003,(VDP_CTRL).l
                move.w  #$1FF,d0
                move.w  #0,d1
Gfx_ClearHScrollTableVRAM_Loop:                         ; was: loc_32C2
                move.w  d1,(a0)
                dbf     d0,Gfx_ClearHScrollTableVRAM_Loop
                move    (sp)+,sr
                rts
; End of function Gfx_ClearHScrollTableVRAM
; Clears the 640-byte sprite table VRAM range $F400-$F67F
Gfx_ClearSpriteTableVRAM:                               ; was: sub_32CC
                move    sr,-(sp)
                move    #$2700,sr
                lea     (VDP_DATA).l,a0
                move.w  #$8F02,(VDP_CTRL).l
                move.l  #$74000003,(VDP_CTRL).l
                move.w  #$13F,d0
                move.w  #0,d1
Gfx_ClearSpriteTableVRAM_Loop:                          ; was: loc_32F2
                move.w  d1,(a0)
                dbf     d0,Gfx_ClearSpriteTableVRAM_Loop
                move    (sp)+,sr
                rts
; End of function Gfx_ClearSpriteTableVRAM
; Clears all 80 bytes of VSRAM with interrupts disabled
Gfx_ClearVSRAM:                                         ; was: sub_32FC
                move    #$2700,sr
                lea     (VDP_DATA).l,a0
                move.l  #$40000010,(VDP_CTRL).l
                move.w  #$13,d0
                moveq   #0,d1
Gfx_ClearVSRAM_Loop:                                    ; was: loc_3316
                move.l  d1,(a0)
                dbf     d0,Gfx_ClearVSRAM_Loop
                move    #$2300,sr
                rts
; End of function Gfx_ClearVSRAM
; Clears CRAM (color RAM) by writing zeros with interrupts disabled
Gfx_ClearCRAM:
                move    #$2700,sr                       ; was: sub_3322
                lea     (VDP_DATA).l,a0
                move.l  #$C0000000,(VDP_CTRL).l
                move.w  #$1F,d0
                moveq   #0,d1
Gfx_ClearCRAM_Loop:                                     ; was: loc_333C
                move.l  d1,(a0)
                dbf     d0,Gfx_ClearCRAM_Loop
                move    #$2300,sr
                rts
; End of function Gfx_ClearCRAM
; Fills 1 KiB at A1 with the longword in D1, advancing A1 past the block
Memory_Fill1KiBWithLongword:
                bsr.s   Memory_Fill128BytesWithLongword  ; was: sub_3348
                bsr.s   Memory_Fill128BytesWithLongword
                bsr.s   Memory_Fill128BytesWithLongword
                bsr.s   Memory_Fill128BytesWithLongword
                bsr.s   Memory_Fill128BytesWithLongword
                bsr.s   Memory_Fill128BytesWithLongword
                bsr.s   Memory_Fill128BytesWithLongword
                nop
; The eighth 128-byte pass is reached by fallthrough
; End of function Memory_Fill1KiBWithLongword
; Fills 128 bytes at A1 with the longword in D1, advancing A1 past the block
Memory_Fill128BytesWithLongword:                        ; was: sub_3358
                                        ; Memory_Fill1KiBWithLongword+2   p
                move.l  d1,(a1)+
                move.l  d1,(a1)+
                move.l  d1,(a1)+
                move.l  d1,(a1)+
                move.l  d1,(a1)+
                move.l  d1,(a1)+
                move.l  d1,(a1)+
                move.l  d1,(a1)+
                move.l  d1,(a1)+
                move.l  d1,(a1)+
                move.l  d1,(a1)+
                move.l  d1,(a1)+
                move.l  d1,(a1)+
                move.l  d1,(a1)+
                move.l  d1,(a1)+
                move.l  d1,(a1)+
                move.l  d1,(a1)+
                move.l  d1,(a1)+
                move.l  d1,(a1)+
                move.l  d1,(a1)+
                move.l  d1,(a1)+
                move.l  d1,(a1)+
                move.l  d1,(a1)+
                move.l  d1,(a1)+
                move.l  d1,(a1)+
                move.l  d1,(a1)+
                move.l  d1,(a1)+
                move.l  d1,(a1)+
                move.l  d1,(a1)+
                move.l  d1,(a1)+
                move.l  d1,(a1)+
                move.l  d1,(a1)+
                rts
; End of function Memory_Fill128BytesWithLongword
; Copies 16 bytes (4 longwords) from a1 to a2
Data_Copy16Bytes:
                move.l  (a1)+,(a2)+                     ; was: sub_339A
                move.l  (a1)+,(a2)+
                move.l  (a1)+,(a2)+
                move.l  (a1)+,(a2)+
                rts
; End of function Data_Copy16Bytes
; Initializes controller input state clearing button flags
