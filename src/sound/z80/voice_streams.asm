; Byte-preserving Z80 instructions; neutral path labels imply no unproved semantics.
; The reset/PCM and negative-request paths retain their original contiguous order.
Dac_VoiceRequest:
    xor a
    ld (Z80DACCommandByte4),a
    ld a,(Z80DACCommandByte5)
    ld (Z80DACStatus),a
    ld hl,Dac_YMAddressB
    ld (hl),182
    inc l
    ld (hl),192
    ld ix,(Dac_Reset)
    ld ix,(Dac_Reset)
    ld hl,Dac_YMAddressA
    ld (hl),40
    inc l
    ld (hl),6
    dec l
    ld ix,(Dac_Reset)
    ld ix,(Dac_Reset)
    ld (hl),43
    inc l
    ld (hl),128
    dec l
    ld hl,Dac_FixedWord001
    ld (Dac_FixedWord018),hl
    ld (Dac_FixedWord008),hl
    ld hl,Dac_SampleBuffer
    ld (Dac_FixedWord021),hl
    ld (Dac_FixedWord014),hl
    ld a,128
    ld (Dac_FixedWord017),a
    ld (Dac_FixedWord020),a
    xor a
    ld (Dac_FixedWord016),a
    ld (Dac_FixedWord019),a
    ld (Dac_FixedWord007),a
    ld (Dac_FixedWord013),a
    ld (Z80DriverBusy),a
    ld hl,Z80DriverBusy
    ld de,Dac_YMAddressA
    ld bc,Dac_YMDataA
    exx
    jp Dac_Path025
Dac_Path023:
    pop hl
    ld a,l
    ex af,af'
    ld c,128
    add ix,bc
    add iy,bc
    nop
    nop
    ld a,0
    ld de,(Dac_Reset)
    ld de,(Dac_Reset)
    jp Dac_Path026
Dac_Path024:
    pop hl
    ld c,128
    add ix,bc
    add iy,bc
    nop
    ld de,0
    ld de,(Dac_Reset)
    ld de,(Dac_Reset)
    ld de,(Dac_Reset)
    ld de,(Dac_Reset)
    jp Dac_Path028
Dac_Path025:
    ld b,0
    ld ix,Dac_VoiceLookupPages
    ld iy,Dac_VoiceLookupPages
    ld sp,Dac_FixedWord016
    pop af
    jr nc,Dac_Path023
    pop hl
    ld d,l
    inc d
    ld l,(hl)
    ld h,Dac_HighNibbleDeltas/256
    add a,(hl)
    ld c,a
    add ix,bc
    dec h
    add a,(hl)
    ld c,a
    add iy,bc
    ld e,a
    ld (Dac_FixedWord017),de
    ld a,d
    ex af,af'
Dac_Path026:
    pop af
    jr nc,Dac_Path024
    pop hl
    ld d,l
    inc d
    ld l,(hl)
    dec h
    add a,(hl)
    ld c,a
    add ix,bc
    dec h
    add a,(hl)
    ld c,a
    add iy,bc
    ld e,a
    ld (Dac_FixedWord020),de
    ld a,(Dac_FixedWord014)
    sub d
    jr z,Dac_Path027
    nop
    nop
    jp Dac_Path028
Dac_Path027:
    ld (Dac_FixedWord019),a
Dac_Path028:
    exx
    ld (hl),d
    ld a,(ix+0)
    ex de,hl
    ld (hl),e
    ex de,hl
    ld (bc),a
    ld (hl),e
    exx
    ld sp,Dac_FixedWord007
    pop af
    jp nc,Dac_Path039
    pop de
    ex af,af'
    sub e
    jp nz,Dac_Path030
Dac_Path029:
    ld a,(Z80VBlankActive)
    or a
    jp nz,Dac_Path029
    ld a,0
    jp Dac_Path031
Dac_Path030:
    cp 192
    jp c,Dac_Path035
    ld a,(Z80VBlankActive)
    or a
    jp nz,Dac_Path036
Dac_Path031:
    ld hl,Dac_BankRegister
    pop bc
    rlc b
    ld (hl),b
    ld a,c
    ld (hl),a
    rrca
    ld (hl),a
    rrca
    ld (hl),a
    rrca
    ld (hl),a
    rrca
    ld (hl),a
    rrca
    ld (hl),a
    rrca
    ld (hl),a
    rrca
    ld (hl),a
    pop hl
    pop bc
    ldi
    ldi
    ldi
    ldi
    jp pe,Dac_Path032
    ld a,e
    ld (Dac_FixedWord008),a
    xor a
    ld (Dac_FixedWord007),a
    ld a,0
    nop
    jr Dac_Path033
