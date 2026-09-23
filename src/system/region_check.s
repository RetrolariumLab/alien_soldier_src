Sys_CheckRegionLock:                                    ; DATA XREF: Sys_DispatchGameState:Sys_GameStateHandlers   o  ; was: sub_4BA
                tst.w   (GameSubstateIndex).w
                bne.w   Sys_CheckRegionLock_Return
                move.b  (IO_PCBVER+1).l,d0
                if      BuildProfileJP
                bpl.s   Sys_EnterInitialGameModeAfterRegionCheck
                endif
                btst    #6,d0
                beq.s   RegionRestricted

; Enters the initial game mode after the hardware region check passes
Sys_EnterInitialGameModeAfterRegionCheck:               ; CODE XREF: Sys_CheckRegionLock+E   j  ; was: loc_4D0
                move.w  #4,(GameModeIndex).w
                clr.w   (GameSubstateIndex).w
                rts
; End of function Sys_CheckRegionLock
RegionRestricted:                                       ; CODE XREF: Sys_CheckRegionLock+14   j
                clr.w   (PaletteFillColor).w
                jsr     (Sys_ResetForRegionLockDisplay).l
                move.b  #4,d0
                jsr     (Sound_QueueRequest).l
                bclr    #6,(VDPReg1Shadow+1).w
                clr.b   (PaletteDMAHIntEnabled).w
                jsr     (Gfx_QueueLargeFontDMACommand81).l
                lea     (FrontendPaletteCommands).l,a0
                jsr     (Gfx_LoadPaletteCommand).l
                move.w  #$8300,d0
                move.w  #RegionLockTextPosition,d4
                lea     RegionLock_DevelopedForUseOnlyWithText(pc),a0
                nop
                jsr     (Text_QueueDoubleHeightStringWrapped).l
                if      BuildProfileJP
                move.w  #$8300,d0
                move.w  #$4518,d4
                lea     RegionLock_NTSCMegaDriveText(pc),a0
                nop
                jsr     (Text_QueueDoubleHeightStringWrapped).l
                move.w  #$8300,d0
                move.w  #$46A4,d4
                lea     RegionLock_AndText(pc),a0
                nop
                jsr     (Text_QueueDoubleHeightStringWrapped).l
                endif
                move.w  #$8300,d0
                if      BuildProfileEU
                move.w  #$4688,d4
                else
                move.w  #$4808,d4
                endif
                lea     RegionLock_PALAndFrenchSecamMegaDriveText(pc),a0
                nop
                jsr     (Text_QueueDoubleHeightStringWrapped).l
                move.w  #$8300,d0
                if      BuildProfileEU
                move.w  #$4820,d4
                else
                move.w  #$49A0,d4
                endif
                lea     RegionLock_SystemsText(pc),a0
                nop
                jsr     (Text_QueueDoubleHeightStringWrapped).l
                bset    #6,(VDPReg1Shadow+1).w
                move.b  #$80,(PaletteDMAHIntEnabled).w
                addq.w  #4,(GameSubstateIndex).w
Sys_CheckRegionLock_Return:                             ; CODE XREF: Sys_CheckRegionLock+4   j  ; was: locret_580
                rts
; End of function RegionRestricted
; ---------------------------------------------------------------------------
RegionLock_DevelopedForUseOnlyWithText: dc.b    $E, $F, $20, $F, $16, $19, $1A, $F  ; was: byte_582
                                        ; DATA XREF: RegionRestricted+38   o
                dc.b    $E, 0, $10, $19, $1C, 0, $1F, $1D
                dc.b    $F, 0, $19, $18, $16, $23, 0, $21
                dc.b    $13, $1E, $12, $FF
RegionLock_NTSCMegaDriveText:   dc.b    $18, $1E, $1D, $D, 0, $17, $F, $11  ; was: byte_59E
                                        ; DATA XREF: RegionRestricted+4C   o
                dc.b    $B, 0, $E, $1C, $13, $20, $F, $FF
RegionLock_AndText:                         dc.b    $B, $18, $E, $FF  ; DATA XREF: RegionRestricted+60   o  ; was: byte_5AE
RegionLock_PALAndFrenchSecamMegaDriveText:  dc.b    $1A, $B, $16, 0, $B, $18, $E, 0  ; was: byte_5B2
                                        ; DATA XREF: RegionRestricted+74   o
                dc.b    $10, $1C, $F, $18, $D, $12, 0, $1D
                dc.b    $F, $D, $B, $17, 0, $17, $F, $11
                dc.b    $B, 0, $E, $1C, $13, $20, $F, $FF
RegionLock_SystemsText: dc.b    $1D, $23, $1D, $1E, $F, $17, $1D, $25  ; was: byte_5D2
                                        ; DATA XREF: RegionRestricted+88   o
                dc.b    $FF, $FF
