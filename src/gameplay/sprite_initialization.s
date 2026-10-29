; Initializes a newly allocated effect object with randomized position and velocity
Effect_InitRandomizedObject:
                bra.w   *+4                             ; was: sub_1B906
; ---------------------------------------------------------------------------
Effect_InitRandomizedObject_Initialize:                 ; CODE XREF: Effect_InitRandomizedObject   j  ; was: loc_1B90A
                bne.w   Effect_InitRandomizedObject_Return
                move.l  d7,$48(a0)
                move.b  (RandomNumberState+1).w,d0
                andi.w  #$1F,d0
                subi.w  #$10,d0
                add.w   $10(a5),d0
                move.w  d0,$10(a0)
                move.b  (RandomNumberState).w,d0
                andi.w  #$1F,d0
                subi.w  #$10,d0
                add.w   $14(a5),d0
                move.w  d0,$14(a0)
                move.w  #1,$18(a0)
                move.l  #$FFFFE000,$58(a0)
                move.b  (RandomNumberState+2).w,d0
                andi.w  #$C,d0
                move.l  Effect_RandomVerticalVelocityTable(pc,d0.w),$1C(a0)
                move.l  #$800,$5C(a0)
                cmpi.w  #8,d0
                bmi.w   Effect_InitRandomizedObject_Return
                move.l  #$FFFFF800,$5C(a0)
Effect_InitRandomizedObject_Return:                     ; CODE XREF: Effect_InitRandomizedObject:Effect_InitRandomizedObject_Initialize   j  ; was: locret_1B96E
                                        ; Effect_InitRandomizedObject+5C   j
                rts
; End of function Effect_InitRandomizedObject
; ---------------------------------------------------------------------------
Effect_RandomVerticalVelocityTable: dc.l    $FFFE8000, $FFFF8000, $8000, $18000  ; was: dword_1B970
                                        ; DATA XREF: Effect_InitRandomizedObject+4A   r

; Clears specific flags from object buffer
Sprite_ClearObjectFlags:                                ; CODE XREF: Boss_JetsripperDeathInit+A   p  ; was: sub_1B980
                                        ; Boss_SniperHoneyviperBeginDefeat+6   p
                movea.w #(Entity_ObjectPool-M68K_RAM),a0
                moveq   #$3C,d7                         ; '<'
                move.b  #$92,d0
Sprite_ClearObjectFlags_Loop:                           ; CODE XREF: Sprite_ClearObjectFlags+1A   j  ; was: loc_1B98A
                move.b  $21(a0),d1
                and.b   d0,d1
                beq.s   Sprite_ClearObjectFlags_Next
                clr.b   $21(a0)
Sprite_ClearObjectFlags_Next:                           ; CODE XREF: Sprite_ClearObjectFlags+10   j  ; was: loc_1B996
                lea     $60(a0),a0
                dbf     d7,Sprite_ClearObjectFlags_Loop
                rts
; End of function Sprite_ClearObjectFlags
; Initializes a group of objects from a terminated descriptor table
Object_InitGroupFromTable:                              ; CODE XREF: Object_InitGroupFromTable+42   j  ; was: sub_1B9A0
                                        ; Boss_SniperHoneyviperInitializeEncounterEntities+136   p
                move.w  (a1)+,d0
                cmpi.w  #$FFFE,d0
                bne.s   Object_InitGroupFromTable_InitializeEntry
                rts
; ---------------------------------------------------------------------------
Object_InitGroupFromTable_InitializeEntry:              ; CODE XREF: Object_InitGroupFromTable+6   j  ; was: loc_1B9AA
                movea.w d0,a0
                move.b  (a1)+,$21(a0)
                clr.b   $23(a0)
                move.b  (a1)+,d0
                bclr    #0,d0
                beq.s   Object_InitGroupFromTable_StoreEntry
                move.b  #$10,$23(a0)
; Stores the decoded descriptor fields for the current object
Object_InitGroupFromTable_StoreEntry:                   ; CODE XREF: Object_InitGroupFromTable+1A   j  ; was: loc_1B9C2
                lsr.b   #1,d0
                move.b  d0,$25(a0)
                clr.b   $24(a0)
                move.l  (a1)+,$28(a0)
                move.l  (a1)+,$2C(a0)
                moveq   #0,d0
                move.b  (a1)+,d0
                asl.w   #1,d0
                move.w  d0,$26(a0)
                move.b  (a1)+,$23(a0)
                bra.s   Object_InitGroupFromTable
