; Initializes the 64 priority buckets used to link generated OAM entries
Sprite_InitializePriorityBuckets:                       ; was: sub_21F0
                                        ; StoryScreen_MainLoop+26   p
                moveq   #$3F,d2                         ; '?'
                lea     (SpritePriorityBuckets).w,a0
                move.l  #$BE0A,d0
Sprite_InitializePriorityBuckets_Loop:                  ; was: loc_21FC
                move.l  d0,(a0)+
                addq.w  #4,d0
                dbf     d2,Sprite_InitializePriorityBuckets_Loop
                move.w  (SpriteOAMStartCount).w,d0
                bne.w   Sprite_InitializePriorityBuckets_SetState
                moveq   #1,d0
Sprite_InitializePriorityBuckets_SetState:              ; was: loc_220E
                move.b  d0,(SpriteOAMEntryCount).w
                asl.w   #3,d0
                addi.w  #-$2000,d0
                move.w  d0,(SpriteOAMWritePointer).w
                move.b  #1,(SpriteOAMBuildActive).w
                rts
; End of function Sprite_InitializePriorityBuckets
; Connects the nonempty priority buckets into one OAM link chain and terminates its final entry
Sprite_FinalizePriorityLinks:                           ; was: sub_2224
                move.b  #$50,d0                         ; 'P'
                sub.b   (SpriteOAMEntryCount).w,d0
                move.b  d0,(SpriteOAMFreeSlots).w
                moveq   #$3F,d2                         ; '?'
                movea.w #(SpritePriorityBuckets-M68K_RAM),a0
                move.w  (SpriteOAMStartCount).w,d0
                bne.w   Sprite_FinalizePriorityLinks_SetTail
                moveq   #1,d0
Sprite_FinalizePriorityLinks_SetTail:                   ; was: loc_2240
                asl.w   #3,d0
                addi.w  #-$2000,d0
                movea.w d0,a1
Sprite_FinalizePriorityLinks_BucketLoop:                ; was: loc_2248
                move.w  (a0)+,d0
                beq.s   Sprite_FinalizePriorityLinks_NextBucket
                move.b  d0,-5(a1)
                movea.w (a0),a1
Sprite_FinalizePriorityLinks_NextBucket:                ; was: loc_2252
                addq.w  #2,a0
                dbf     d2,Sprite_FinalizePriorityLinks_BucketLoop
                move.b  #0,-5(a1)
                clr.b   (SpriteOAMBuildActive).w
                rts
; End of function Sprite_FinalizePriorityLinks
; Clips and appends one object's direct OAM entry, then resumes the display-list traversal
Sprite_RenderSingleObjectEntry:                         ; was: sub_2264
                cmpi.b  #$50,d4                         ; 'P'
                bge.s   Sprite_RenderSingleObjectEntry_NextObject
                move.b  $B(a5),d6
                ext.w   d6
                add.w   $14(a5),d6
                tst.b   3(a5)
                bmi.s   Sprite_RenderSingleObjectEntry_CheckBounds
                sub.w   (SpriteShakeYOffset).w,d6
Sprite_RenderSingleObjectEntry_CheckBounds:             ; was: loc_227E
                cmpi.w  #$200,d6
                bcc.s   Sprite_RenderSingleObjectEntry_NextObject
                move.b  $A(a5),d5
                ext.w   d5
                add.w   $10(a5),d5
                beq.s   Sprite_RenderSingleObjectEntry_NextObject
                cmpi.w  #$220,d5
                bcc.s   Sprite_RenderSingleObjectEntry_NextObject
                move.b  $20(a5),d0
                andi.w  #$FC,d0
                movea.w d0,a1
                movea.w -$41FA(a1),a0
                move.b  d4,-5(a0)
                move.w  d6,(a3)+
                move.w  8(a5),d0
                addq.b  #1,d4
                move.b  d4,d0
                move.w  d0,(a3)+
                move.w  $E(a5),(a3)+
                move.w  d5,(a3)+
                move.w  a3,-$41FA(a1)
Sprite_RenderSingleObjectEntry_NextObject:              ; was: loc_22BE
                                        ; Sprite_RenderSingleObjectEntry+1E   j
                bra.w   Sprite_RenderObjectList_NextObject
