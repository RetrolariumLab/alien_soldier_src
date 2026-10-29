; Updates the stage object-spawn cursor and delay
Sys_UpdateObjectSpawner:                                ; was: sub_1A280
                                        ; ZLeoEnding_UpdateScene+C   p
                tst.b   (FrameControlFlags).w
                bpl.w   Sys_UpdateObjectSpawner_TickDelay
                rts
; ---------------------------------------------------------------------------
Sys_UpdateObjectSpawner_TickDelay:                      ; was: loc_1A28A
                move.w  (StageSpawnCountdown).w,d0
                bmi.w   Sys_UpdateObjectSpawner_ProcessList
                subq.w  #1,(StageSpawnCountdown).w
Sys_UpdateObjectSpawner_ProcessList:                    ; was: loc_1A296
                jsr     Sys_ProcessSpawnList(pc)        ; (pc)
                nop
; End of function Sys_UpdateObjectSpawner
; Processes all objects with screen bounds culling
Sys_ProcessVisibleObjects:                              ; was: sub_1A29C
                                        ; UI_UpdateOptionsScreen+58   p
                lea     (Entity_ObjectPool).w,a5
Sys_ProcessVisibleObjects_Loop:                         ; was: loc_1A2A0
                move.w  (a5),d0
                beq.s   Sys_AdvanceObjectPointer
                cmpi.w  #$10,d0
                beq.s   Sys_ProcessVisibleObjects_CheckVisibility
                movea.w d0,a0
                movea.l Entity_UpdateHandlerTable(a0),a0
                jsr     (a0)
Sys_ProcessVisibleObjects_CheckVisibility:              ; was: loc_1A2B2
                btst    #4,2(a5)
                bne.s   Sys_ProcessVisibleObjects_Clear
                btst    #1,2(a5)
                beq.s   Sys_ProcessVisibleObjects_Queue
                move.w  $10(a5),d0
                subi.w  #$60,d0                         ; '`'
                cmpi.w  #$180,d0
                bhi.s   Sys_ProcessVisibleObjects_Clear
                move.w  $14(a5),d0
                subi.w  #$40,d0                         ; '@'
                cmpi.w  #$130,d0
                bls.s   Sys_ProcessVisibleObjects_Queue
Sys_ProcessVisibleObjects_Clear:                        ; was: loc_1A2DE
                                        ; Sys_ProcessVisibleObjects+32   j
                bsr.w   Sys_ClearObjectSlot
                bra.s   Sys_AdvanceObjectPointer
; ---------------------------------------------------------------------------
Sys_ProcessVisibleObjects_Queue:                        ; was: loc_1A2E4
                                        ; Sys_ProcessVisibleObjects+40   j
                movea.w (VisibleObjectListCursor).w,a0
                move.w  a5,(a0)+
                move.w  a0,(VisibleObjectListCursor).w
; Advances object array pointer to next slot in processing loop
Sys_AdvanceObjectPointer:                               ; was: loc_1A2EE
                                        ; Sys_ProcessVisibleObjects+46   j
                lea     $60(a5),a5
                cmpa.w  #$DCA0,a5
                bcs.s   Sys_ProcessVisibleObjects_Loop
                rts
; End of function Sys_ProcessVisibleObjects
; Processes object spawn list based on scroll
Sys_ProcessSpawnList:                                   ; was: sub_1A2FA
                move.l  (StageObjectSpawnCursor).w,d0
                bmi.s   Sys_ProcessSpawnList_Return
                tst.w   (CameraXDelta).w
                bmi.s   Sys_ProcessSpawnList_Return
                movea.l d0,a4
Sys_ProcessSpawnList_Loop:                              ; was: loc_1A308
                move.w  (PrimaryCameraXPosition).w,d7
                addi.w  #$140,d7
                cmp.w   (a4),d7
                blt.s   Sys_ProcessSpawnList_SaveCursor
                bsr.w   Sys_SpawnObject
                lea     $C(a4),a4
                bra.s   Sys_ProcessSpawnList_Loop
