Math_LookupPackedBCDWord:                               ; was: sub_1B404
                lea     (Math_PackedBCDLookup).l,a0
                move.w  (a0,d0.w),d0
                rts
; End of function Math_LookupPackedBCDWord
; Returns the player's absolute horizontal and signed vertical deltas
Physics_GetPlayerDelta:                                 ; was: sub_1B410
                                        ; Projectile_UpdateOscillatingContactHazardType2B4:Projectile_UpdateOscillatingContactHazardType2B4_CheckPlayerProximity   p
                movea.w #(PlayerObjectType-M68K_RAM),a0
                move.w  $10(a0),d1
                sub.w   $10(a5),d1
                move.w  d1,d0
                bpl.s   Physics_GetPlayerDelta_AbsoluteX
                neg.w   d0
Physics_GetPlayerDelta_AbsoluteX:                       ; was: loc_1B422
                move.w  $14(a0),d2
                sub.w   $14(a5),d2
                moveq   #1,d3
                rts
; End of function Physics_GetPlayerDelta
; Unreferenced: returns the arctan2 angle between two objects in $1FE units
Orphaned_CalculateAngleBetweenObjects:
                move.w  $10(a0),d0                      ; was: sub_1B42E
                move.w  $14(a0),d1
                sub.w   $10(a1),d0
                sub.w   $14(a1),d1
                jsr     (Math_Arctan2Lookup).l
                asr.w   #7,d2
                andi.w  #$1FE,d2
                rts
; End of function Orphaned_CalculateAngleBetweenObjects
; Calculates sine/cosine values in all four quadrants and stores in lookup tables
Math_CalculateSineCosineTable:                          ; was: sub_1B44C
                                        ; Boss_FlyingNeoInit+1C   p
                movea.w a0,a1
                adda.w  #$200,a1
                movea.w a1,a2
                addq.w  #4,a1
                movea.w a0,a3
                adda.w  #$400,a3
                movea.w a3,a4
                addq.w  #4,a3
                move.w  a5,(TrigSavedObjectPtr).w
                movea.l #Math_QuarterSineTable,a5
                asl.w   #2,d0
                move.w  #$3F,d7                         ; '?'
; Populates sine/cosine lookup table with calculated values
Math_PopulateTrigTable:                                 ; was: loc_1B470
                move.w  (a5)+,d1
                muls.w  d0,d1
                move.l  d1,(a0)+
                move.l  d1,-(a1)
                move.l  d1,(a4)+
                neg.l   d1
                move.l  d1,(a2)+
                move.l  d1,-(a3)
                dbf     d7,Math_PopulateTrigTable
                move.w  (a5)+,d1
                muls.w  d0,d1
                move.l  d1,(a0)+
                neg.l   d1
                move.l  d1,(a2)+
                movea.w (TrigSavedObjectPtr).w,a5
                rts
; End of function Math_CalculateSineCosineTable
; ---------------------------------------------------------------------------
Math_QuarterSineTable:  dc.w    0, $192, $323, $4B5, $645, $7D5, $964, $AF1  ; was: word_1B494
                                        ; Projectile_SpawnType1A8AtAngle+3A   r
                dc.w    $C7C, $E05, $F8C, $1111, $1294, $1413, $158F, $1708
                dc.w    $187D, $19EF, $1B5D, $1CC6, $1E2B, $1F8B, $20E7, $223D
                dc.w    $238E, $24DA, $261F, $275F, $2899, $29CD, $2AFA, $2C21
                dc.w    $2D41, $2E5A, $2F6B, $3076, $3179, $3274, $3367, $3453
                dc.w    $3536, $3612, $36E5, $37AF, $3871, $392A, $39DA, $3A82
                dc.w    $3B20, $3BB6, $3C42, $3CC5, $3D3E, $3DAE, $3E14, $3E71
                dc.w    $3EC5, $3F0E, $3F4E, $3F84, $3FB1, $3FD3, $3FEC, $3FFB
Math_SineTable: binclude "data/other/word_1B514.bin"    ; was: word_1B514
Math_SineTable_End:                                     ; was: word_1B514_End

; Unreferenced: marks $60-byte entity records for removal up to $DCA0
Orphaned_MarkEntityRecordsExceptTwoTypes:               ; was: sub_1B714
                bsr.w   Orphaned_MarkEntityRecordExceptTwoTypes
                lea     $60(a0),a0
                cmpa.w  #$DCA0,a0
                bmi.w   Orphaned_MarkEntityRecordsExceptTwoTypes
                rts