; End of function Sprite_RenderSingleObjectEntry
Sprite_RenderMappingClippedReturn:                      ; was: nullsub_11
                                        ; Sprite_RenderMapping+2A   j
                rts
; End of function Sprite_RenderMappingClippedReturn

; Expands a variable-length sprite mapping into linked OAM entries using the object's tile attributes
Sprite_RenderMapping:                                   ; was: sub_22C4
                                        ; Sprite_RenderDynamicObject+24   j
                move.w  $E(a5),d7
                move.w  d7,d2
                andi.w  #$F800,d7
                andi.w  #$7FF,d2
                move.w  $10(a5),d5
                move.w  $14(a5),d6
                tst.b   3(a5)
                bmi.s   Sprite_RenderMapping_CheckBounds
                sub.w   (SpriteShakeYOffset).w,d6
Sprite_RenderMapping_CheckBounds:                       ; was: loc_22E4
                cmpi.w  #$200,d6
                bcc.s   Sprite_RenderMappingClippedReturn
                cmpi.w  #$220,d5
                bcc.s   Sprite_RenderMappingClippedReturn
                move.b  $20(a5),d0
                andi.w  #$FC,d0
                movea.w d0,a1
                movea.w -$41FA(a1),a0
                move.b  d4,-5(a0)
                btst    #$B,d7
                bne.s   Sprite_RenderMapping_SelectXFlip
                lea     Sprite_RenderMapping_ApplyXOffset(pc),a0
                bra.s   Sprite_RenderMapping_NextEntry
; ---------------------------------------------------------------------------
; Selects the reflected-X offset path when tile-attribute bit 11 is set
Sprite_RenderMapping_SelectXFlip:                       ; was: loc_230E
                lea     Sprite_RenderMapping_ApplyXFlip(pc),a0
                subq.w  #7,d5
                bra.s   Sprite_RenderMapping_NextEntry
; Reflects one mapping entry's X offset using its encoded width
Sprite_RenderMapping_ApplyXFlip:                        ; was: sub_2316
                neg.w   d0
                move.b  -4(a4),d1
                add.w   d1,d1
                andi.w  #$18,d1
                sub.w   d1,d0
Sprite_RenderMapping_ApplyXOffset:                      ; was: loc_2324
                add.w   d5,d0
                bmi.s   Sprite_RenderMapping_ClampXToOne
                andi.w  #$1FF,d0
                bne.s   Sprite_RenderMapping_WriteTileAndX
Sprite_RenderMapping_ClampXToOne:                       ; was: loc_232E
                moveq   #1,d0
Sprite_RenderMapping_WriteTileAndX:                     ; was: loc_2330
                move.w  d3,d1
                bmi.s   Sprite_RenderMapping_WriteFinalTileAndX
                eor.w   d7,d1
                add.w   d2,d1
                move.w  d1,(a3)+
                move.w  d0,(a3)+
Sprite_RenderMapping_NextEntry:                         ; was: loc_233C
                                        ; Sprite_RenderMapping+50   j
                cmpi.b  #$50,d4                         ; 'P'
                bge.s   Sprite_RenderMappingReturn
                move.w  (a4)+,d3
                move.w  (a4)+,d0
                move.w  d0,d1
                swap    d0
                move.b  (a4)+,d0
                ext.w   d0
                btst    #$C,d7
                beq.s   Sprite_RenderMapping_ApplyYOffset
                neg.w   d0
                lsr.w   #5,d1
                andi.w  #$18,d1
                addq.w  #8,d1
                sub.w   d1,d0
Sprite_RenderMapping_ApplyYOffset:                      ; was: loc_2360
                add.w   d6,d0
                addq.b  #1,d4
                swap    d0
                move.b  d4,d0
                move.l  d0,(a3)+
                move.b  (a4)+,d0
                ext.w   d0
                jmp     (a0)
; ---------------------------------------------------------------------------
Sprite_RenderMapping_WriteFinalTileAndX:                ; was: loc_2370
                andi.w  #$7FFF,d1
                eor.w   d7,d1
                add.w   d2,d1
                move.w  d1,(a3)+
                move.w  d0,(a3)+
                move.w  a3,-$41FA(a1)
