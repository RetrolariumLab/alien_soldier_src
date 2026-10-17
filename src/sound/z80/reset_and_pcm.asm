; Byte-preserving Z80 instructions; neutral path labels imply no unproved semantics.
; The reset/PCM and negative-request paths retain their original contiguous order.
Dac_Reset:
    di
    di
    di
    ld sp,Dac_StackTop
    ld a,1
    ld (Z80DriverBusy),a
    ld ix,(Dac_Reset)
    ld ix,(Dac_Reset)
    ld hl,Dac_YMAddressB
    ld (hl),182
    inc hl
    ld (hl),0
    ld ix,(Dac_Reset)
    ld ix,(Dac_Reset)
    ld hl,Dac_YMAddressA
    ld (hl),40
    inc hl
    ld (hl),6
    ld ix,(Dac_Reset)
    ld ix,(Dac_Reset)
    dec hl
    ld (hl),43
    inc hl
    xor a
    ld (hl),a
    ld (Z80VBlankActive),a
    ld (Z80DACCommandByte4),a
    ld (Z80DACRequestState),a
    ld (Z80DACStatus),a
    ld (Z80DACCommandByte6),a
    ld (Z80DACPanning),a
    ld (Z80DACPanningUpdate),a
    ld (Z80VoiceSlotAActive),a
    ld (Z80VoiceSlotBActive),a
    ld (Z80VoiceSlotAFlags),a
    ld (Z80VoiceSlotBFlags),a
    ld (Z80DriverBusy),a
Dac_WaitForRequest:
    ld a,(Z80DACCommandByte4)
    or a
    jp z,Dac_WaitForRequest
Dac_Path002:
    ld (Z80DriverBusy),a
    or a
    jp m,Dac_VoiceRequest
    ld (Dac_DelayCount),a
    xor a
    ld (Z80DACCommandByte4),a
    ld iy,(Z80DACCommandByte2)
    ld a,(Z80DACCommandByte5)
    ld (Z80DACStatus),a
    ld a,(Z80DACRequestState)
    or a
    jp m,Dac_Path003
    ld a,(Z80DACPanning)
    jr Dac_Path004
Dac_Path003:
    ld a,(Z80DACCommandByte6)
Dac_Path004:
    ex af,af'
    ld a,(Z80DACCommandByte1)
    rlca
    ld (Dac_BankRegister),a
    ld b,8
    ld a,(Z80DACCommandByte0)
Dac_Path005:
    ld (Dac_BankRegister),a
    rrca
    djnz Dac_Path005
    xor a
    ld (Z80DriverBusy),a
    ld l,(iy+0)
    ld h,(iy+1)
    ld de,Dac_SampleBuffer
    ld bc,128
Dac_Path006:
    ld a,(Z80VBlankActive)
    or a
    jp nz,Dac_Path006
    ldi
    ldi
    ldi
    ldi
    jp pe,Dac_Path006
    ld a,(iy+2)
    ld b,(iy+3)
    sub 128
    jp nc,Dac_Path007
    dec b
Dac_Path007:
    ld c,a
    exx
    ld a,128
    ld (Z80DriverBusy),a
    ld ix,(Dac_Reset)
    ld ix,(Dac_Reset)
    ex af,af'
    ld hl,Dac_YMAddressB
    ld (hl),182
    inc hl
    ld (hl),a
    ld ix,(Dac_Reset)
    ld ix,(Dac_Reset)
    ld hl,Dac_YMAddressA
    ld (hl),40
    inc hl
    ld (hl),6
    ld ix,(Dac_Reset)
    ld ix,(Dac_Reset)
    dec hl
    ld (hl),43
    inc hl
    ld (hl),128
    ld hl,Z80DriverBusy
    ld de,Dac_YMAddressA
    ld a,(Dac_DelayCount)
    ld c,a
    exx
    ld sp,Z80DACCommandByte2
    push hl
    ld hl,Dac_SampleBuffer
    ld (Dac_BufferReadPosition),hl
    ld a,128
    ex af,af'
    xor a
    ld (Z80DriverBusy),a
    jp Dac_Path016
Dac_Path008:
    ld hl,(Dac_BufferReadPosition)
    ld d,h
    ld a,l
    inc a
    ld (Dac_BufferReadPosition),a
    ex af,af'
    ld l,(hl)
    dec h
    exx
    ld (hl),d
    exx
    add a,(hl)
    exx
    ex de,hl
    ld (hl),e
    ex de,hl
    ld (Dac_YMDataA),a
    ld (hl),e
    nop
    ld b,c
Dac_Path009:
    djnz Dac_Path009
    exx
    dec h
    add a,(hl)
    ex af,af'
    cp e
    jr z,Dac_Path011
    jp m,Dac_Path012
    ld a,(iy+0)
    inc iy
Dac_Path010:
    nop
    nop
    inc iy
    inc iy
    inc iy
    jp Dac_Path014
Dac_Path011:
    ld a,(Z80VBlankActive)
    or a
    jr z,Dac_Path013
    jp Dac_Path011
Dac_Path012:
    ld a,(Z80VBlankActive)
    or a
    jr nz,Dac_Path010
Dac_Path013:
    pop hl
    ldi
    ldi
    push hl
Dac_Path014:
    exx
    ld (hl),d
    exx
    ex af,af'
    exx
    ex de,hl
    ld (hl),e
    ex de,hl
    ld (Dac_YMDataA),a
    ld (hl),e
    ld b,c
Dac_Path015:
    djnz Dac_Path015
    exx
    ex af,af'
Dac_Path016:
    ld a,b
    or a
    jp m,Dac_Path017
    or c
    jp z,Dac_Path018
    ld a,(Z80DACCommandByte4)
    or a
    jp z,Dac_Path008
    jp Dac_Path002
Dac_Path017:
    nop
    inc iy
Dac_Path018:
    ld a,0
    nop
    nop
    ld a,e
    add a,c
    ld e,a
Dac_Path019:
    ld hl,(Dac_BufferReadPosition)
    ld d,h
    ld a,l
    inc a
    ld (Dac_BufferReadPosition),a
    ex af,af'
    ld l,(hl)
    dec h
    exx
    ld (hl),d
    exx
    add a,(hl)
    exx
    ex de,hl
    ld (hl),e
    ex de,hl
    ld (Dac_YMDataA),a
    ld (hl),e
    nop
    ld b,c
Dac_Path020:
    djnz Dac_Path020
    exx
    dec h
    add a,(hl)
    ex af,af'
    nop
    nop
    inc iy
    inc iy
    inc iy
    inc iy
    inc iy
    inc iy
    inc iy
    inc iy
    inc iy
    exx
    ld (hl),d
    exx
    ex af,af'
    exx
    ex de,hl
    ld (hl),e
    ex de,hl
    ld (Dac_YMDataA),a
    ld (hl),e
    ld b,c
Dac_Path021:
    djnz Dac_Path021
    exx
    ex af,af'
    nop
    nop
    inc iy
    cp e
    jp z,Dac_Path067
    ld a,(Z80DACCommandByte4)
    or a
    jp z,Dac_Path019
    jp Dac_Path002
