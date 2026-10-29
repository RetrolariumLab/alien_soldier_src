; Seven Force post-battle transition controller
; Dispatch the post-battle transition requested by the completed boss
Boss_QueueSevenForcePostBattleTransition:               ; CODE XREF: Entity_UpdateValkirieBattle+26   j  ; was: sub_555C8
                                        ; Boss_UpdateMedusa+26   j
                bset    #0,(StageTimerPauseFlag).w
                movea.w #(Entity60Type-M68K_RAM),a5
                bsr.s   Entity_DispatchSevenForcePostBattleTransition
                movea.w #(Entity_ObjectPool-M68K_RAM),a5
                rts
; End of function Boss_QueueSevenForcePostBattleTransition
; Dispatch a post-battle transition by the caller-supplied even index
Entity_DispatchSevenForcePostBattleTransition:          ; CODE XREF: Boss_QueueSevenForcePostBattleTransition+A   p  ; was: sub_555DA
                movea.w Entity_SevenForcePostBattleTransitionOffsets(pc,d0.w),a1
                adda.l  #Entity_ResetSevenForceTransitionController,a1
                jmp     (a1)
; End of function Entity_DispatchSevenForcePostBattleTransition
; ---------------------------------------------------------------------------
Entity_SevenForcePostBattleTransitionOffsets:   dc.w    Entity_ResetSevenForceTransitionController-Entity_ResetSevenForceTransitionController  ; was: off_555E6
                                        ; DATA XREF: Entity_DispatchSevenForcePostBattleTransition   r
                dc.w    Entity_StartSevenForceMedusaTransition-Entity_ResetSevenForceTransitionController
                dc.w    Entity_StartSevenForceSylpheedTransition-Entity_ResetSevenForceTransitionController
                dc.w    Entity_StartSevenForceArtemisTransition-Entity_ResetSevenForceTransitionController
                dc.w    Entity_StartSevenForceSireneTransition-Entity_ResetSevenForceTransitionController
                dc.w    Entity_ResumeSevenForceIntroState24-Entity_ResetSevenForceTransitionController
                dc.w    Entity_ResumeSevenForceIntroState26-Entity_ResetSevenForceTransitionController
                dc.w    Entity_StartSevenForceFinalTransition-Entity_ResetSevenForceTransitionController
                dc.w    Entity_SevenForcePostBattleNoOp-Entity_ResetSevenForceTransitionController

; Reset the Seven Force transition controller state
Entity_ResetSevenForceTransitionController:             ; DATA XREF: Entity_DispatchSevenForcePostBattleTransition+4   o  ; was: sub_555F8
                                        ; ROM:Entity_SevenForcePostBattleTransitionOffsets   o
                move.w  #0,4(a5)
                rts
; End of function Entity_ResetSevenForceTransitionController
; Start the Medusa form transition after Valkirie completes
Entity_StartSevenForceMedusaTransition:                 ; DATA XREF: ROM:000555E8   o  ; was: sub_55600
                move.w  #$10,4(a5)
                bsr.w   Entity_InitSevenForceTransitionSprite
                move.w  #$428,d0
                moveq   #0,d1
                jsr     (Object_ClearEntityRecordsExceptTwoTypes).l
                move.w  #$FFF4,$5E(a5)
                bsr.w   Gfx_UpdateSevenForceMultiRangePaletteFade
                move.b  #$30,d0                         ; '0'
                jmp     (Sound_QueueSFXRequest).l
; End of function Entity_StartSevenForceMedusaTransition
; Start the Sylpheed form transition after Medusa completes
Entity_StartSevenForceSylpheedTransition:               ; DATA XREF: ROM:000555EA   o  ; was: sub_5562A
                move.w  #$18,4(a5)
                bsr.w   Entity_InitSevenForceTransitionSprite
                move.w  #$428,d0
                moveq   #0,d1
                jsr     (Object_ClearEntityRecordsExceptTwoTypes).l
                lea     (SevenForceSylpheedTransitionPaletteCommand).l,a0
                jsr     (Gfx_LoadPaletteCommand).l
                move.w  #$FFF2,$5E(a5)
                bsr.w   Gfx_UpdateSevenForceMultiRangePaletteFade
                clr.b   (VDPReg11Shadow+1).w
                clr.b   (PlaneAScrollModeFlags).w
                clr.b   (PlaneBScrollModeFlags).w
                move.b  #$30,d0                         ; '0'
                jmp     (Sound_QueueSFXRequest).l