Sprite_RenderMappingReturn:                             ; was: locret_2380
                rts
; End of function Sprite_RenderMapping
Sprite_RenderDynamicMappingClippedReturn:               ; was: nullsub_12
                                        ; Sprite_RenderDynamicMapping+2A   j
                rts
; End of function Sprite_RenderDynamicMappingClippedReturn

; Expands a dynamic-art mapping into OAM while recording its DMA source pointers
Sprite_RenderDynamicMapping:                            ; was: sub_2384
                                        ; Sprite_RenderDynamicObject+38   p
                move.w  $E(a5),d7
                move.w  d7,d2
                andi.w  #$F800,d7
                andi.w  #$7FF,d2
                move.w  $10(a5),d5
                move.w  $14(a5),d6
                tst.b   3(a5)
                bmi.s   Sprite_RenderDynamicMapping_CheckBounds
                sub.w   (SpriteShakeYOffset).w,d6
Sprite_RenderDynamicMapping_CheckBounds:                ; was: loc_23A4
                cmpi.w  #$200,d6
                bcc.s   Sprite_RenderDynamicMappingClippedReturn
                cmpi.w  #$220,d5
                bcc.s   Sprite_RenderDynamicMappingClippedReturn
                move.b  $20(a5),d0
                andi.w  #$FC,d0
                movea.w d0,a1
                movea.w -$41FA(a1),a0
                move.b  d4,-5(a0)
                btst    #$B,d7
                bne.s   Sprite_RenderDynamicMapping_SelectXFlip
                lea     Sprite_RenderDynamicMapping_ApplyXOffset(pc),a0
                bra.s   Sprite_RenderDynamicMapping_NextEntry
; ---------------------------------------------------------------------------
Sprite_RenderDynamicMapping_SelectXFlip:                ; was: loc_23CE
                lea     Sprite_RenderDynamicMapping_ApplyXFlip(pc),a0
                subq.w  #8,d5
Sprite_RenderDynamicMapping_NextEntry:                  ; was: loc_23D4
                                        ; Sprite_RenderDynamicMapping+B4   j
                cmpi.b  #$50,d4                         ; 'P'
                bge.s   Sprite_RenderDynamicMappingReturn
                move.w  (a4)+,d3
                move.l  (a4)+,d0
                move.l  d0,(a2)+
                swap    d0
                move.b  d4,d0
                move.w  d0,d4
                move.b  (a4)+,d0
                ext.w   d0
                btst    #$C,d7
                beq.s   Sprite_RenderDynamicMapping_ApplyYOffset
                neg.w   d0
                move.w  d4,d1
                lsr.w   #5,d1
                andi.w  #$18,d1
                addi.w  #9,d1
                sub.w   d1,d0
Sprite_RenderDynamicMapping_ApplyYOffset:               ; was: loc_2400
                add.w   d6,d0
                move.w  d0,(a3)+
                addq.b  #1,d4
                move.w  d4,(a3)+
                move.w  d3,d0
                andi.w  #$1FFF,d0
                eor.w   d7,d0
                add.w   d2,d0
                move.w  d0,(a3)+
                move.b  (a4)+,d0
                ext.w   d0
                jmp     (a0)
; ---------------------------------------------------------------------------
Sprite_RenderDynamicMapping_ApplyXFlip:                 ; was: loc_241A
                neg.w   d0
                move.b  -6(a4),d1
                add.w   d1,d1
                andi.w  #$18,d1
                sub.w   d1,d0
Sprite_RenderDynamicMapping_ApplyXOffset:               ; was: loc_2428
                add.w   d5,d0
                bmi.s   Sprite_RenderDynamicMapping_ClampXToOne
                andi.w  #$1FF,d0
                bne.s   Sprite_RenderDynamicMapping_WriteXAndContinue
Sprite_RenderDynamicMapping_ClampXToOne:                ; was: loc_2432
                moveq   #1,d0