; ---------------------------------------------------------------------------
Sys_ProcessSpawnList_SaveCursor:                        ; was: loc_1A31E
                move.l  a4,(StageObjectSpawnCursor).w
Sys_ProcessSpawnList_Return:                            ; was: locret_1A322
                                        ; Sys_ProcessSpawnList+A   j
                rts
; End of function Sys_ProcessSpawnList
; Spawns object from spawn table entry
Sys_SpawnObject:                                        ; was: sub_1A324
                movea.w 8(a4),a5
                movea.w $A(a4),a0
                bsr.w   Sys_FindSlotInRange
                beq.s   Sys_SpawnObject_InitializeSlot
                movea.w 8(a4),a5
                bsr.w   Sys_FindReusableSlotInRange
                beq.s   Sys_SpawnObject_Return
Sys_SpawnObject_InitializeSlot:                         ; was: loc_1A33C
                bsr.w   Sys_ClearObjectSlot
                move.w  4(a4),d0
                bclr    #0,d0
                beq.s   Sys_SpawnObject_CheckSecondDifficultyFlag
                tst.w   (DifficultyMode).w
                bne.s   Sys_SpawnObject_Populate
Sys_SpawnObject_ReturnWithoutSpawn:                     ; was: locret_1A350
                rts
; ---------------------------------------------------------------------------
Sys_SpawnObject_CheckSecondDifficultyFlag:              ; was: loc_1A352
                bclr    #1,d0
                beq.s   Sys_SpawnObject_Populate
                tst.w   (DifficultyMode).w
                bne.s   Sys_SpawnObject_ReturnWithoutSpawn
Sys_SpawnObject_Populate:                               ; was: loc_1A35E
                                        ; Sys_SpawnObject+32   j
                move.w  d0,(a5)
                move.w  6(a4),$5E(a5)
                move.w  (a4),d0
                sub.w   (PrimaryCameraXPosition).w,d0
                addi.w  #$80,d0
                move.w  d0,$10(a5)
                clr.w   $12(a5)
                move.w  2(a4),d1
                add.w   (PrimaryCameraYPosition).w,d1
                move.w  d1,$14(a5)
                clr.w   $16(a5)
Sys_SpawnObject_Return:                                 ; was: locret_1A388
                rts
; End of function Sys_SpawnObject
; Finds free slot in object array range
Sys_FindSlotInRange:                                    ; was: sub_1A38A
                                        ; Sys_FindSlotInRange+A   j
                tst.w   (a5)
                beq.s   Sys_FindSlotInRange_Return
                lea     $60(a5),a5
                cmpa.l  a0,a5
                bcs.s   Sys_FindSlotInRange
                andi    #$FB,ccr
Sys_FindSlotInRange_Return:                             ; was: locret_1A39A
                rts
; End of function Sys_FindSlotInRange
; Finds a flagged reusable object slot within the requested range
Sys_FindReusableSlotInRange:                            ; was: sub_1A39C
                                        ; Sys_FindReusableSlotInRange+E   j
                btst    #6,3(a5)
                bne.s   Sys_FindReusableSlotInRange_Return
                lea     $60(a5),a5
                cmpa.l  a0,a5
                bcs.s   Sys_FindReusableSlotInRange
                moveq   #0,d0
Sys_FindReusableSlotInRange_Return:                     ; was: locret_1A3AE
                rts
; End of function Sys_FindReusableSlotInRange
; Clears 96 bytes of object RAM
Sys_ClearObjectSlot:                                    ; was: sub_1A3B0
                                        ; sub_1A29C:Sys_ProcessVisibleObjects_Clear   p
                movea.l a5,a0
; Clears 96-byte object memory block (24 long-words) to zero
Sys_Clear96ByteBlock:                                   ; was: loc_1A3B2
                                        ; sub_2C3F8:EnemySpawn_AllocateObjectSlot_Initialize   p
                moveq   #0,d0
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                rts
; End of function Sys_ClearObjectSlot
; ---------------------------------------------------------------------------
Stage_EmptyObjectSpawnList: dc.w    $7FFF               ; was: word_1A3E6
                                        ; ROM:Stage16ConfigRecord   o