Dac_Path032:
    ld a,b
    or a
    jp m,Dac_Path034
    push bc
    push hl
    ld a,e
    ld (Dac_FixedWord008),a
Dac_Path033:
    exx
    ld (hl),d
    ld a,(iy+0)
    ex de,hl
    ld (hl),e
    ex de,hl
    ld (bc),a
    ld (hl),e
    exx
    ld a,(Z80DACCommandByte4)
    or a
    jp z,Dac_Path047
    ex af,af'
    xor a
    ld (Z80VoiceSlotAActive),a
    ld (Z80VoiceSlotBActive),a
    ld (Z80VoiceSlotAFlags),a
    ld (Z80VoiceSlotBFlags),a
    ex af,af'
    jp Dac_Path002
Dac_Path034:
    ld a,e
    add a,c
    ld (Dac_FixedWord008),a
    xor a
    ld (Dac_FixedWord007),a
    exx
    ld (hl),d
    ld a,(iy+0)
    ex de,hl
    ld (hl),e
    ex de,hl
    ld (bc),a
    ld (hl),e
    exx
    ld a,(Z80DACCommandByte4)
    or a
    jp z,Dac_Path047
    ex af,af'
    xor a
    ld (Z80VoiceSlotAActive),a
    ld (Z80VoiceSlotBActive),a
    ld (Z80VoiceSlotAFlags),a
    ld (Z80VoiceSlotBFlags),a
    ex af,af'
    jp Dac_Path002
Dac_Path035:
    ld a,1
    ld (Dac_FixedWord016),a
    ld a,0
Dac_Path036:
    ld a,(Z80VoiceSlotAActive)
    or a
    jp m,Dac_Path037
    nop
    ld a,0
    ld bc,0
    jr Dac_Path038
Dac_Path037:
    ld a,64
    ld (Z80VoiceSlotAActive),a
    ld (Dac_FixedWord007),a
Dac_Path038:
    nop
    ld bc,(Dac_Reset)
    ld bc,(Dac_Reset)
    ld bc,(Dac_Reset)
    ld bc,(Dac_Reset)
    ld bc,(Dac_Reset)
    ld bc,(Dac_Reset)
    ld bc,(Dac_Reset)
    ld bc,(Dac_Reset)
    ld bc,(Dac_Reset)
    ld bc,(Dac_Reset)
    jp Dac_Path033
Dac_Path039:
    jp z,Dac_Path044
    nop
    nop
    nop
    ld bc,0
    ld bc,(Dac_Reset)
    ld bc,(Dac_Reset)
    ld a,(Z80VoiceSlotAActive)
    or a
    jp m,Dac_Path037
    jp nz,Dac_Path040
    nop
    ld a,0
    ld bc,0
    ld bc,(Dac_Reset)
    ld bc,(Dac_Reset)
    jp Dac_Path042
Dac_Path040:
    pop de
    ex af,af'
    cp e
    jp z,Dac_Path041
    ld a,0
    ld bc,(Dac_Reset)
    ld bc,(Dac_Reset)
    jp Dac_Path043
Dac_Path041:
    xor a
    ld (Dac_FixedWord016),a
    ld (Z80VoiceSlotAActive),a
    ld (Z80VoiceSlotAFlags),a
Dac_Path042:
    ld a,(Z80VoiceSlotBActive)
    or a
    jp z,Dac_Path067
Dac_Path043:
    nop
    nop
    nop
    ld a,0
    ld bc,0
    ld bc,(Dac_Reset)
    ld bc,(Dac_Reset)
    ld bc,(Dac_Reset)
    ld bc,(Dac_Reset)
    ld bc,(Dac_Reset)
    jp Dac_Path033
