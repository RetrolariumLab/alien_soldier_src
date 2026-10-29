Reset:
                                        ; Reset:ChecksumCheck   o
                tst.l   (IO_CT1_CTRL).l
                bne.s   Reset_CheckColdBoot
                tst.w   (IO_EXT_CTRL).l
Reset_CheckColdBoot:                                    ; was: loc_20E
                bne.s   Reset_EnterRuntime
                lea     Reset_BootstrapData(pc),a5
                movem.w (a5)+,d5-d7
                movem.l (a5)+,a0-a4
                move.b  -$10FF(a1),d0
                andi.b  #$F,d0
                beq.s   Reset_InitVDP
                move.l  #'SEGA',$2F00(a1)
Reset_InitVDP:                                          ; was: loc_22E
                move.w  (a4),d0
                moveq   #0,d0
                movea.l d0,a6
                move.l  a6,usp
                moveq   #$17,d1
Reset_InitVDPRegistersLoop:                             ; was: loc_238
                move.b  (a5)+,d5
                move.w  d5,(a4)
                add.w   d7,d5
                dbf     d1,Reset_InitVDPRegistersLoop
                move.l  (a5)+,(a4)
                move.w  d0,(a3)
                move.w  d7,(a1)
                move.w  d7,(a2)
Reset_WaitForZ80Bus:                                    ; was: loc_24A
                btst    d0,(a1)
                bne.s   Reset_WaitForZ80Bus
                moveq   #$25,d2                         ; '%'
Reset_CopyZ80BootstrapLoop:                             ; was: loc_250
                move.b  (a5)+,(a0)+
                dbf     d2,Reset_CopyZ80BootstrapLoop
                move.w  d0,(a2)
                move.w  d0,(a1)
                move.w  d7,(a2)
Reset_ClearMainRAMBootstrapLoop:                        ; was: loc_25C
                move.l  d0,-(a6)
                dbf     d6,Reset_ClearMainRAMBootstrapLoop
                move.l  (a5)+,(a4)
                move.l  (a5)+,(a4)
                moveq   #$1F,d3
Reset_ClearCRAMBootstrapLoop:                           ; was: loc_268
                move.l  d0,(a3)
                dbf     d3,Reset_ClearCRAMBootstrapLoop
                move.l  (a5)+,(a4)
                moveq   #$13,d4
Reset_ClearVSRAMBootstrapLoop:                          ; was: loc_272
                move.l  d0,(a3)
                dbf     d4,Reset_ClearVSRAMBootstrapLoop
                moveq   #3,d5
Reset_MutePSGChannelsLoop:                              ; was: loc_27A
                move.b  (a5)+,$11(a3)
                dbf     d5,Reset_MutePSGChannelsLoop
                move.w  d0,(a2)
                movem.l (a6),d0-d7/a0-a6
                move    #$2700,sr
; Cold and warm boot converge here before the runtime initialization
Reset_EnterRuntime:                                     ; was: loc_28C
                bra.s   Reset_InitRuntime
; ---------------------------------------------------------------------------
Reset_BootstrapData:    dc.w    $8000                   ; was: word_28E
                dc.w    $3FFF
                dc.w    $100
                dc.l    Z80_RAM
                dc.l    IO_Z80BUS
                dc.l    IO_Z80RES
                dc.l    VDP_DATA
                dc.l    VDP_CTRL
                dc.w    $414, $303C, $76C, 0, 0, $FF00, $8137, 1, $100, $FF
                dc.w    $FF00, $80, $4000, $80, $AF01, $D91F, $1127, $21, $2600, $F977
                dc.w    $EDB0, $DDE1, $FDE1, $ED47, $ED4F, $D1E1, $F108, $D9C1, $D1E1, $F1F9
                dc.w    $F3ED, $5636, $E9E9, $8104, $8F02, $C000, 0, $4000, $10, $9FBF
                dc.w    $DFFF
; ---------------------------------------------------------------------------
Reset_InitRuntime:                                      ; was: loc_2FA
                tst.w   (VDP_CTRL).l
                move    #$2700,sr
                move.w  #0,(IO_Z80RES).l
                move.w  #$100,(IO_Z80RES).l
                move.b  (IO_PCBVER+1).l,d0
                move.b  d0,d7
                andi.b  #$F,d0
                beq.s   Reset_CheckDeveloperSignature
                move.l  #'SEGA',(IO_TMSS).l
Reset_CheckDeveloperSignature:                          ; was: loc_32C
                btst    #6,(IO_EXT_DATA+1).l
                beq.w   ChecksumCheck
                cmpi.l  #'TREA',(DeveloperSignatureTREA).w
                bne.w   ChecksumCheck
                cmpi.l  #'SURE',(DeveloperSignatureSURE).w
                beq.w   Reset_InitDefaults
ChecksumCheck:
                                        ; Reset+140   j
                movea.l #Reset,a0
                if      BuildProfileEU
                move.w  #$1FFD,d0
                moveq   #0,d1
