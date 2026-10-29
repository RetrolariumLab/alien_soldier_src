; Traverses display objects, resolves mappings, builds OAM, and queues dynamic art DMA
Sprite_RenderObjectList:                                ; was: sub_2016
                                        ; UI_UpdateOptionsScreen+68   p
                tst.b   (SpriteOAMBuildActive).w
                bne.w   Sprite_RenderObjectList_Begin
                bsr.w   Sprite_InitializePriorityBuckets
Sprite_RenderObjectList_Begin:                          ; was: loc_2022
                move.b  (FrameControlFlags).w,d3
                ror.l   #8,d3
                move.b  (SpriteOAMEntryCount).w,d4
                movea.w (SpriteOAMWritePointer).w,a3
                lea     (PlayerObjectType).w,a5
                bsr.w   Sprite_RenderDynamicObject
                move.w  (VisibleObjectCount).w,d2
                beq.w   Sprite_RenderObjectList_Finalize
                subq.w  #1,d2
                lea     (VisibleObjectList).w,a2
Sprite_RenderObjectList_ObjectLoop:                     ; was: loc_2046
                movea.w (a2)+,a5
                move.b  2(a5),d7
                bpl.s   Sprite_RenderObjectList_HandleAlternateFlags
                add.b   d7,d7
                bpl.w   Sprite_RenderSingleObjectEntry
                movea.l 8(a5),a4
                add.b   d7,d7
                bpl.s   Sprite_RenderObjectList_RenderMapping
                bsr.w   Anim_ResolveTimedMappingFrame
Sprite_RenderObjectList_RenderMapping:                  ; was: loc_2060
                swap    d2
                bsr.w   Sprite_RenderMapping
                swap    d2
Sprite_RenderObjectList_NextObject:                     ; was: loc_2068
                                        ; Sprite_RenderObjectList+66   j
                dbf     d2,Sprite_RenderObjectList_ObjectLoop
Sprite_RenderObjectList_Finalize:                       ; was: loc_206C
                move.b  d4,(SpriteOAMEntryCount).w
                move.w  a3,(SpriteOAMWritePointer).w
                bra.w   Sprite_FinalizePriorityLinks
; ---------------------------------------------------------------------------
Sprite_RenderObjectList_HandleAlternateFlags:           ; was: loc_2078
                beq.s   Sprite_RenderObjectList_NextObject
                add.b   d7,d7
                bpl.s   Sprite_RenderObjectList_NextObject
                add.b   d7,d7
                bpl.s   Sprite_RenderObjectList_NextObject
                movea.l 8(a5),a4
                pea     Sprite_RenderObjectList_NextObject(pc)
                bra.w   Anim_ResolveTimedMappingFrame
; End of function Sprite_RenderObjectList
; Renders the dynamic-art object, rebuilding and uploading its cached tile sources when its mapping changes
Sprite_RenderDynamicObject:                             ; was: sub_208E
                move.w  2(a5),d7
                bmi.w   Sprite_RenderDynamicObject_Active
                beq.s   Sprite_RenderDynamicObject_Return
                movea.l 8(a5),a4
                bra.w   Sprite_LoadObjectMappingPointer
; ---------------------------------------------------------------------------
Sprite_RenderDynamicObject_Active:                      ; was: loc_20A0
                move.l  8(a5),d0
                beq.w   Sprite_RenderDynamicObject_Return
                movea.l d0,a4
                bsr.w   Sprite_LoadObjectMappingPointer
                btst    #5,d7
                bne.w   Sprite_RenderMapping
                lea     $E0(a5),a2
                cmpa.l  $DC(a5),a4
                beq.w   Sprite_RenderDynamicMapping
                move.l  a4,$DC(a5)
                bsr.w   Sprite_RenderDynamicMapping
                lea     $E0(a5),a4
                cmpa.w  a4,a2
                beq.w   Sprite_RenderDynamicObject_Return
                movea.w (VDPCommandQueueHead).w,a0
                move.w  $DA(a5),d0
Sprite_RenderDynamicObject_QueueDMATransfersLoop:       ; was: loc_20DC
                movea.l (a4)+,a1
                jsr     (Gfx_PrependDMATransferCommand).l
                cmpa.w  a4,a2
                bhi.s   Sprite_RenderDynamicObject_QueueDMATransfersLoop
                move.w  a0,(VDPCommandQueueHead).w
Sprite_RenderDynamicObject_Return:                      ; was: locret_20EC
                                        ; Sprite_RenderDynamicObject+16   j
                rts
; End of function Sprite_RenderDynamicObject
; Renders the dynamic-art object while retaining per-entry tile attributes from its mapping
Sprite_RenderDynamicObjectWithEntryAttributes:          ; was: sub_20EE
                move.b  2(a5),d7
                bmi.w   Sprite_RenderDynamicObjectWithEntryAttributes_Active
                beq.w   Sprite_RenderDynamicObjectWithEntryAttributes_Return
                add.b   d7,d7
                bpl.w   Sprite_RenderDynamicObjectWithEntryAttributes_Return
                add.b   d7,d7
                bpl.w   Sprite_RenderDynamicObjectWithEntryAttributes_Return
                movea.l 8(a5),a4
                bra.w   Sprite_LoadObjectMappingPointer
; ---------------------------------------------------------------------------
Sprite_RenderDynamicObjectWithEntryAttributes_Active:   ; was: loc_210E
                move.l  8(a5),d0
                beq.w   Sprite_RenderDynamicObjectWithEntryAttributes_Return
                movea.l d0,a4
                btst    #5,d7
                beq.w   Sprite_RenderDynamicObjectWithEntryAttributes_UpdateCache
                movea.l 8(a5),a4
                bsr.w   Sprite_LoadObjectMappingPointer
