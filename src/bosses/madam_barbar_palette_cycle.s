; Cycles the signed fade step applied to Madam Barbar's four-color palette
Boss_MadamBarbarUpdatePaletteCycle:
                move.w  8(a5),d0                        ; was: sub_3A0EA
                tst.w   $A(a5)
                beq.s   Boss_MadamBarbarDecreasePaletteStep
                addq.w  #1,d0
                cmpi.w  #$E,d0
                bne.s   Boss_MadamBarbarApplyPaletteStep
                clr.w   $A(a5)
                bra.s   Boss_MadamBarbarApplyPaletteStep
; ---------------------------------------------------------------------------
Boss_MadamBarbarDecreasePaletteStep:                    ; was: loc_3A102
                subq.w  #1,d0
                cmpi.w  #$FFF2,d0
                bne.s   Boss_MadamBarbarApplyPaletteStep
                addq.w  #1,$A(a5)
Boss_MadamBarbarApplyPaletteStep:                       ; was: loc_3A10E
                                        ; Boss_MadamBarbarUpdatePaletteCycle+16   j
                move.w  d0,8(a5)
                movea.w #(PaletteActiveColor12-M68K_RAM),a0
                moveq   #3,d5
                move.w  #$E000,d7
                jmp     (Gfx_ApplyPaletteFade).l
; End of function Boss_MadamBarbarUpdatePaletteCycle