; End of function Object_InitGroupFromTable
; ---------------------------------------------------------------------------
Boss_AntroidObjectInitTable:    dc.w    $C620, $1050, $F010, $F010, 0, 0, $80  ; was: word_1B9E4
                                        ; DATA XREF: Boss_AntroidInitializeBattleState+60   o
                dc.w    $C680, $5028, $F010, $F010, $F808, $F808, $2A00
                dc.w    $C6E0, $103C, $F808, $F808, 0, 0, 4
                dc.w    $C9E0, $5008, $F808, $F808, $FC04, $FC04, $2A04
                dc.w    $CA40, $5008, $F808, $F808, $FC04, $FC04, $2A04
                dc.w    $CDA0, $5008, $F808, $F808, $FC04, $FC04, $2A04
                dc.w    $CE60, $5008, $F808, $F808, $FC04, $FC04, $2A04
                dc.w    $FFFE
Boss_ShellshogunObjectInitTable:    dc.w    $C620, $5014, $E61A, $E61A, $E818, $E818, $5B0D  ; was: word_1BA48
                                        ; DATA XREF: Boss_ShellshogunSetupPhase+128   o
                dc.w    $C680, $1038, $F00C, $F40C, 0, 0, $80
                dc.w    $C920, $5020, $F808, $F808, $F808, $F808, $5005
                dc.w    $C9E0, $1020, $F808, $F808, 0, 0, 5
                dc.w    $CD40, $5020, $F808, $F808, $F808, $F808, $5005
                dc.w    $CE00, $1020, $F808, $F808, 0, 0, 5
                dc.w    $FFFE
Boss_SniperHoneyviperObjectInitTable:   dc.w    $C620, $5008, $C808, $E214, $C808, $E214, $3C00  ; was: word_1BA9E
                                        ; DATA XREF: Boss_SniperHoneyviperInitializeEncounterEntities+130   o
                dc.w    $C680, $5008, $C000, $D81C, $C000, $D81C, $3C00
                dc.w    $CB60, $5020, $F40C, $F40C, $FA06, $FA06, $7F05
                dc.w    $CAA0, $5020, $F40C, $F40C, $F808, $F808, $7F05
                dc.w    $C9E0, $1020, $F40C, $F40C, $F60A, $F60A, $7F05
                dc.w    $CBC0, $1030, $F010, $F808, 0, 0, $80
                dc.w    $FFFE
Boss_MadamBarbarObjectInitTable:    dc.w    $C620, $5024, $E820, $E020, $EC18, $EC18, $A080  ; was: word_1BAF4
                                        ; DATA XREF: Boss_MadamBarbarSetupState+AA   o
                dc.w    $C6E0, $1010, $F20E, $F20E, 0, 0, 5
                dc.w    $C7A0, $5010, $F20E, $F20E, $F40C, $F40C, $4305
                dc.w    $C920, $1010, $F20E, $F20E, 0, 0, 5
                dc.w    $C9E0, $5010, $F20E, $F20E, $F40C, $F40C, $4305
                dc.w    $FFFE
Boss_JokerObjectInitTable:  dc.w    $C620, $5038, $E830, $E020, $E830, $E020, $6E80  ; was: word_1BB3C
                                        ; DATA XREF: Boss_JokerSetup+70   o
                dc.w    $FFFE
Boss_TerobusterObjectInitTable: dc.w    $C620, $5040, $D40C, $B80C, $D40C, $B80C, $3C88  ; was: word_1BB4C
                                        ; DATA XREF: Boss_TerobusterSetup+A4   o
                dc.w    $C6E0, $5008, $F010, $F010, $F808, $F808, $3C00
                dc.w    $C7A0, $5008, $F010, $F010, $F808, $F808, $3C00
                dc.w    $C8C0, $5008, $F010, $F010, $F808, $F808, $3C00
                dc.w    $C980, $5008, $F010, $F010, $F808, $F808, $3C00
                dc.w    $FFFE
Boss_FlyingNeoObjectInitTable:  dc.w    $C620, $5038, 0, 0, 0, 0, $4204  ; was: word_1BB94
                                        ; DATA XREF: Boss_FlyingNeoSetup+C4   o
                dc.w    $C9E0, $5050, $F808, $F20E, $F808, $F20E, $4280
                dc.w    $C800, $5008, $F812, $F808, $F812, $F808, $4204
                dc.w    $C980, $5008, $F812, $F808, $F812, $F808, $4204
                dc.w    $FFFE