Stage1_ObjectSpawnList: dc.w    $1A0, $130, $1C, $10, $C680, $CF80  ; was: word_1A3E8
                dc.w    $200, $130, $1D, $11, $C680, $CF80
                dc.w    $280, $D0, $1C, $15, $C680, $CF80
                dc.w    $2C0, $130, $1D, $18, $C680, $CF80
                dc.w    $300, $110, $44, 4, $C680, $CF80
                dc.w    $340, $130, $1C, $10, $C680, $CF80
                dc.w    $3A0, $130, $1D, $10, $C680, $CF80
                dc.w    $400, $130, $8C, 0, $C680, $CF80
                dc.w    $410, $EC, $24C, 0, $C680, $CF80
                dc.w    $440, $D0, $44, 0, $C680, $CF80
                dc.w    $470, $130, $1E0, 0, $C680, $CF80
                dc.w    $4A0, $D0, $1C, 0, $C680, $CF80
                dc.w    $633, $130, $44, 0, $C680, $CF80
                dc.w    $658, $C4, $24C, 0, $C680, $CF80
                dc.w    $6C0, $14C, $48, 0, $C680, $CF80
                dc.w    $6F0, $14C, $49, 0, $C680, $CF80
                dc.w    $720, $14C, $48, 0, $C680, $CF80
                dc.w    $750, $14C, $49, 0, $C680, $CF80
                dc.w    $780, $130, $1D, 0, $C680, $CF80
                dc.w    $7C0, $110, $1E0, 0, $C680, $CF80
Stage2_ObjectSpawnList: binclude "data/other/word_1A4D8.bin"  ; was: word_1A4D8
Stage2_ObjectSpawnList_End:                             ; was: word_1A4D8_End
Stage3_ObjectSpawnList: dc.w    $D10, $130, $1C, 0, $C680, $CF80  ; was: word_1A6B8
                dc.w    $D30, $130, $1C, 0, $C680, $CF80
                dc.w    $D40, $130, $28C, 0, $C680, $CF80
                dc.w    $D80, $130, $1D, $11, $C680, $CF80
                dc.w    $E20, $C0, $FC, 8, $C680, $CF80
                dc.w    $ED0, $C0, $100, $A, $C680, $CF80
                dc.w    $F60, $C0, $FC, $C, $C680, $CF80
                dc.w    $FC0, $E4, $24C, 0, $C680, $CF80
                dc.w    $1010, $C0, $100, $E, $C680, $CF80
                dc.w    $10D0, $130, $1C, 0, $C680, $CF80
                dc.w    $110A, $AC, $22, 0, $C680, $CF80
                dc.w    $11E0, $130, $1C, 0, $C680, $CF80
                dc.w    $1240, $130, $1C, 0, $C680, $CF80
Stage4_ObjectSpawnList: binclude "data/other/word_1A754.bin"  ; was: word_1A754
Stage4_ObjectSpawnList_End:                             ; was: word_1A754_End
Stage5_ObjectSpawnList: binclude "data/other/word_1A882.bin"  ; was: word_1A882
Stage5_ObjectSpawnList_End:                             ; was: word_1A882_End
Stage6_ObjectSpawnList: dc.w    $4D4, $108, $12C, 8, $DB20, $DCA0  ; was: word_1A9B0
                dc.w    $550, $108, $12C, $18, $DB20, $DCA0
                dc.w    $5B8, $108, $12C, $10, $DB20, $DCA0
