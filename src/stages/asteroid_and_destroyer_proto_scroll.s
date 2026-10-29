StageTransition_RenderAsteroidField:                    ; was: sub_FB24
                                        ; StageTransition_FinishAsteroidFieldScroll+E   j
                bsr.s   StageTransition_UpdateAsteroidFieldScroll
                moveq   #0,d0
                move.w  (PrimaryCameraYPosition).w,d1
                subi.w  #$F8,d1
                lea     (Gfx_DefaultVRAMTransferParameters).l,a0
                bra.w   Tilemap_QueueRowFromDescriptor
; End of function StageTransition_RenderAsteroidField
; Advances both asteroid-field positions and detects a $100 boundary crossing
StageTransition_UpdateAsteroidFieldScroll:              ; was: sub_FB3A
                                        ; StageTransition_StartAsteroidFieldScroll+C   j
                move.l  (AsteroidFieldVelocity).w,d0
                add.l   d0,(PrimaryCameraYPosition).w
                add.l   d0,(AsteroidFieldPosition).w
                clr.b   (AsteroidBoundaryFlag).w
                move.w  (AsteroidFieldPosition).w,d0
                andi.w  #$100,d0
                cmp.w   (AsteroidBoundaryPhase).w,d0
                beq.s   StageTransition_SharedReturn
                addq.b  #1,(AsteroidBoundaryFlag).w
                move.w  d0,(AsteroidBoundaryPhase).w
; Shared return for inactive or incomplete transition states
StageTransition_SharedReturn:                           ; was: locret_FB60
                                        ; StageTransition_InitializeDestroyerProtoBackdrop+8   j
                rts
; End of function StageTransition_UpdateAsteroidFieldScroll
; Unreferenced input-bit test that sets the transition completion flag
UnreferencedSetTransitionFlagFromInputBit6:
                btst    #6,(ControllerHeldState).w      ; was: sub_FB62
                beq.s   UnreferencedTransitionInputCheckReturn
                bset    #0,(SceneSequenceFlags).w
UnreferencedTransitionInputCheckReturn:                 ; was: locret_FB70
                rts
; End of function UnreferencedSetTransitionFlagFromInputBit6
; Integrates asteroid-field velocity and fills its vertical-scroll buffer
StageTransition_FillAsteroidFieldVScroll:               ; was: sub_FB72
                                        ; StageTransition_StartAsteroidFieldScroll   p
                move.l  (AsteroidVScrollPos).w,d0
                add.l   (AsteroidVScrollSpeed).w,d0
                move.l  d0,(AsteroidVScrollPos).w
                swap    d0
                movea.w #(HScrollPlaneARow32-M68K_RAM),a0
                move.w  #$BF,d7
StageTransition_FillAsteroidFieldVScrollLoop:           ; was: loc_FB88
                move.w  d0,(a0)
                addq.w  #4,a0
                dbf     d7,StageTransition_FillAsteroidFieldVScrollLoop
                rts
; End of function StageTransition_FillAsteroidFieldVScroll
; Unreferenced entry that updates and shifts the segmented V-scroll buffer
UnreferencedUpdateAndShiftTransitionVScroll:
                bsr.w   StageTransition_UpdateSegmentedBackdropScroll  ; was: sub_FB92
                movea.w #(HScrollPlaneARow32-M68K_RAM),a0
                moveq   #$5F,d7                         ; '_'
UnreferencedShiftTransitionVScrollLoop:                 ; was: loc_FB9C
                move.w  2(a0),(a0)
                addq.w  #4,a0
                dbf     d7,UnreferencedShiftTransitionVScrollLoop
                rts
