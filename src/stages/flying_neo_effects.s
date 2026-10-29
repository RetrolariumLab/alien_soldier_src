; Initialize the Stage 8 Flying Neo composite rendered from the shared
; high-RAM display record
Stage8_InitializeFlyingNeoComposite:                    ; was: sub_D6D6
                movea.w #(Entity60Type-M68K_RAM),a0
                move.w  #$170,(a0)
                move.w  #$D00,2(a0)
                clr.w   4(a0)
                move.l  #Stage8_FlyingNeoCompositeSpriteAnimation,8(a0)
                clr.w   $C(a0)
                move.w  #$81E8,$E(a0)
                clr.b   $20(a0)
                move.w  #$910,$10(a0)
                move.w  #$110,$14(a0)
                clr.l   $18(a0)
                clr.l   $1C(a0)
                rts
; End of function Stage8_InitializeFlyingNeoComposite
; Spawn Flying Neo and queue its initial tile columns
Stage8_StartFlyingNeoCompositeAndQueueTiles:            ; was: sub_D714
                movea.w #(Entity60Type-M68K_RAM),a0
                addq.w  #2,4(a0)
                move.w  #$EF00,2(a0)
                move.l  #$FFFAE000,$18(a0)
                move.l  #$FFFE8000,$1C(a0)
                lea     Stage8_FlyingNeoInitialIndexedColumnDescriptor(pc),a0
                nop
                jmp     Tilemap_QueueIndexedColumns
; End of function Stage8_StartFlyingNeoCompositeAndQueueTiles
; Apply vertical acceleration while the type-$170 object is active
Entity_UpdateFlyingNeoGravity:                          ; was: sub_D73E
                tst.w   4(a5)
                beq.s   Entity_UpdateFlyingNeoGravity_Return
                addi.l  #$2000,$1C(a5)
Entity_UpdateFlyingNeoGravity_Return:                   ; was: locret_D74C
                rts
; End of function Entity_UpdateFlyingNeoGravity
; ---------------------------------------------------------------------------
Stage8_FlyingNeoInitialIndexedColumnDescriptor:
                dc.b    $66, $68, $40, 0, 1, 2, $1C, $1D, $21, $22, $26, $27  ; was: byte_D74E

; Load the shared Flying Neo/midgame palette command bank
Midgame_LoadFlyingNeoPaletteCommands:                   ; was: sub_D75A
                                        ; Stage9_InitializeFlyCorridor+24   p
                lea     (FlyingNeoAndMidgamePaletteCommandBank).l,a0
                jmp     Gfx_LoadPaletteCommand
; End of function Midgame_LoadFlyingNeoPaletteCommands
; Update the random Stage 8/9 lightning palette effect and optional composite
Midgame_UpdateRandomLightningEffect:                    ; was: sub_D766
                                        ; Stage8_UpdateFlyingNeoVerticalScrollAndEffects+3A   p
                move.w  (MidgameLightningMode).w,d7
                bmi.w   Midgame_UpdateRandomLightningEffect_Return
                tst.w   (PalettePrimaryIndex).w
                bne.w   Midgame_UpdateRandomLightningEffect_Return
                tst.w   (PaletteSecondaryIndex).w
                bne.w   Midgame_UpdateRandomLightningEffect_Return
                addq.w  #1,(LightningEffectTimer).w
                cmpi.w  #$42,(LightningEffectTimer).w   ; 'B'
                bne.w   Midgame_UpdateRandomLightningEffect_Return
                move.w  (RandomNumberState).w,d0
                andi.w  #$3F,d0                         ; '?'
                addq.w  #1,d0
                move.w  d0,(LightningEffectTimer).w
                move.w  (RandomNumberState).w,d0
                andi.w  #3,d0
                beq.s   Midgame_RandomLightningUseSecondaryPalette
                move.b  (RandomNumberState).w,d0
                andi.w  #7,d0
                addq.w  #3,d0
                move.w  d0,(PaletteEffectControl).w
                move.w  #8,(PalettePrimaryIndex).w
                rts