Dac_Path044:
    xor a
    ld (Dac_FixedWord016),a
    ld (Dac_FixedWord018),a
    ld (Dac_FixedWord008),a
    ld a,128
    ld (Dac_FixedWord017),a
    ld a,1
    ld (Dac_FixedWord007),a
    ld (Z80DriverBusy),a
    ld a,(Z80DACCommandByte5)
    ld (Z80DACStatus),a
    ld sp,Z80VoiceSlotADesc0
    pop hl
    pop de
    pop bc
    ld sp,Dac_FixedWord009
    push bc
    push de
    push hl
    xor a
    ld (Z80DriverBusy),a
    nop
    ld bc,(Dac_Reset)
    ld bc,(Dac_Reset)
    ld bc,(Dac_Reset)
    ld bc,(Dac_Reset)
    ld bc,(Dac_Reset)
    jp Dac_Path033
Dac_Path045:
    pop hl
    ld c,128
    add ix,bc
    add iy,bc
    ld a,0
    ld de,0
    ld de,(Dac_Reset)
    ld de,(Dac_Reset)
    ld de,(Dac_Reset)
    ld de,(Dac_Reset)
    jp Dac_Path049
Dac_Path046:
    pop hl
    ld a,l
    ex af,af'
    ld c,128
    add ix,bc
    add iy,bc
    nop
    nop
    nop
    ld de,(Dac_Reset)
    ld de,(Dac_Reset)
    jp Dac_Path050
Dac_Path047:
    ld b,0
    ld ix,Dac_VoiceLookupPages
    ld iy,Dac_VoiceLookupPages
    ld sp,Dac_FixedWord016
    pop af
    jr nc,Dac_Path045
    pop hl
    ld d,l
    inc d
    ld l,(hl)
    ld h,Dac_HighNibbleDeltas/256
    add a,(hl)
    ld c,a
    add ix,bc
    dec h
    add a,(hl)
    ld c,a
    add iy,bc
    ld e,a
    ld (Dac_FixedWord017),de
    ld a,(Dac_FixedWord008)
    sub d
    jr z,Dac_Path048
    nop
    nop
    jp Dac_Path049
Dac_Path048:
    ld (Dac_FixedWord016),a
Dac_Path049:
    pop af
    jr nc,Dac_Path046
    pop hl
    ld d,l
    inc d
    ld l,(hl)
    dec h
    add a,(hl)
    ld c,a
    add ix,bc
    dec h
    add a,(hl)
    ld c,a
    add iy,bc
    ld e,a
    ld (Dac_FixedWord020),de
    ld a,d
    ex af,af'
Dac_Path050:
    exx
    ld (hl),d
    ld a,(ix+0)
    ex de,hl
    ld (hl),e
    ex de,hl
    ld (bc),a
    ld (hl),e
    exx
    ld sp,Dac_FixedWord013
    pop af
    jp nc,Dac_Path061
    pop de
    ex af,af'
    sub e
    jp nz,Dac_Path052
Dac_Path051:
    ld a,(Z80VBlankActive)
    or a
    jp nz,Dac_Path051
    ld a,0
    jp Dac_Path053
Dac_Path052:
    cp 192
    jp c,Dac_Path057
    ld a,(Z80VBlankActive)
    or a
    jp nz,Dac_Path058
Dac_Path053:
    ld hl,Dac_BankRegister
    pop bc
    rlc b
    ld (hl),b
    ld a,c
    ld (hl),a
    rrca
    ld (hl),a
    rrca
    ld (hl),a
    rrca
    ld (hl),a
    rrca
    ld (hl),a
    rrca
    ld (hl),a
    rrca
    ld (hl),a
    rrca
    ld (hl),a
    pop hl
    pop bc
    ldi
    ldi
    ldi
    ldi
    jp pe,Dac_Path054
    ld a,e
    ld (Dac_FixedWord014),a
    xor a
    ld (Dac_FixedWord013),a
    ld a,0
    nop
    jr Dac_Path055
Dac_Path054:
    ld a,b
    or a
    jp m,Dac_Path056
    push bc
    push hl
    ld a,e
    ld (Dac_FixedWord014),a
Dac_Path055:
    exx
    ld (hl),d
    ld a,(iy+0)
    ex de,hl
    ld (hl),e
    ex de,hl
    ld (bc),a
    ld (hl),e
    exx
    ld a,(Z80DACCommandByte4)
    or a
    jp z,Dac_Path025
    ex af,af'
    xor a
    ld (Z80VoiceSlotAActive),a
    ld (Z80VoiceSlotBActive),a
    ld (Z80VoiceSlotAFlags),a
    ld (Z80VoiceSlotBFlags),a
    ex af,af'
    jp Dac_Path002