Boss_XiTigerObjectInitTable:    dc.w    $C620, $5030, $E826, $E020, $E826, $E020, $6C80  ; was: word_1BBCE
                                        ; DATA XREF: Boss_XiTigerSetup+5C   o
                dc.w    $C6E0, $1018, $F010, $F010, 0, 0, 5
                dc.w    $C7A0, $1018, $F010, $F010, 0, 0, 5
                dc.w    $C860, $5000, $EE12, $EE12, $F010, $F010, $B810
                dc.w    $C8C0, $1018, $F010, $F010, 0, 0, 5
                dc.w    $C980, $1018, $F010, $F010, 0, 0, 5
                dc.w    $CA40, $5000, $EE12, $EE12, $F010, $F010, $B810
                dc.w    $CB60, $5018, $F010, $F010, $F40C, $F40C, $6C04
                dc.w    $CC20, $1018, $F40C, $F40C, 0, 0, 4
                dc.w    $CDA0, $5018, $F010, $F010, $F40C, $F40C, $6C04
                dc.w    $CE60, $1018, $F40C, $F40C, 0, 0, 4
                dc.w    $FFFE
Boss_DeepStriderObjectInitTable:    dc.w    $C740, $103C, $F010, $F010, $FD0C, $F40C, 0  ; was: word_1BC6A
                                        ; DATA XREF: Boss_DeepStriderIntroRise+36   o
                dc.w    $C680, $103C, $F010, $F010, 0, 0, $80
                dc.w    $C7A0, $103C, $F40C, $F40C, 0, 0, 0
                dc.w    $C860, $1008, $F808, $F808, 0, 0, 0
                dc.w    $C8C0, $1008, $FC04, $FC04, 0, 0, 0
                dc.w    $FFFE
Boss_SharpsteelObjectInitTable: dc.w    $C620, $1014, $F010, $F010, $F010, $F010, $4700  ; was: word_1BCB2
                                        ; DATA XREF: Boss_SharpsteelInitializeState+4A   o
                dc.w    $C680, $1014, $E41C, $E41C, $F010, $F010, $4700
                dc.w    $C6E0, $1028, $EC14, $EC14, $F010, $F010, $4780
                dc.w    $C740, $1014, $F010, $F010, $F010, $F010, $4700
                dc.w    $C7A0, $1014, $F010, $F010, $F010, $F010, 0
                dc.w    $C800, $1014, $F010, $F010, $F010, $F010, 0
                dc.w    $C920, 0, $F010, $F010, $F808, $F808, 0
                dc.w    $C980, 0, $F010, $F010, $F010, $F010, 0
                dc.w    $CAA0, 0, $F010, $F010, $FA06, $FA06, 0
                dc.w    $CB00, 0, $F010, $F010, $FA06, $FA06, 0
                dc.w    $CB60, 0, $F010, $F010, $F20E, $F20E, 0
                dc.w    $CBC0, 0, $F010, $F010, $F20E, $F20E, 0
                dc.w    $CC20, 0, $F010, $F010, $F20E, $F20E, 0
                dc.w    $CC80, 0, $F010, $F010, $F20E, $F20E, 0
                dc.w    $FFFE
EntityType1C0_ObjectInitTable:  dc.w    $C620, $502C, $E41C, $E41C, $E41C, $E41C, $3280  ; was: word_1BD78
                                        ; DATA XREF: EntityType1C0_LoadGraphics+C   o
                dc.w    $C860, $1004, $F010, $F010, $F808, $F808, $3200
                dc.w    $CA40, $1004, $F010, $F010, $F808, $F808, $3200
                dc.w    $CC20, $1004, $F010, $F010, $F808, $F808, $3200
                dc.w    $D400, $1004, $F010, $F010, $F808, $F808, $3200
                dc.w    $FFFE
Boss_BackStringerObjectInitTable:   dc.w    $C6E0, $1020, $F010, $F010, $F808, $F808, $2204  ; was: word_1BDC0
                                        ; DATA XREF: Boss_BackStringerInitializeState+68   o
                dc.w    $C740, $1020, $F010, $F010, $F808, $F808, $2204
                dc.w    $C7A0, $1038, $EC14, $EC14, $F808, $F808, $2280
                dc.w    $FFFE
