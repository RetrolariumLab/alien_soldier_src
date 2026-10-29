; Resets scene memory and video state before drawing the region-lock message
Sys_ResetForRegionLockDisplay:                          ; was: sub_2D40
                clr.w   (FrameSkipLevel).w
                bsr.w   Gfx_LoadInitialVDPRegisterShadows
                bsr.w   Sys_ClearSceneVideoAndRAM
                bsr.w   Sys_ClearObjectAndSpriteState
                bsr.w   Sys_ClearPaletteBuffers
                bsr.w   Gfx_ClearStagingAndFirst48KiBVRAM
                bsr.w   Sys_ResetTransferAndInputState
                bsr.w   Sys_ClearGameplayStateBlock
                bsr.w   Sys_ClearFrameAndSpriteScratch
                bsr.w   Sys_ClearGameplayStateRegion8KiB
                bra.w   Sys_ClearObjectBuffer
; End of function Sys_ResetForRegionLockDisplay
; Resets the common scene state used by frontend, results, credits, and gameplay entry
Sys_InitGameMode:                                       ; was: sub_2D6C
                                        ; TitleScreen_Initialize+6   p
                clr.w   (FrameSkipLevel).w
                bsr.w   Gfx_LoadGameVDPRegisterShadows
                bsr.w   Sys_ClearSceneVideoAndRAM
                bsr.w   Sys_ClearObjectAndSpriteState
                bsr.w   Sys_ClearPaletteBuffers
                bsr.w   Gfx_ClearStagingAndFirst48KiBVRAM
                bsr.w   Sys_ResetTransferAndInputState
                bsr.w   Sys_ClearFrameAndSpriteScratch
                bsr.w   Sys_ClearGameplayStateRegion8KiB
                bra.w   Sys_ClearObjectBuffer
; End of function Sys_InitGameMode
; Clears scene tilemaps, scroll buffers, VSRAM, and the shared lower-RAM regions
Sys_ClearSceneVideoAndRAM:                              ; was: sub_2D94
                                        ; Sys_InitGameMode+8   p
                bsr.w   Gfx_ClearPlaneATilemapVRAM
                bsr.w   Gfx_ClearPlaneBTilemapVRAM
                bsr.w   Sys_ClearLowerRAM32KiB
                bsr.w   Sys_ClearCameraStageAndDebugStateRegion256
                bsr.w   Gfx_ClearHScrollBuffer
                bsr.w   Gfx_ClearHScrollTableVRAM
                bsr.w   Gfx_ClearVScrollBuffer
                bra.w   Gfx_ClearVSRAM
; End of function Sys_ClearSceneVideoAndRAM
; Clears initialization object pools, software sprite state, and sprite-table VRAM
Sys_ClearObjectAndSpriteState:                          ; was: sub_2DB4
                                        ; Sys_InitGameMode+C   p
                bsr.w   Sys_ClearInitializationObjectPools
                bsr.w   Sys_ClearOrphanedObjectArea
                bsr.w   Sprite_ClearOAMBuildState
                bsr.w   Sprite_ClearOAMBuffer
                bsr.w   Gfx_ClearSpriteTableVRAM
                rts
; End of function Sys_ClearObjectAndSpriteState
; Wrapper to clear palette buffer
Sys_ClearPaletteBuffers:                                ; was: sub_2DCA
                                        ; Sys_InitGameMode+10   p
                bsr.w   Palette_ClearBuffers
                rts
; End of function Sys_ClearPaletteBuffers
; Resets transfer buffers, controller state, VDP cursors, and scroll DMA sources
Sys_ResetTransferAndInputState:                         ; was: sub_2DD0
                                        ; Sys_ResetForRegionLockDisplay+18   p
                bsr.w   Sys_ClearVDPCommandBuffer
                bsr.w   Sys_ClearSpriteVDPStagingBuffer
                bsr.w   Sys_ClearWorkBuffer192
                bsr.w   Input_InitializeControllerState
                move.w  #$F400,(VDPCommandQueueHead).w
                move.w  #$F400,(VDPStagingDataCursor).w
                move.l  #HScrollBuffer,(HScrollDMASource).w
                move.l  #VScrollBuffer,(VScrollDMASource).w
                rts
; End of function Sys_ResetTransferAndInputState
; Clears the 1 KiB graphics staging buffer and the first 48 KiB of VRAM
Gfx_ClearStagingAndFirst48KiBVRAM:                      ; was: sub_2DFE
                                        ; Sys_InitGameMode+14   p
                bsr.w   Gfx_ClearGraphicsStagingBuffer
                bsr.w   Gfx_ClearVRAMFirst48KiB
                rts
; End of function Gfx_ClearStagingAndFirst48KiBVRAM
; Initializes all VDP registers by loading values from lookup table and storing them to VDP_CTRL and RAM
Gfx_InitVDPRegisters:                                   ; was: sub_2E08
                                        ; Boot_ShowRedScreen   p
                lea     Gfx_InitialVDPRegisterValues(pc),a0
                lea     (VDPReg0Shadow).w,a1
                move.w  #$8000,d0
                moveq   #$17,d7
Gfx_InitVDPRegisters_Loop:                              ; was: loc_2E16
                move.b  (a0)+,d0
                move.w  d0,(VDP_CTRL).l
                move.w  d0,(a1)+
                addi.w  #$100,d0
                dbf     d7,Gfx_InitVDPRegisters_Loop
                rts
; End of function Gfx_InitVDPRegisters
; Loads the initial VDP register profile into the shadow table without hardware writes
Gfx_LoadInitialVDPRegisterShadows:                      ; was: sub_2E2A
                lea     Gfx_InitialVDPRegisterValues(pc),a0
                bra.w   Gfx_LoadVDPRegisterShadowsSetup
; End of function Gfx_LoadInitialVDPRegisterShadows
; Loads the game VDP register profile into the shadow table without hardware writes
Gfx_LoadGameVDPRegisterShadows:                         ; was: sub_2E32
                                        ; Stage_UpdateGameplayEntry+26   p
                lea     Gfx_GameVDPRegisterValues(pc),a0
Gfx_LoadVDPRegisterShadowsSetup:                        ; was: loc_2E36
                lea     (VDPReg0Shadow).w,a1
                move.w  #$8000,d0
                moveq   #23,d7
; Copies 24 register command words into the contiguous VDP shadow table
Gfx_LoadVDPRegisterShadowsLoop:                         ; was: loc_2E40
                move.b  (a0)+,d0
                move.w  d0,(a1)+
                addi.w  #$100,d0
                dbf     d7,Gfx_LoadVDPRegisterShadowsLoop
                rts
; End of function Gfx_LoadGameVDPRegisterShadows
; ---------------------------------------------------------------------------
Gfx_InitialVDPRegisterValues:   dc.b    4, $24, $30, $34, 7, $7A, 0, 0  ; was: byte_2E4E
                                        ; sub_2E2A   o
                dc.b    0, 0, 0, 0, $81, $3C, 0, 2
                dc.b    1, 0, 0, 0, 0, 0, 0
                align0  2
Gfx_GameVDPRegisterValues:  dc.b    4, $24, $30, $34, 7, $7A, 0, $10  ; was: byte_2E66
                dc.b    0, 0, 0, 0, $81, $3C, 0, 2
                dc.b    1, 0, 4, 0, 0, 0, 0
                align0  2

; Initializes controller I/O ports and modes