; End of function Entity_StartSevenForceSylpheedTransition
; Start the Artemis form transition after Sylpheed completes
Entity_StartSevenForceArtemisTransition:                ; DATA XREF: ROM:000555EC   o  ; was: sub_5566C
                move.b  #1,(SceneSequenceFlags).w
                move.w  #$22,4(a5)                      ; '"'
                bsr.w   Entity_InitSevenForceTransitionSprite
                move.w  #$428,d0
                moveq   #0,d1
                jsr     (Object_ClearEntityRecordsExceptTwoTypes).l
                lea     (SevenForceArtemisTransitionPaletteCommand).l,a0
                jsr     (Gfx_LoadPaletteCommand).l
                move.w  #$FFF2,$5E(a5)
                bsr.w   Gfx_UpdateSevenForceMultiRangePaletteFade
                move.b  #$30,d0                         ; '0'
                jmp     (Sound_QueueSFXRequest).l
; End of function Entity_StartSevenForceArtemisTransition
; Start the Sirene form transition after Artemis completes
Entity_StartSevenForceSireneTransition:                 ; DATA XREF: ROM:000555EE   o  ; was: sub_556A8
                move.w  #$2A,4(a5)                      ; '*'
                bsr.w   Entity_InitSevenForceTransitionSprite
                move.w  #$428,d0
                moveq   #0,d1
                jsr     (Object_ClearEntityRecordsExceptTwoTypes).l
                move.w  #$FFF2,$5E(a5)
                bsr.w   Gfx_UpdateSevenForceMultiRangePaletteFade
                move.b  #$30,d0                         ; '0'
                jmp     (Sound_QueueSFXRequest).l
; End of function Entity_StartSevenForceSireneTransition
; Resume the intro controller at state $24 and clear obsolete objects
Entity_ResumeSevenForceIntroState24:                    ; DATA XREF: ROM:000555F0   o  ; was: sub_556D2
                move.w  #$24,4(a5)                      ; '$'
                move.b  #1,(SceneSequenceFlags).w
                move.w  #$428,d0
                moveq   #0,d1
                jsr     (Object_ClearEntityRecordsExceptTwoTypes).l
                move.b  #$30,d0                         ; '0'
                jmp     (Sound_QueueSFXRequest).l
; End of function Entity_ResumeSevenForceIntroState24
; Resume the intro controller at state $26 and clear obsolete objects
Entity_ResumeSevenForceIntroState26:                    ; DATA XREF: ROM:000555F2   o  ; was: sub_556F4
                move.w  #$26,4(a5)                      ; '&'
                move.b  #1,(SceneSequenceFlags).w
                move.w  #$428,d0
                moveq   #0,d1
                jsr     (Object_ClearEntityRecordsExceptTwoTypes).l
                move.b  #$30,d0                         ; '0'
                jmp     (Sound_QueueSFXRequest).l
; End of function Entity_ResumeSevenForceIntroState26
; Start the final explosion sequence after Sirene completes
Entity_StartSevenForceFinalTransition:                  ; DATA XREF: ROM:000555F4   o  ; was: sub_55716
                move.w  #$36,4(a5)                      ; '6'
                bclr    #0,(PlayerObjectFlags).w
                bset    #0,(PlayerModeFlags).w
                bclr    #2,(PlayerModeFlags).w
                clr.w   $48(a5)
                clr.b   (VDPReg11Shadow+1).w
                clr.b   (PlaneAScrollModeFlags).w
                clr.b   (PlaneBScrollModeFlags).w
                move.b  #1,(SceneSequenceFlags).w
                move.w  #$428,d0
                moveq   #0,d1
                jsr     (Object_ClearEntityRecordsExceptTwoTypes).l
                move.w  #$FFF2,$5E(a5)
                bsr.w   Gfx_UpdateSevenForceMultiRangePaletteFade
                rts
; End of function Entity_StartSevenForceFinalTransition
; Intentional no-op post-battle transition entry
Entity_SevenForcePostBattleNoOp:                        ; DATA XREF: ROM:000555F6   o  ; was: nullsub_127
                rts
; End of function Entity_SevenForcePostBattleNoOp