Boss_WolfGaropaObjectInitTable: dc.w    $C620, $5004, $E004, $E040, $E0F8, $E030, $4309  ; was: word_1BDEC
                                        ; DATA XREF: Boss_WolfGaropaInitialize+106   o
                dc.w    $C8C0, 4, $F010, $F010, $FC04, $FC04, 9
                dc.w    $CC80, 4, $F010, $F010, $FC04, $FC04, 9
                dc.w    $C800, 4, $F010, $F010, 0, 0, 9
                dc.w    $CBC0, 4, $F010, $F010, 0, 0, 9
                dc.w    $D0A0, $1008, $F010, $F010, 0, 0, 9
                dc.w    $D100, $5028, $F20E, $E818, $FC04, $F80E, $4309
                dc.w    $CF80, 8, $F010, $FF24, $F010, $FC04, $2A04
                dc.w    $CFE0, $1038, $FC2C, $F010, 0, 0, $84
                dc.w    $FFFE
Debug_ValkirieViewerObjectInitTable:    dc.w    $C620, $501C, $D010, $F010, $D808, $F808, $6909  ; was: word_1BE6C
                                        ; DATA XREF: Debug_ValkirieViewerInitialize+F6   o
                dc.w    $CB60, $5004, $F010, $F010, $FC04, $FC04, $7D09
                dc.w    $CCE0, $5004, $F010, $F010, $FC04, $FC04, $7D09
                dc.w    $CC20, $5004, $E41C, $F010, $F808, $FE02, $7D09
                dc.w    $CDA0, $5004, $E41C, $F010, $F808, $FE02, $7D09
                dc.w    $FFFE
Boss_ZLeoObjectInitTable:   dc.w    $C620, $1018, $CC02, $EC14, 0, 0, $8F  ; was: word_1BEB4
                                        ; DATA XREF: Boss_ZLeoIntroInit+192   o
                dc.w    $FFFE
Boss_ValkirieIntroObjectInitTable:  dc.w    $C620, $5038, $F010, $F010, $EC14, $EC14, $6488  ; was: word_1BEC4
                                        ; DATA XREF: Entity_InitValkirieBattleState0+46   o
                dc.w    $C6E0, $500C, $F010, $F010, $F010, $F010, $6408
                dc.w    $C7A0, $5000, $F60A, $F60A, $F010, $F010, $6410
                dc.w    $C980, $5000, $F60A, $F60A, $F010, $F010, $6410
Boss_ValkirieEffectObjectInitTable: dc.w    $CBC0, $5004, $F010, $F010, $FA06, $FA06, $640C  ; was: word_1BEFC
                                        ; DATA XREF: Entity_SpawnValkirieTransitionEffect   o
                dc.w    $CE00, $5004, $F010, $F010, $FA06, $FA06, $640C
                dc.w    $FFFE
Boss_MedusaObjectInitTable: dc.w    $C620, $5018, $E020, $E020, $E818, $E41C, $8088  ; was: word_1BF1A
                                        ; DATA XREF: Boss_UpdateMedusaState4+4A   o
                dc.w    $FFFE
Boss_SireneObjectInitTable: dc.w    $C620, $5040, $EC14, $EC14, $EC14, $EC14, $3888  ; was: word_1BF2A
                                        ; DATA XREF: Boss_UpdateSireneState10   o
                dc.w    $C920, $5000, $F010, $F010, $F010, $F010, $3810
                dc.w    $CCE0, $5000, $F010, $F010, $F010, $F010, $3810
                dc.w    $FFFE
Boss_ArtemisAttackObjectInitData:   dc.b    $D1, 0, $10, $40, $F8, 8, $F8  ; was: byte_1BF56
                                        ; DATA XREF: Boss_UpdateArtemisState4+BA   o
                dc.b    8, 0, 0, 0, 0, 0, $88
Boss_ArtemisAttackPartGroupInitTable:   dc.w    $C680, $5004, $F010, $F010, $EC14, $EC14, $2908  ; was: word_1BF64
                                        ; DATA XREF: Boss_InitArtemisAttackPartGroup   o
                dc.w    $C6E0, $5004, $F010, $F010, $EC14, $EC14, $2908
                dc.w    $C7A0, $501C, $F808, $F808, $FA06, $FA06, $2905
                dc.w    $FFFE