; End of function Orphaned_MarkEntityRecordsExceptTwoTypes
; Marks one record for removal unless its type is zero or one of two spared types
Orphaned_MarkEntityRecordExceptTwoTypes:                ; was: sub_1B726
                cmpi.w  #0,(a0)
                beq.w   Orphaned_MarkEntityRecordExceptTwoTypesReturn
                cmp.w   (a0),d0
                beq.w   Orphaned_MarkEntityRecordExceptTwoTypesReturn
                cmp.w   (a0),d1
                beq.w   Orphaned_MarkEntityRecordExceptTwoTypesReturn
                move.w  #$10,(a0)
                move.w  #$1000,2(a0)
Orphaned_MarkEntityRecordExceptTwoTypesReturn:          ; was: locret_1B744
                                        ; Orphaned_MarkEntityRecordExceptTwoTypes+A   j
                rts
; End of function Orphaned_MarkEntityRecordExceptTwoTypes
; Clears the complete entity object pool
Sys_ClearEntityObjectPool:                              ; was: sub_1B746
                                        ; EndingStarfield_FadeOutAndPreparePlanet+44   p
                moveq   #0,d0
                movea.w #(Entity_ObjectPool-M68K_RAM),a0
Sys_ClearEntityObjectPool_Loop:                         ; was: loc_1B74C
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
                cmpa.w  #$DCA0,a0
                bmi.s   Sys_ClearEntityObjectPool_Loop
                rts
; End of function Sys_ClearEntityObjectPool
; Queues VDP command for DMA
VDP_QueueCommand:                                       ; was: sub_1B784
                move.w  #$8F02,d3
                movea.w (VDPStagingDataCursor).w,a0
VDP_QueueCommand_Build:                                 ; was: loc_1B78C
                                        ; WeaponSetup_UpdateBackgroundEffect+190   j
                movea.w (VDPCommandQueueHead).w,a1
                move.w  d0,d1
                moveq   #0,d2
                roxl.w  #1,d0
                roxl.w  #1,d2
                roxl.w  #1,d0
                roxl.w  #1,d2
                ori.w   #$80,d2
                move.w  d2,-(a1)
                andi.w  #$3FFF,d1
                addi.w  #$4000,d1
                move.w  d1,-(a1)
                move.l  a0,d0
                lsr.l   #1,d0
                move.l  d0,(DMASourceEncoding).w
                move.b  (DMASourceEncoding+2).w,d1
                move.b  (DMASourceEncoding+1).w,d2
                andi.b  #$7F,d2
                move.b  d0,-(a1)
                move.b  #$95,-(a1)
                move.b  d1,-(a1)
                move.b  #$96,-(a1)
                move.b  d2,-(a1)
                move.b  #$97,-(a1)
                move.w  d3,-(a1)
                move.l  d4,-(a1)
                move.w  a1,(VDPCommandQueueHead).w
                rts
; End of function VDP_QueueCommand
; Halts the Z80, programs a DMA transfer to VDP memory, then restores both
Gfx_DmaTransferWithZ80Halt:                             ; was: sub_1B7DC
                move.w  #$8F02,d3
                move    sr,-(sp)
                move    #$2700,sr
Gfx_DmaTransferWithZ80Halt_RequestBus:                  ; was: loc_1B7E6
                bset    #0,(IO_Z80BUS).l
                bne.s   Gfx_DmaTransferWithZ80Halt_RequestBus
                lea     (VDP_CTRL).l,a4
                move.w  (VDPReg1Shadow).w,d2
                bset    #4,d2
                move.w  d2,(a4)
                move.w  d3,(a4)
                move.l  d4,(a4)
                move.l  a0,d0
                lsr.l   #1,d0
                move.l  d0,(DMASourceEncoding).w
                move.b  (DMASourceEncoding+2).w,d1
                move.b  (DMASourceEncoding+1).w,d2
                andi.w  #$FF,d0
                andi.w  #$FF,d1
                andi.w  #$7F,d2
                addi.w  #-$6B00,d0
                addi.w  #-$6A00,d1
                addi.w  #-$6900,d2
                move.w  d0,(a4)
                move.w  d1,(a4)
                move.w  d2,(a4)
                move.w  d5,d1
                moveq   #0,d2
                roxl.w  #1,d5
                roxl.w  #1,d2
                roxl.w  #1,d5
                roxl.w  #1,d2
                ori.w   #$80,d2
                move.w  d2,(VDPCommand).w
                andi.w  #$3FFF,d1
                addi.w  #$4000,d1
                move.w  d1,(VDPCommand+2).w
                move.w  (VDPCommand+2).w,(a4)
                move.w  (VDPCommand).w,(a4)
                move.w  (VDPReg1Shadow).w,d0
                bclr    #4,d0
                move.w  d0,(a4)