Sprite_RenderDynamicObjectWithEntryAttributes_UpdateCache:  ; was: loc_2128
                lea     $E0(a5),a2
                cmpa.l  $DC(a5),a4
                beq.w   Sprite_RenderDynamicMappingWithEntryAttributes
                move.l  a4,$DC(a5)
                bsr.w   Sprite_RenderDynamicMappingWithEntryAttributes
                lea     $E0(a5),a4
                cmpa.w  a4,a2
                beq.w   Sprite_RenderDynamicObjectWithEntryAttributes_Return
                movea.w (VDPCommandQueueHead).w,a0
                move.w  $DA(a5),d0
Sprite_RenderDynamicObjectWithEntryAttributes_QueueDMATransfersLoop:  ; was: loc_214E
                movea.l (a4)+,a1
                jsr     (Gfx_PrependDMATransferCommand).l
                cmpa.w  a4,a2
                bhi.s   Sprite_RenderDynamicObjectWithEntryAttributes_QueueDMATransfersLoop
                move.w  a0,(VDPCommandQueueHead).w
Sprite_RenderDynamicObjectWithEntryAttributes_Return:   ; was: locret_215E
                                        ; Sprite_RenderDynamicObjectWithEntryAttributes+E   j
                rts
; End of function Sprite_RenderDynamicObjectWithEntryAttributes
; Resolves the current mapping from a timed relative-pointer sequence
Anim_ResolveTimedMappingFrame:                          ; was: sub_2160
                                        ; Sprite_RenderObjectList+74   j
                move.w  $C(a5),d0
                tst.b   d0
                bmi.s   Anim_ResolveTimedMappingFrame_ResolveMappingPointer
                beq.s   Anim_ResolveTimedMappingFrame_LoadInitialTimer
                tst.l   d3
                bmi.s   Anim_ResolveTimedMappingFrame_TickTimer
                subq.w  #1,d0
Anim_ResolveTimedMappingFrame_TickTimer:                ; was: loc_2170
                bne.s   Anim_ResolveTimedMappingFrame_StoreTimer
                addq.w  #4,a4
                move.w  2(a4),d0
                bne.s   Anim_ResolveTimedMappingFrame_StoreSequencePointer
                adda.w  (a4),a4
Anim_ResolveTimedMappingFrame_LoadInitialTimer:         ; was: loc_217C
                move.w  2(a4),d0
Anim_ResolveTimedMappingFrame_StoreSequencePointer:     ; was: loc_2180
                move.l  a4,8(a5)
Anim_ResolveTimedMappingFrame_StoreTimer:               ; was: loc_2184
                move.w  d0,$C(a5)
Anim_ResolveTimedMappingFrame_ResolveMappingPointer:    ; was: loc_2188
                adda.w  (a4),a4
                rts
; End of function Anim_ResolveTimedMappingFrame
; Loads the object's current mapping pointer without advancing its sequence
Sprite_LoadObjectMappingPointer:                        ; was: sub_218C
                                        ; Sprite_RenderDynamicObject+1C   p
                movea.l 8(a5),a4
                rts
; End of function Sprite_LoadObjectMappingPointer
; Resolves a byte-offset animation sequence with per-entry timers and relative jumps
Anim_ResolveOffsetSequenceFrame:                        ; was: sub_2192
                move.b  $D(a5),d0
                bmi.s   Anim_ResolveOffsetSequenceFrame_LoadPausedEntry
                bne.s   Anim_ResolveOffsetSequenceFrame_LoadCurrentEntry
                move.b  $C(a5),d1
                ext.w   d1
                adda.w  d1,a4
                move.b  3(a4),d0
                bra.w   Anim_ResolveOffsetSequenceFrame_TickTimer
; ---------------------------------------------------------------------------
Anim_ResolveOffsetSequenceFrame_LoadCurrentEntry:       ; was: loc_21AA
                move.b  $C(a5),d1
                ext.w   d1
                adda.w  d1,a4
                tst.b   (FrameControlFlags).w
                bmi.s   Anim_ResolveOffsetSequenceFrame_ResolveMappingPointer
Anim_ResolveOffsetSequenceFrame_TickTimer:              ; was: loc_21B8
                subq.b  #1,d0
                move.b  d0,$D(a5)
                bne.w   Anim_ResolveOffsetSequenceFrame_ResolveMappingPointer
                movea.l a4,a2
                addq.w  #4,a2
                addq.w  #4,d1
Anim_ResolveOffsetSequenceFrame_ScanEntries:            ; was: loc_21C8
                move.b  3(a2),d0
                beq.w   Anim_ResolveOffsetSequenceFrame_FollowRelativeJump
                move.b  d0,$D(a5)
                move.b  d1,$C(a5)
                adda.w  (a4),a4
                rts
; ---------------------------------------------------------------------------
Anim_ResolveOffsetSequenceFrame_FollowRelativeJump:     ; was: loc_21DC
                move.w  (a2),d0
                adda.w  d0,a2
                add.w   d0,d1
                bra.s   Anim_ResolveOffsetSequenceFrame_ScanEntries
; ---------------------------------------------------------------------------
Anim_ResolveOffsetSequenceFrame_LoadPausedEntry:        ; was: loc_21E4
                move.b  $C(a5),d1
                ext.w   d1
                adda.w  d1,a4
Anim_ResolveOffsetSequenceFrame_ResolveMappingPointer:  ; was: loc_21EC
                                        ; Anim_ResolveOffsetSequenceFrame+2C   j
                adda.w  (a4),a4
                rts
; End of function Anim_ResolveOffsetSequenceFrame
