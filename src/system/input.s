Input_InitializeControllerState:                        ; was: sub_33A4
                clr.b   (GameplayControlFlags).w
                move.w  #$FFFF,(ControllerHeldState).w
                move.w  #0,(ControllerPressedState).w
                move.w  #0,(ControllerReleasedState).w
; End of function Input_InitializeControllerState
; Polls both controller ports while holding and then releasing the Z80 bus
Input_PollBothControllersWithZ80BusLock:                ; was: sub_33BA
                                        ; Input_PollBothControllersWithZ80BusLock+8   j
                bset    #0,(IO_Z80BUS).l
                bne.s   Input_PollBothControllersWithZ80BusLock
                bsr.w   Input_ReadPrimaryController
                bsr.w   Input_ReadSecondaryController
Input_PollBothControllers_WaitForZ80BusRelease:         ; was: loc_33CC
                bclr    #0,(IO_Z80BUS).l
                beq.s   Input_PollBothControllers_WaitForZ80BusRelease
                rts
; End of function Input_PollBothControllersWithZ80BusLock
; Reads the primary controller type and updates its button state when connected
Input_ReadPrimaryController:                            ; was: sub_33D8
                lea     (ControllerHeldState).w,a1
                lea     ((IO_CT1_DATA+1)).l,a2
                lea     (P1ButtonASourceBit).w,a3
                bsr.w   Input_ReadControllerTypeSignature
                move.b  d0,(Controller1TypeID).w
                cmpi.b  #$D,d0
                beq.w   Input_UpdateControllerButtonStates
                bra.w   Input_ClearDisconnectedControllerState
; End of function Input_ReadPrimaryController
; Reads the secondary controller type and updates its button state when connected
Input_ReadSecondaryController:                          ; was: sub_33FA
                lea     ((ControllerHeldState+1)).w,a1
                lea     ((IO_CT2_DATA+1)).l,a2
                lea     (P2ButtonASourceBit).w,a3
                bsr.w   Input_ReadControllerTypeSignature
                move.b  d0,(Controller2TypeID).w
                cmpi.b  #$D,d0
                beq.w   Input_UpdateControllerButtonStates
Input_ClearDisconnectedControllerState:                 ; was: loc_3418
                clr.b   (a1)
                clr.b   2(a1)
                clr.b   4(a1)
                rts
; ---------------------------------------------------------------------------
Input_UpdateControllerButtonStates:                     ; was: loc_3424
                                        ; Input_ReadSecondaryController+1A   j
                move.b  #0,(a2)
                nop
                nop
                move.b  (a2),d0
                add.b   d0,d0
                add.b   d0,d0
                andi.b  #$C0,d0
                move.b  #$40,(a2)                       ; '@'
                nop
                nop
                move.b  (a2),d1
                andi.b  #$3F,d1                         ; '?'
                or.b    d1,d0
                not.b   d0
                bsr.w   Input_ApplyConfiguredABCMapping
                move.b  (a1),d1
                move.b  d1,d2
                eor.b   d0,d2
                move.b  d0,(a1)
                and.b   d2,d1
                move.b  d1,4(a1)
                and.b   d2,d0
                move.b  d0,2(a1)
                rts
; End of function Input_UpdateControllerButtonStates
; Applies the selected port's configurable A/B/C source-bit mapping
Input_ApplyConfiguredABCMapping:                        ; was: sub_3462
                btst    #6,(GameplayControlFlags).w
                beq.w   Input_ApplyConfiguredABCMapping_Return
                move.b  d0,d1
                move.b  #6,d2
                move.b  (a3),d3
                bsr.w   Input_CopyConfiguredButtonBit
                move.b  #4,d2
                move.b  2(a3),d3
                bsr.w   Input_CopyConfiguredButtonBit
                move.b  #5,d2
                move.b  4(a3),d3
; End of function Input_ApplyConfiguredABCMapping
; Copies one configured source button bit to its canonical output position
Input_CopyConfiguredButtonBit:                          ; was: sub_348C
                                        ; Input_ApplyConfiguredABCMapping+1E   p
                btst    d3,d1
                beq.w   Input_CopyConfiguredButtonBit_Clear
                bset    d2,d0
                rts
; ---------------------------------------------------------------------------
Input_CopyConfiguredButtonBit_Clear:                    ; was: loc_3496
                bclr    d2,d0
Input_ApplyConfiguredABCMapping_Return:                 ; was: locret_3498
                rts
; End of function Input_CopyConfiguredButtonBit
; Combines TH-high and TH-low samples into the controller type signature
Input_ReadControllerTypeSignature:                      ; was: sub_349A
                                        ; Input_ReadSecondaryController+E   p
                move.b  #$40,(a2)                       ; '@'
                nop
                nop
                move.b  (a2),d0
                move.b  d0,d1
                lsl.b   #1,d1
                or.b    d1,d0
                move.b  d0,d1
                andi.b  #8,d0
                lsl.b   #1,d1
                andi.b  #4,d1
                move.b  #0,(a2)
                nop
                nop
                move.b  (a2),d2
                move.b  d2,d3
                lsr.b   #1,d3
                or.b    d3,d2
                move.b  d2,d3
                lsr.b   #1,d2
                andi.b  #2,d2
                andi.b  #1,d3
                or.b    d1,d0
                or.b    d2,d0
                or.b    d3,d0
                rts
; End of function Input_ReadControllerTypeSignature