PostBossRuntimeSpawnList:   binclude "data/other/word_1A9D4.bin"  ; was: word_1A9D4
PostBossRuntimeSpawnList_End:                           ; was: word_1A9D4_End
Stage7_ObjectSpawnList:     dc.w    $C10, $130, $1C, 0, $C680, $CF80  ; was: word_1AB24
                dc.w    $C30, $130, $1D, $11, $C680, $CF80
                dc.w    $C50, $130, $1C, 0, $C680, $CF80
                dc.w    $C80, $110, $8C, 0, $C680, $CF80
                dc.w    $D40, $110, $3B4, $500, $C680, $CF80
                dc.w    $DC0, $110, $3B4, $402, $C680, $CF80
                dc.w    $E40, $C0, $3B4, $304, $C680, $CF80
                dc.w    $EC0, $140, $3B4, $206, $C680, $CF80
                dc.w    $EE0, $B0, $24C, 0, $C680, $CF80
                dc.w    $F00, $F0, $3B4, $402, $C680, $CF80
                dc.w    $FA0, $130, $3B4, $506, $C680, $CF80
                dc.w    $1070, $130, $8C, 0, $C680, $CF80
                dc.w    $10E2, $118, $12C, $8020, $DB20, $DCA0
                dc.w    $7FFF
Stage8_ObjectSpawnList: dc.w    $980, $120, $1C, 0, $C680, $CF80  ; was: word_1ABC2
                dc.w    $A20, $120, $1D, $11, $C680, $CF80
                dc.w    $AC0, $120, $1C, 0, $C680, $CF80
                dc.w    $B40, $120, $1C, 0, $C680, $CF80
                dc.w    $BC0, $120, $1C, 0, $C680, $CF80
                dc.w    $C40, $120, $1C, 0, $C680, $CF80
                dc.w    $C58, $120, $24C, 0, $C680, $CF80
                dc.w    $CC0, $120, $1C, 0, $C680, $CF80
                dc.w    $D40, $120, $1C, 0, $C680, $CF80
                dc.w    $DC0, $120, $1C, 0, $C680, $CF80
                dc.w    $E40, $120, $1C, 0, $C680, $CF80
                dc.w    $EC0, $120, $1C, 0, $C680, $CF80
                dc.w    $F40, $120, $1C, 0, $C680, $CF80
                dc.w    $7FFF
Stage9_EmptyObjectSpawnList:    dc.w    $7FFF           ; was: word_1AC60
Stage10_ObjectSpawnList:        binclude "data/other/word_1AC62.bin"  ; was: word_1AC62
Stage10_ObjectSpawnList_End:                            ; was: word_1AC62_End
Stage11_ObjectSpawnList:        binclude "data/other/word_1AD8E.bin"  ; was: word_1AD8E
Stage11_ObjectSpawnList_End:                            ; was: word_1AD8E_End
Stage12_ObjectSpawnList:        binclude "data/other/word_1AE96.bin"  ; 26 entries plus $7FFF terminator  ; was: word_1AE96
Stage12_ObjectSpawnList_End:                            ; was: word_1AE96_End
Stage14_ObjectSpawnList:        dc.w    $160, $1FD8, $20, 0, $C680, $CF80  ; was: word_1AFD0
                dc.w    $1E0, $2028, $24C, 0, $C680, $CF80
                dc.w    $200, $2010, $1C, 0, $C680, $CF80
                dc.w    $2C0, $2010, $1C, 0, $C680, $CF80
                dc.w    $380, $2010, $1C, 0, $C680, $CF80
Stage15_ObjectSpawnList:    dc.w    $720, $2000, $380, 0, $C680, $CF80  ; was: word_1B00C
                dc.w    $720, $2000, $39C, 0, $C680, $CF80
                dc.w    $740, $2028, $24C, 0, $C680, $CF80
                dc.w    $764, $2028, $20, 0, $C680, $CF80
                dc.w    $7FFF
Stage18_ObjectSpawnList:        binclude "data/other/word_1B03E.bin"  ; was: word_1B03E
Stage18_ObjectSpawnList_End:                            ; was: word_1B03E_End
Stage19_ObjectSpawnList:        binclude "data/other/word_1B2BA.bin"  ; was: word_1B2BA
Stage19_ObjectSpawnList_End:                            ; was: word_1B2BA_End
Stage23_EmptyObjectSpawnList:   dc.w    $7FFF           ; was: word_1B3F4
Stage25_ObjectSpawnList:        dc.w    $270, $2D0, $20, 0, $C680, $CF80  ; was: word_1B3F6
                dc.w    $7FFF