Boss_UnidentifiedSevenForceObjectInitTable: dc.w    $C620, $5044, $EC14, $EC14, $EC14, $EC14, $5B08  ; was: word_1BF90
                                        ; DATA XREF: Boss_UnidentifiedSevenForceInit+46   o
                dc.w    $FFFE
Boss_ValkirieAlternateObjectInitTable:  dc.w    $C620, $5044, $EC14, $EC14, $EC14, $EC14, $5B08  ; was: word_1BFA0
                                        ; DATA XREF: Boss_ValkirieAlternateInit+46   o
                dc.w    $FFFE
Boss_SylpheedObjectInitTable:   dc.w    $C620, $5040, $EC14, $EC14, $EC14, $EC14, $5B88  ; was: word_1BFB0
                                        ; DATA XREF: Boss_SylpheedAnimationScript+68   o
                dc.w    $CB60, $5000, $EC14, $EC14, $FC04, $FC04, $3710
                dc.w    $CC20, $5000, $EC14, $EC14, $FC04, $FC04, $3710
                dc.w    $CCE0, $5000, $E41C, $E41C, $FC04, $FC04, $3710
                dc.w    $CE60, $5000, $EC14, $EC14, $FC04, $FC04, $3710
                dc.w    $CF20, $5000, $EC14, $EC14, $FC04, $FC04, $3710
                dc.w    $CFE0, $5000, $E41C, $E41C, $FC04, $FC04, $3710
                dc.w    $FFFE

; Scans sixteen contiguous enemy records for the first free one
Sprite_FindFreeEnemySlot:                               ; CODE XREF: TerrainTileAnimation_WaitForActivation+14   p  ; was: sub_1C014
                movea.w #(SecondaryEntityType-M68K_RAM),a0
                moveq   #$F,d7
Sprite_FindFreeEnemySlot_Loop:                          ; CODE XREF: Sprite_FindFreeEnemySlot+E   j  ; was: loc_1C01A
                move.w  (a0),d0
                beq.s   Sprite_FindFreeEnemySlot_Return
                lea     $60(a0),a0
                dbf     d7,Sprite_FindFreeEnemySlot_Loop
Sprite_FindFreeEnemySlot_Return:                        ; CODE XREF: Sprite_FindFreeEnemySlot+8   j  ; was: locret_1C026
                rts
; End of function Sprite_FindFreeEnemySlot
; Scans four contiguous records from the shared entity slot for the first free one
Sprite_FindFreeEffectSlot:                              ; CODE XREF: Hazard_UpdateTopFallingSpawnerType104+2E   p  ; was: sub_1C028
                movea.w #(Entity57Type-M68K_RAM),a0
                moveq   #3,d7
Sprite_FindFreeEffectSlot_Loop:                         ; CODE XREF: Sprite_FindFreeEffectSlot+E   j  ; was: loc_1C02E
                move.w  (a0),d0
                beq.s   Sprite_FindFreeEffectSlot_Return
                lea     $60(a0),a0
                dbf     d7,Sprite_FindFreeEffectSlot_Loop
Sprite_FindFreeEffectSlot_Return:                       ; CODE XREF: Sprite_FindFreeEffectSlot+8   j  ; was: locret_1C03A
                rts
; End of function Sprite_FindFreeEffectSlot
; Finds a free slot among player-effect records one through seven
PlayerEffect_FindFreeSlot:                              ; CODE XREF: Effect_SpawnParticle+16   p  ; was: sub_1C03C
                                        ; sub_175B8:Player_SpawnPhoenixParticles_Allocate   p
                movea.w #(PlayerEffectAllocStart-M68K_RAM),a0
                moveq   #6,d7
; End of function PlayerEffect_FindFreeSlot
; Finds free slot in object array
Sys_FindFreeObjectSlot:                                 ; CODE XREF: Effect_FindDashTrailSlot+6   j  ; was: sub_1C042
                                        ; Effect_InitPlayerMotionProjectile+36   p
                move.w  (a0),d0
                beq.s   Sys_FindFreeObjectSlot_Return
                lea     $60(a0),a0
                dbf     d7,Sys_FindFreeObjectSlot
Sys_FindFreeObjectSlot_Return:                          ; CODE XREF: Sys_FindFreeObjectSlot+2   j  ; was: locret_1C04E
                rts
; End of function Sys_FindFreeObjectSlot