; ---------------------------------------------------------------------------
Midgame_RandomLightningUseSecondaryPalette:             ; was: loc_D7BA
                move.w  #2,(PaletteSecondaryIndex).w
                move.b  (RandomNumberState).w,d0
                andi.w  #6,d0
                addq.w  #8,d0
                move.w  d0,(PaletteEffectControl).w
                cmpi.w  #2,d7
                beq.s   Midgame_CreateRandomLightningComposite
                move.b  #$1A,d0
                jsr     (Sound_QueueSFXRequest).l
; Create the randomized high-RAM lightning composite unless mode one suppresses it
Midgame_CreateRandomLightningComposite:                 ; was: loc_D7DE
                cmpi.w  #1,d7
                beq.s   Midgame_UpdateRandomLightningEffect_Return
                movea.w #(Entity57Type-M68K_RAM),a0
                move.w  #$160,(a0)
                move.w  #$E100,2(a0)
                move.w  (RandomNumberState).w,d0
                andi.w  #$C,d0
                move.l  Midgame_RandomLightningMappingPointers(pc,d0.w),8(a0)
                clr.w   $C(a0)
                move.w  #$1E8,$E(a0)
                move.b  #$70,$20(a0)                    ; 'p'
                move.w  (RandomNumberState).w,d0
                andi.w  #$800,d0
                or.w    d0,$E(a0)
                move.w  (RandomNumberState).w,d0
                andi.w  #$FF,d0
                addi.w  #$A0,d0
                move.w  d0,$10(a0)
                move.w  #$F8,d0
                add.w   (PrimaryCameraYPosition).w,d0
                move.w  d0,$14(a0)
Midgame_UpdateRandomLightningEffect_Return:             ; was: locret_D838
                                        ; Midgame_UpdateRandomLightningEffect+C   j
                rts
; End of function Midgame_UpdateRandomLightningEffect
; ---------------------------------------------------------------------------
Midgame_RandomLightningMappingPointers: dc.l    Midgame_LightningSpriteAnimation00  ; was: off_D83A
                dc.l    Midgame_LightningSpriteAnimation01
                dc.l    Midgame_LightningSpriteAnimation02
                dc.l    Midgame_LightningSpriteAnimation03
Stage8_TrainLightningPaletteEntryLists:
                dc.w    0, $E308, 9, $E326, $E328, $E32A, $E32C, $E32E  ; was: word_D84A
                dc.w    $E330, $E332, $E334, $E336, $E324
Stage8_FlyingNeoLightningPaletteEntryLists:
                dc.w    1, $E308, $E36E, $22, $E324, $E326, $E328, $E32A  ; was: word_D864
                                        ; sub_D01E:loc_D040   o
                dc.w    $E32C, $E32E, $E330, $E332, $E344, $E346, $E348, $E34A
                dc.w    $E34C, $E34E, $E350, $E352, $E354, $E356, $E358, $E35A
                dc.w    $E35C, $E35E, $E362, $E364, $E366, $E368, $E36A, $E370
                dc.w    $E372, $E374, $E376, $E378, $E37A, $E37C, $E37E
Stage9_FlyCorridorLightningPaletteEntryLists:
                dc.w    7, $E308, $E30A, $E30C, $E30E, $E310, $E312, $E314  ; was: word_D8B2
                                        ; UnreferencedStage9_UpdateCaterpillarScroll   o
                dc.w    $E316, $23, $E324, $E326, $E328, $E32A, $E32C, $E32E
                dc.w    $E330, $E332, $E344, $E346, $E348, $E34A, $E34C, $E34E
                dc.w    $E350, $E352, $E354, $E356, $E358, $E35A, $E35C, $E35E
                dc.w    $E362, $E364, $E366, $E368, $E36A, $E36E, $E370, $E372
                dc.w    $E374, $E376, $E378, $E37A, $E37C, $E37E