Reset_ChecksumUnrolledLoop:                             ; 128 words per iteration across the complete EU ROM
.words          :=      $80
                while   .words > 0
                add.w   (a0)+,d1
.words          :=      .words-1
                endm
                dbf     d0,Reset_ChecksumUnrolledLoop
                else
                move.l  #$60000,d0
                moveq   #0,d1
Reset_ChecksumLoop:                                     ; was: loc_35E
                add.w   (a0)+,d1
                cmp.l   a0,d0
                bcc.s   Reset_ChecksumLoop
                endif
                movea.l #Checksum,a1
                cmp.w   (a1),d1
                bne.w   Boot_ShowRedScreen
                lea     (SystemStateBlock).w,a1
                moveq   #0,d1
                move.w  #$3F,d0                         ; '?'
GameProgram:
                move.l  d1,(a1)+
                dbf     d0,GameProgram
                move.l  #'TREA',(DeveloperSignatureTREA).w
                move.l  #'SURE',(DeveloperSignatureSURE).w
                move.b  (IO_PCBVER+1).l,(ConsoleVersionFlags).w
                move.w  #2,(DifficultyMode).w
                move.l  #$100000,(HighScoreBCD).w
                move.w  #0,(MessageMode).w
                move.b  #0,(ControlLayoutFlags).w
                clr.w   (SoundDisableFlags).w
                clr.w   (FrameSkipLevel).w
                move.w  #0,(BootInitializedWord).w
                move.l  #$1010101,(PasswordDigits).w
Reset_InitDefaults:                                     ; was: loc_3C8
                move.b  #0,(MessageDisplayFlags).w
                move.b  #6,(P1ButtonASourceBit).w
                move.b  #6,(P2ButtonASourceBit).w
                move.b  #4,(P1ButtonBSourceBit).w
                move.b  #4,(P2ButtonBSourceBit).w
                move.b  #5,(P1ButtonCSourceBit).w
                move.b  #5,(P2ButtonCSourceBit).w
                clr.w   (DemoPlaybackActive).w
                clr.w   (DemoRotationIndex).w
Reset_WaitForDmaIdle:                                   ; was: loc_3FA
                move.w  (VDP_CTRL).l,d0
                btst    #1,d0
                bne.s   Reset_WaitForDmaIdle
                lea     (M68K_RAM).l,a0
                moveq   #0,d0
                move.w  #$3FBF,d1
Reset_ClearMainRAMLoop:                                 ; was: loc_412
                move.l  d0,(a0)+
                dbf     d1,Reset_ClearMainRAMLoop
                jsr     (Gfx_InitVDPRegisters).l
                jsr     (Input_InitializeControllerPorts).l
                jsr     (Sys_ResetTransferAndInputState).l
Reset_AcquireZ80Bus:                                    ; was: loc_42A
                bset    #0,(IO_Z80BUS).l
                bne.s   Reset_AcquireZ80Bus
                lea     (Z80_RAM).l,a0
                moveq   #0,d0
                move.w  #$7FF,d1
Reset_ClearZ80RAMLoop:                                  ; was: loc_440
                move.l  d0,(a0)+
                dbf     d1,Reset_ClearZ80RAMLoop
                jsr     (Sound_InitDriverThunk).l
                move.b  #4,(SoundRequestQueue).w
                jsr     (Sound_UpdateThunk).l
                move.b  #1,(VBlankUpdateReady).w
                move    #$2300,sr
; Endless loop that re-enables interrupts and runs the data loader dispatcher
Sys_MainGameLoop:                                       ; was: loc_462
                move    #$2300,sr
                jsr     (Sys_DispatchDataLoader).l
                bra.s   Sys_MainGameLoop
; End of function Reset

Reserv3F:
                                        ; ROM:0000002C   o
                stop    #$2700
; End of function Reserv3F

IRQ7:
                                        ; ROM:00000068   o
                stop    #$2700
; End of function IRQ7

Trap15:
                                        ; ROM:00000084   o
                stop    #$2700
; End of function Trap15

BusErr:
                stop    #$2700
; End of function BusErr

AdrErr:
                stop    #$2700
; End of function AdrErr

InvOpCode:
                stop    #$2700
; End of function InvOpCode

DivBy0:
                stop    #$2700
; End of function DivBy0

Check:
                stop    #$2700
; End of function Check

TrapV:
                stop    #$2700
; End of function TrapV

GPF:
                stop    #$2700
; End of function GPF

Trace:
                stop    #$2700
; End of function Trace

Boot_ShowRedScreen:
                jsr     (Gfx_InitVDPRegisters).l
                move.l  #$C0000000,(VDP_CTRL).l
                moveq   #$3F,d7                         ; '?'
Boot_ShowRedScreen_FillLoop:
                move.w  #$E,(VDP_DATA).l
                dbf     d7,Boot_ShowRedScreen_FillLoop
Boot_ShowRedScreen_HaltLoop:                            ; was: loc_4B8
                bra.s   Boot_ShowRedScreen_HaltLoop
; End of function Boot_ShowRedScreen
