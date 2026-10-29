; Decays the Plane A/B shake levels and publishes their current offsets
Effect_ScreenShakeUpdate:                               ; was: sub_1CB5A
                tst.b   (FrameControlFlags).w
                bmi.s   Effect_ScreenShakeUpdate_Return
                move.w  (PlaneAShakeOffset).w,(SpriteShakeYOffset).w
                move.w  (PlaneBShakeOffset).w,(PlaneBShakeWriteOnly).w
                move.w  (FrameCounter).w,d0
                tst.w   (PlaneAShakeLevel).w
                bne.s   Effect_ScreenShakeUpdate_UpdatePlaneA
Effect_ScreenShakeUpdate_ClearPlaneA:                   ; was: loc_1CB76
                clr.w   (PlaneAShakeOffset).w
                bra.s   Effect_ScreenShakeUpdate_CheckPlaneB
; ---------------------------------------------------------------------------
Effect_ScreenShakeUpdate_UpdatePlaneA:                  ; was: loc_1CB7C
                btst    #1,d0
                bne.s   Effect_ScreenShakeUpdate_ClearPlaneA
                move.w  d0,d1
                andi.w  #7,d1
                bne.s   Effect_ScreenShakeUpdate_StorePlaneA
                subq.w  #1,(PlaneAShakeLevel).w
Effect_ScreenShakeUpdate_StorePlaneA:                   ; was: loc_1CB8E
                move.w  (PlaneAShakeLevel).w,(PlaneAShakeOffset).w
Effect_ScreenShakeUpdate_CheckPlaneB:                   ; was: loc_1CB94
                tst.w   (PlaneBShakeLevel).w
                bne.s   Effect_ScreenShakeUpdate_UpdatePlaneB
Effect_ScreenShakeUpdate_ClearPlaneB:                   ; was: loc_1CB9A
                clr.w   (PlaneBShakeOffset).w
                rts
; ---------------------------------------------------------------------------
Effect_ScreenShakeUpdate_UpdatePlaneB:                  ; was: loc_1CBA0
                btst    #1,d0
                bne.s   Effect_ScreenShakeUpdate_ClearPlaneB
                move.w  d0,d1
                andi.w  #7,d1
                bne.s   Effect_ScreenShakeUpdate_StorePlaneB
                subq.w  #1,(PlaneBShakeLevel).w
Effect_ScreenShakeUpdate_StorePlaneB:                   ; was: loc_1CBB2
                move.w  (PlaneBShakeLevel).w,(PlaneBShakeOffset).w
Effect_ScreenShakeUpdate_Return:                        ; was: locret_1CBB8
                rts
; End of function Effect_ScreenShakeUpdate