; End of function UnreferencedUpdateAndShiftTransitionVScroll
; Updates the segmented transition backdrop's motion and V-scroll pattern
StageTransition_UpdateSegmentedBackdropScroll:          ; was: sub_FBA8
                                        ; StageTransition_StartAsteroidFieldScroll+4   p
                tst.w   (BackdropVelocityA).w
                bpl.s   StageTransition_DampenFirstBackdropVelocity
                cmpi.l  #$FFFF8080,(BackdropVelocityA).w
                bmi.s   StageTransition_CheckSecondBackdropVelocity
StageTransition_DampenFirstBackdropVelocity:            ; was: loc_FBB8
                subi.l  #$40,(BackdropVelocityA).w      ; '@'
StageTransition_CheckSecondBackdropVelocity:            ; was: loc_FBC0
                tst.w   (BackdropVelocityB).w
                bpl.s   StageTransition_DampenSecondBackdropVelocity
                cmpi.l  #$FFFF8000,(BackdropVelocityB).w
                bmi.s   StageTransition_ApplySegmentedBackdropMotion
StageTransition_DampenSecondBackdropVelocity:           ; was: loc_FBD0
                subi.l  #$40,(BackdropVelocityB).w      ; '@'
StageTransition_ApplySegmentedBackdropMotion:           ; was: loc_FBD8
                                        ; StageTransition_UpdatePostDestroyerProtoScroll+4   p
                move.l  (BackdropVelocityA).w,d0
                add.l   d0,(BackdropPositionA).w
                add.l   d0,(BackdropCameraYPos).w
                move.l  (BackdropPositionB).w,d0
                add.l   (BackdropVelocityB).w,d0
                move.l  d0,(BackdropPositionB).w
                swap    d0
                move.w  d0,d1
                move.w  d0,d2
                move.w  d0,d3
                move.w  d0,d4
                move.w  d0,d5
                move.w  d0,d6
                asr.w   #1,d1
                asr.w   #2,d2
                asr.w   #3,d3
                asr.w   #4,d4
                asr.w   #5,d5
                asr.w   #6,d6
                movea.w #(BackdropScrollPattern-M68K_RAM),a0
                moveq   #1,d7
StageTransition_BuildBackdropScrollPattern:             ; was: loc_FC10
                move.w  d0,(a0)+
                move.w  d1,(a0)+
                move.w  d2,(a0)+
                move.w  d3,(a0)+
                dbf     d7,StageTransition_BuildBackdropScrollPattern
                move.w  (VScrollPlaneBColumn0).w,d7
                andi.w  #3,d7
                asl.w   #1,d7
                movea.w #(BackdropScrollPattern-M68K_RAM),a0
                adda.w  d7,a0
                move.w  (a0)+,d0
                move.w  (a0)+,d1
                move.w  (a0)+,d2
                move.w  (a0)+,d3
                btst    #0,(FrameCounter+1).w
                beq.s   StageTransition_CheckBackdropScrollParity
                asr.w   #1,d0
                asr.w   #1,d1
                asr.w   #1,d2
                asr.w   #1,d3
StageTransition_CheckBackdropScrollParity:              ; was: loc_FC44
                movea.w #(HScrollPlaneBRow32-M68K_RAM),a0
                move.w  #$2F,d7                         ; '/'
StageTransition_FillSegmentedBackdropVScroll:           ; was: loc_FC4C
                move.w  d0,(a0)
                addq.w  #4,a0
                move.w  d1,(a0)
                addq.w  #4,a0
                move.w  d2,(a0)
                addq.w  #4,a0
                move.w  d3,(a0)
                addq.w  #4,a0
                dbf     d7,StageTransition_FillSegmentedBackdropVScroll
                move.l  (BackdropCameraYPos).w,d0
                btst    #0,(FrameCounter+1).w
                bne.s   StageTransition_StoreSegmentedBackdropOutput
                asr.l   #1,d0
StageTransition_StoreSegmentedBackdropOutput:           ; was: loc_FC6E
                move.l  d0,(SecondaryCameraYPos).w
                rts
; End of function StageTransition_UpdateSegmentedBackdropScroll