Dac_Path056:
    ld a,e
    add a,c
    ld (Dac_FixedWord014),a
    xor a
    ld (Dac_FixedWord013),a
    exx
    ld (hl),d
    ld a,(iy+0)
    ex de,hl
    ld (hl),e
    ex de,hl
    ld (bc),a
    ld (hl),e
    exx
    ld a,(Z80DACCommandByte4)
    or a
    jp z,Dac_Path025
    ex af,af'
    xor a
    ld (Z80VoiceSlotAActive),a
    ld (Z80VoiceSlotBActive),a
    ld (Z80VoiceSlotAFlags),a
    ld (Z80VoiceSlotBFlags),a
    ex af,af'
    jp Dac_Path002
Dac_Path057:
    ld a,1
    ld (Dac_FixedWord019),a
    ld a,0
Dac_Path058:
    ld a,(Z80VoiceSlotBActive)
    or a
    jp m,Dac_Path059
    nop
    ld a,0
    ld bc,0
    jr Dac_Path060
Dac_Path059:
    ld a,64
    ld (Z80VoiceSlotBActive),a
    ld (Dac_FixedWord013),a
Dac_Path060:
    nop
    ld bc,(Dac_Reset)
    ld bc,(Dac_Reset)
    ld bc,(Dac_Reset)
    ld bc,(Dac_Reset)
    ld bc,(Dac_Reset)
    ld bc,(Dac_Reset)
    ld bc,(Dac_Reset)
    ld bc,(Dac_Reset)
    ld bc,(Dac_Reset)
    ld bc,(Dac_Reset)
    jp Dac_Path055
Dac_Path061:
    jp z,Dac_Path066
    nop
    nop
    nop
    ld bc,0
    ld bc,(Dac_Reset)
    ld bc,(Dac_Reset)
    ld a,(Z80VoiceSlotBActive)
    or a
    jp m,Dac_Path059
    jp nz,Dac_Path062
    nop
    ld a,0
    ld bc,0
    ld bc,(Dac_Reset)
    ld bc,(Dac_Reset)
    jp Dac_Path064
Dac_Path062:
    pop de
    ex af,af'
    cp e
    jp z,Dac_Path063
    ld a,0
    ld bc,(Dac_Reset)
    ld bc,(Dac_Reset)
    jp Dac_Path065
Dac_Path063:
    xor a
    ld (Dac_FixedWord019),a
    ld (Z80VoiceSlotBActive),a
    ld (Z80VoiceSlotBFlags),a
Dac_Path064:
    ld a,(Z80VoiceSlotAActive)
    or a
    jp z,Dac_Path067
Dac_Path065:
    nop
    nop
    nop
    ld a,0
    ld bc,0
    ld bc,(Dac_Reset)
    ld bc,(Dac_Reset)
    ld bc,(Dac_Reset)
    ld bc,(Dac_Reset)
    ld bc,(Dac_Reset)
    jp Dac_Path055
Dac_Path066:
    xor a
    ld (Dac_FixedWord019),a
    ld (Dac_FixedWord021),a
    ld (Dac_FixedWord014),a
    ld a,128
    ld (Dac_FixedWord020),a
    ld a,1
    ld (Dac_FixedWord013),a
    ld (Z80DriverBusy),a
    ld a,(Z80DACCommandByte5)
    ld (Z80DACStatus),a
    ld sp,Z80VoiceSlotBDesc0
    pop hl
    pop de
    pop bc
    ld sp,Dac_FixedWord015
    push bc
    push de
    push hl
    xor a
    ld (Z80DriverBusy),a
    nop
    ld bc,(Dac_Reset)
    ld bc,(Dac_Reset)
    ld bc,(Dac_Reset)
    ld bc,(Dac_Reset)
    ld bc,(Dac_Reset)
    jp Dac_Path055
Dac_Path067:
    ld a,128
    ld (Z80DriverBusy),a
    ld ix,(Dac_Reset)
    ld ix,(Dac_Reset)
    ld hl,Dac_YMAddressB
    ld (hl),182
    inc hl
    ld a,(Z80DACPanningUpdate)
    ld (hl),a
    ld ix,(Dac_Reset)
    ld ix,(Dac_Reset)
    ld hl,Dac_YMAddressA
    ld (hl),43
    inc hl
    xor a
    ld (hl),a
    ld (Z80DACStatus),a
    ld (Z80DACRequestState),a
    ld (Z80DriverBusy),a
    jp Dac_WaitForRequest