Gfx_DmaTransferWithZ80Halt_ReleaseBus:                  ; was: loc_1B864
                bclr    #0,(IO_Z80BUS).l
                beq.s   Gfx_DmaTransferWithZ80Halt_ReleaseBus
                move    (sp)+,sr
                rts
; End of function Gfx_DmaTransferWithZ80Halt
; Unreferenced: rounds an arctan2 result to one of eight angle sectors
Orphaned_QuantizeAngleToEightSectors:
                asr.w   #7,d2                           ; was: sub_1B872
                andi.w  #$1FE,d2
                move.w  d2,d0
                addi.w  #$20,d0                         ; ' '
                andi.w  #$1C0,d0
                rts
; End of function Orphaned_QuantizeAngleToEightSectors
; Unreferenced: rounds an arctan2 result to one of sixteen angle sectors
Orphaned_QuantizeAngleToSixteenSectors:
                asr.w   #7,d2                           ; was: sub_1B884
                andi.w  #$1FE,d2
                move.w  d2,d0
                addi.w  #$10,d0
                andi.w  #$1E0,d0
                rts
; End of function Orphaned_QuantizeAngleToSixteenSectors
; Unreferenced: rounds an arctan2 result to one of thirty-two angle sectors
Orphaned_QuantizeAngleToThirtyTwoSectors:
                asr.w   #7,d2                           ; was: sub_1B896
                andi.w  #$1FE,d2
                move.w  d2,d0
                addq.w  #8,d0
                andi.w  #$1F0,d0
                rts
; End of function Orphaned_QuantizeAngleToThirtyTwoSectors
; Unreferenced: clears the 8 KB gameplay state buffer
Orphaned_ClearGameplayStateBuffer:
                movea.w #(GameplayStateBuffer-M68K_RAM),a0  ; was: sub_1B8A6
                moveq   #0,d0
                move.w  #$7FF,d7
Orphaned_ClearGameplayStateBufferLoop:                  ; was: loc_1B8B0
                move.l  d0,(a0)+
                dbf     d7,Orphaned_ClearGameplayStateBufferLoop
                rts
; End of function Orphaned_ClearGameplayStateBuffer
; Queue the requested BGM ID, or stop playback when BGM is disabled
Sound_QueueBGMOrStop:                                   ; was: sub_1B8B8
                                        ; Stage13_StartPostBugmaxTransition+1C   p
                btst    #1,(SoundDisableFlags+1).w
                beq.s   Sound_QueueBGMOrStopSubmit
                move.b  #4,d0
Sound_QueueBGMOrStopSubmit:                             ; was: loc_1B8C4
                jmp     (Sound_QueueRequest).l
; End of function Sound_QueueBGMOrStop
; Queue the BGM selected for the current stage, or stop disabled playback
Sound_QueueStageBGMOrStop:                              ; was: sub_1B8CA
                                        ; RetryPrompt_Update+22   j
                btst    #1,(SoundDisableFlags+1).w
                beq.s   Sound_SelectAndQueueStageBGM
                move.b  #4,d0
                jmp     (Sound_QueueRequest).l
; ---------------------------------------------------------------------------
; Select the current stage's BGM request and submit it to the sound queue
Sound_SelectAndQueueStageBGM:                           ; was: loc_1B8DC
                move.w  (StageTableIndex).w,d0
                asr.w   #1,d0
                move.b  Sound_StageBGMRequestTable(pc,d0.w),d0
                jmp     (Sound_QueueRequest).l
; End of function Sound_QueueStageBGMOrStop
; ---------------------------------------------------------------------------
Sound_StageBGMRequestTable: dc.b    $81, $81, $81, $81, $81, $81, $81, $89, $89, $86  ; was: byte_1B8EC
                dc.b    $86, $86, $89, $92, $92, $8B, $8B, $97, $97, 0
                dc.b    $93, $93, $89, $8F, $9F, 0