Sprite_RenderDynamicMapping_WriteXAndContinue:          ; was: loc_2434
                move.w  d0,(a3)+
                add.w   d3,d3
                bcc.s   Sprite_RenderDynamicMapping_NextEntry
                move.w  a3,-$41FA(a1)
Sprite_RenderDynamicMappingReturn:                      ; was: locret_243E
                rts
; End of function Sprite_RenderDynamicMapping
Sprite_RenderDynamicMappingWithEntryAttributesClippedReturn:  ; was: nullsub_13
                                        ; Sprite_RenderDynamicMappingWithEntryAttributes+2A   j
                rts
; End of function Sprite_RenderDynamicMappingWithEntryAttributesClippedReturn

; Expands a dynamic-art mapping while retaining its per-entry tile attributes
Sprite_RenderDynamicMappingWithEntryAttributes:         ; was: sub_2442
                                        ; Sprite_RenderDynamicObjectWithEntryAttributes+4A   p
                move.w  $E(a5),d7
                move.w  d7,d2
                andi.w  #$F800,d7
                andi.w  #$7FF,d2
                move.w  $10(a5),d5
                move.w  $14(a5),d6
                tst.b   3(a5)
                bmi.s   Sprite_RenderDynamicMappingWithEntryAttributes_CheckBounds
                sub.w   (SpriteShakeYOffset).w,d6
Sprite_RenderDynamicMappingWithEntryAttributes_CheckBounds:  ; was: loc_2462
                cmpi.w  #$200,d6
                bcc.s   Sprite_RenderDynamicMappingWithEntryAttributesClippedReturn
                cmpi.w  #$220,d5
                bcc.s   Sprite_RenderDynamicMappingWithEntryAttributesClippedReturn
                move.b  $20(a5),d0
                andi.w  #$FC,d0
                movea.w d0,a1
                movea.w -$41FA(a1),a0
                move.b  d4,-5(a0)
                btst    #$B,d7
                bne.s   Sprite_RenderDynamicMappingWithEntryAttributes_SelectXFlip
                lea     Sprite_RenderDynamicMappingWithEntryAttributes_ApplyXOffset(pc),a0
                bra.s   Sprite_RenderDynamicMappingWithEntryAttributes_NextEntry
; ---------------------------------------------------------------------------
Sprite_RenderDynamicMappingWithEntryAttributes_SelectXFlip:  ; was: loc_248C
                lea     Sprite_RenderDynamicMappingWithEntryAttributes_ApplyXFlip(pc),a0
                subi.w  #9,d5
Sprite_RenderDynamicMappingWithEntryAttributes_NextEntry:  ; was: loc_2494
                                        ; Sprite_RenderDynamicMappingWithEntryAttributes+B6   j
                cmpi.b  #$50,d4                         ; 'P'
                bge.s   Sprite_RenderDynamicMappingWithEntryAttributesReturn
                move.w  (a4)+,d3
                move.l  (a4)+,d0
                move.l  d0,(a2)+
                swap    d0
                move.b  d4,d0
                move.w  d0,d4
                move.b  (a4)+,d0
                ext.w   d0
                btst    #$C,d7
                beq.s   Sprite_RenderDynamicMappingWithEntryAttributes_ApplyYOffset
                neg.w   d0
                move.w  d4,d1
                lsr.w   #5,d1
                andi.w  #$18,d1
                addi.w  #9,d1
                sub.w   d1,d0
Sprite_RenderDynamicMappingWithEntryAttributes_ApplyYOffset:  ; was: loc_24C0
                add.w   d6,d0
                move.w  d0,(a3)+
                addq.b  #1,d4
                move.w  d4,(a3)+
                move.w  d3,d0
                andi.w  #$7FFF,d0
                eor.w   d7,d0
                add.w   d2,d0
                move.w  d0,(a3)+
                move.b  (a4)+,d0
                ext.w   d0
                jmp     (a0)
; ---------------------------------------------------------------------------
Sprite_RenderDynamicMappingWithEntryAttributes_ApplyXFlip:  ; was: loc_24DA
                neg.w   d0
                move.b  -6(a4),d1
                add.w   d1,d1
                andi.w  #$18,d1
                sub.w   d1,d0
