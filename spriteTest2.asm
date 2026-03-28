// 4‑Sprite Demo — F1/F3/F5/F7 toggle colours on/off

BasicUpstart2(main)

* = $1000

.const CHROUT = $FFD2
.const GETIN  = $FFE4

.const SPRITE_ENABLE   = $D015
.const SPRITE_X        = $D000
.const SPRITE_Y        = $D001
.const SPRITE_XHIGH    = $D010
.const SPRITE_POINTERS = $07F8

.const SPRITE_COLOR0 = $D027
.const SPRITE_COLOR1 = $D028
.const SPRITE_COLOR2 = $D029
.const SPRITE_COLOR3 = $D02A

.const SPRITE_DATA = $3000

main:
    cli
    jsr SetupSprites
    jsr PrintMessage

MainLoop:
    jsr GETIN
    beq MainLoop        // no key

    cmp #$85            // F1
    beq Toggle0
    cmp #$86            // F3
    beq Toggle1
    cmp #$87            // F5
    beq Toggle2
    cmp #$88            // F7
    beq Toggle3

    jmp MainLoop

// --- Toggle handlers ---

Toggle0:
    lda sprite0State
    eor #1
    sta sprite0State
    beq Make0Black
    lda #2              // red
    sta SPRITE_COLOR0
    jmp MainLoop
Make0Black:
    lda #0
    sta SPRITE_COLOR0
    jmp MainLoop

Toggle1:
    lda sprite1State
    eor #1
    sta sprite1State
    beq Make1Black
    lda #1              // white
    sta SPRITE_COLOR1
    jmp MainLoop
Make1Black:
    lda #0
    sta SPRITE_COLOR1
    jmp MainLoop

Toggle2:
    lda sprite2State
    eor #1
    sta sprite2State
    beq Make2Black
    lda #4              // purple
    sta SPRITE_COLOR2
    jmp MainLoop
Make2Black:
    lda #0
    sta SPRITE_COLOR2
    jmp MainLoop

Toggle3:
    lda sprite3State
    eor #1
    sta sprite3State
    beq Make3Black
    lda #5              // green
    sta SPRITE_COLOR3
    jmp MainLoop
Make3Black:
    lda #0
    sta SPRITE_COLOR3
    jmp MainLoop

// --- Setup sprites ---

SetupSprites:
    lda #%00001111
    sta SPRITE_ENABLE

    // clear high X bits
    lda #0
    sta SPRITE_XHIGH

    // sprite pointers
    lda #192            // $3000 / 64
    sta SPRITE_POINTERS+0
    sta SPRITE_POINTERS+1
    sta SPRITE_POINTERS+2
    sta SPRITE_POINTERS+3

    // start all black
    lda #0
    sta SPRITE_COLOR0
    sta SPRITE_COLOR1
    sta SPRITE_COLOR2
    sta SPRITE_COLOR3

    // sprite 0: top-left
    lda #24
    sta SPRITE_X+0
    lda #50
    sta SPRITE_Y+0

    // sprite 1: top-right (X = 300 → low 44, high bit set)
    lda SPRITE_XHIGH
    ora #%00000010      // bit 1
    sta SPRITE_XHIGH
    lda #44
    sta SPRITE_X+2
    lda #50
    sta SPRITE_Y+2

    // sprite 2: bottom-left
    lda #24
    sta SPRITE_X+4
    lda #200
    sta SPRITE_Y+4

    // sprite 3: bottom-right (X = 300 → low 44, high bit set)
    lda SPRITE_XHIGH
    ora #%00001000      // bit 3
    sta SPRITE_XHIGH
    lda #44
    sta SPRITE_X+6
    lda #200
    sta SPRITE_Y+6

    // clear states
    lda #0
    sta sprite0State
    sta sprite1State
    sta sprite2State
    sta sprite3State

    rts

// --- Text ---

PrintMessage:
    ldx #0
PM_Loop:
    lda Message,x
    beq PM_Done
    jsr CHROUT
    inx
    bne PM_Loop
PM_Done:
    rts

Message:
    .text "4 SPRITES IN CORNERS"
    .byte 13
    .text "F1/F3/F5/F7 TOGGLE COLOURS"
    .byte 13,0

// --- State bytes ---

sprite0State: .byte 0
sprite1State: .byte 0
sprite2State: .byte 0
sprite3State: .byte 0

// --- Sprite data ---

* = SPRITE_DATA
.import binary "spriteEG.bin"
.import binary "spriteEG.bin"
.import binary "spriteEG.bin"
.import binary "spriteEG.bin"