Sprite_RenderDynamicMappingWithEntryAttributes_ApplyXOffset:  ; was: loc_24E8
                add.w   d5,d0
                bmi.s   Sprite_RenderDynamicMappingWithEntryAttributes_ClampXToOne
                andi.w  #$1FF,d0
                bne.s   Sprite_RenderDynamicMappingWithEntryAttributes_WriteXAndContinue
Sprite_RenderDynamicMappingWithEntryAttributes_ClampXToOne:  ; was: loc_24F2
                moveq   #1,d0
Sprite_RenderDynamicMappingWithEntryAttributes_WriteXAndContinue:  ; was: loc_24F4
                move.w  d0,(a3)+
                add.w   d3,d3
                bcc.s   Sprite_RenderDynamicMappingWithEntryAttributes_NextEntry
                move.w  a3,-$41FA(a1)
Sprite_RenderDynamicMappingWithEntryAttributesReturn:   ; was: locret_24FE
                rts
; End of function Sprite_RenderDynamicMappingWithEntryAttributes
; Selects a six-byte table frame, retaining and XOR-merging the object's priority bit
Anim_SelectTableFrameMergePriority:                     ; was: sub_2500
                move.b  9(a5),d0
                beq.w   Anim_SelectTableFrameMergePriority_LoadCurrentEntry
                addq.b  #1,d0
                beq.w   Anim_SelectTableFrameMergePriorityReturn
                subq.b  #1,9(a5)
                beq.w   Anim_SelectTableFrameMergePriority_AdvanceEntry
Anim_SelectTableFrameMergePriorityReturn:               ; was: locret_2516
                rts
; ---------------------------------------------------------------------------
Anim_SelectTableFrameMergePriority_LoadCurrentEntry:    ; was: loc_2518
                move.w  $C(a5),d0
                bra.w   Anim_SelectTableFrameMergePriority_ResolveEntry
; ---------------------------------------------------------------------------
Anim_SelectTableFrameMergePriority_FollowRelativeRedirect:  ; was: loc_2520
                move.w  d1,d0
                bra.w   Anim_SelectTableFrameMergePriority_ResolveEntry
; ---------------------------------------------------------------------------
Anim_SelectTableFrameMergePriority_AdvanceEntry:        ; was: loc_2526
                move.w  $C(a5),d0
                addq.w  #6,d0
Anim_SelectTableFrameMergePriority_ResolveEntry:        ; was: loc_252C
                                        ; Anim_SelectTableFrameMergePriority+22   j
                move.l  (a0,d0.w),d1
                bmi.s   Anim_SelectTableFrameMergePriority_FollowRelativeRedirect
                move.l  d1,8(a5)
                move.w  4(a0,d0.w),d1
                andi.w  #$8000,$E(a5)
                eor.w   d1,$E(a5)
                move.w  d0,$C(a5)
                rts
; End of function Anim_SelectTableFrameMergePriority
; Selects a six-byte table frame and replaces the object's tile attributes
Anim_SelectTableFrame:                                  ; was: sub_254A
                move.b  9(a5),d0
                beq.w   Anim_SelectTableFrame_LoadCurrentEntry
                addq.b  #1,d0
                beq.w   Anim_SelectTableFrameReturn
                subq.b  #1,9(a5)
                beq.w   Anim_SelectTableFrame_AdvanceEntry
Anim_SelectTableFrameReturn:                            ; was: locret_2560
                rts
; ---------------------------------------------------------------------------
Anim_SelectTableFrame_LoadCurrentEntry:                 ; was: loc_2562
                move.w  $C(a5),d0
                bra.w   Anim_SelectTableFrame_ResolveEntry
; ---------------------------------------------------------------------------
Anim_SelectTableFrame_FollowRelativeRedirect:           ; was: loc_256A
                move.w  d1,d0
                bra.w   Anim_SelectTableFrame_ResolveEntry
; ---------------------------------------------------------------------------
Anim_SelectTableFrame_AdvanceEntry:                     ; was: loc_2570
                move.w  $C(a5),d0
                addq.w  #6,d0
Anim_SelectTableFrame_ResolveEntry:                     ; was: loc_2576
                                        ; Anim_SelectTableFrame+22   j
                move.l  (a0,d0.w),d1
                bmi.s   Anim_SelectTableFrame_FollowRelativeRedirect
                move.l  d1,8(a5)
                move.w  4(a0,d0.w),$E(a5)
                move.w  d0,$C(a5)
                rts
; End of function Anim_SelectTableFrame
; Appends terminated eight-byte OAM entries and links them through their priority buckets
Sprite_AppendOAMEntries:                                ; was: sub_258C
                                        ; Cutscene_RenderShipSpriteGrid+7C   j
                movea.l a0,a4
                move.b  (SpriteOAMEntryCount).w,d4
                movea.w (SpriteOAMWritePointer).w,a3
                ; MOVEA preserves CCR: BEQ tests the loaded entry count
                beq.w   Sprite_AppendOAMEntriesReturn
Sprite_AppendOAMEntries_Loop:                           ; was: loc_259A
                cmpi.b  #$50,d4                         ; 'P'
                bge.s   Sprite_AppendOAMEntries_StoreState
                move.l  (a0)+,(a3)+
                move.b  -(a3),d0
                andi.w  #$FC,d0
                movea.w d0,a1
                movea.w -$41FA(a1),a2
                move.b  d4,-5(a2)
                addq.b  #1,d4
                move.b  d4,(a3)+
                move.l  (a0)+,(a3)+
                move.w  a3,-$41FA(a1)
                cmpi.w  #$FFFF,(a0)
                bne.s   Sprite_AppendOAMEntries_Loop
Sprite_AppendOAMEntries_StoreState:                     ; was: loc_25C2
                move.w  a3,(SpriteOAMWritePointer).w
                move.b  d4,(SpriteOAMEntryCount).w
                movea.l a4,a0
Sprite_AppendOAMEntriesReturn:                          ; was: locret_25CC
                rts
; End of function Sprite_AppendOAMEntries
; Appends terminated world-space OAM entries after vertical camera clipping and translation
Sprite_AppendWorldOAMEntries:                           ; was: sub_25CE
                movea.l a0,a4
                move.b  (SpriteOAMEntryCount).w,d4
                movea.w (SpriteOAMWritePointer).w,a3
Sprite_AppendWorldOAMEntries_Loop:                      ; was: loc_25D8
                cmpi.b  #$50,d4                         ; 'P'
                bge.s   Sprite_AppendWorldOAMEntries_StoreState
                move.b  3(a0),d0
                andi.w  #$FC,d0
                movea.w d0,a1
                movea.w -$41FA(a1),a2
                move.b  d4,-5(a2)
                move.w  (a0),d6
                sub.w   (SpriteShakeYOffset).w,d6
                cmpi.w  #$200,d6
                bcs.s   Sprite_AppendWorldOAMEntries_WriteEntry
                clr.w   d6
Sprite_AppendWorldOAMEntries_WriteEntry:                ; was: loc_25FE
                move.w  d6,(a3)+
                move.w  2(a0),d0
                addq.b  #1,d4
                move.b  d4,d0
                move.w  d0,(a3)+
                move.w  4(a0),(a3)+
                move.w  6(a0),d5
                cmpi.w  #$220,d5
                bcs.s   Sprite_AppendWorldOAMEntries_NormalizeX
                clr.w   -6(a3)
Sprite_AppendWorldOAMEntries_NormalizeX:                ; was: loc_261C
                andi.w  #$1FF,d5
                bne.s   Sprite_AppendWorldOAMEntries_WriteX
                addq.w  #1,d5
Sprite_AppendWorldOAMEntries_WriteX:                    ; was: loc_2624
                move.w  d5,(a3)+
                move.w  a3,-$41FA(a1)
                addq.w  #8,a0
                cmpi.w  #$FFFF,(a0)
                bne.s   Sprite_AppendWorldOAMEntries_Loop
Sprite_AppendWorldOAMEntries_StoreState:                ; was: loc_2632
                move.w  a3,(SpriteOAMWritePointer).w
                move.b  d4,(SpriteOAMEntryCount).w
                movea.l a4,a0
                rts
; End of function Sprite_AppendWorldOAMEntries
