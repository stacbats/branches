// ------------------------------------------------------------
// C64 Simple Branching Demo with Jump Table + Sound
// Press F1, F3 or F5 to change border color and hear a beep
// ------------------------------------------------------------

BasicUpstart2(main)         // This tells KickAssembler to add a tiny BASIC line at the start:
                            // 10 SYS 4096  so the program can be RUN from BASIC

* = $1000                   // Put our machine code starting at memory address $1000 (4096 in decimal)

// Kernal routines (built-in C64 functions to use)
.const CHROUT = $FFD2       // CHROUT = Print one character to the screen
.const GETIN  = $FFE4       // GETIN  = Check if a key was pressed (returns 0 if no key)

// Hardware registers
.const BORDER = $D020       // BORDER = Memory location that controls the screen border color
.const SID    = $D400       // SID    = Base address of the Sound Interface Device (sound chip)

// Temporary pointer used by the jump table (safe zero-page memory)
.const JUMP_PTR = $FB       // We use $FB and $FC to store a 16-bit address temporarily

// ------------------------------------------------------------
// Main program starts here
// ------------------------------------------------------------
main:
    cli                     // Enable interrupts so the keyboard works properly

    jsr InitSID             // Call subroutine to silence the sound chip at the beginning
    jsr PrintMessage        // Call subroutine to print the starting message on screen
    jsr NewLine             // Print a new empty line

// This is the main waiting loop
WaitKey:
    jsr GETIN               // Ask the keyboard: "Was any key pressed?" Result goes into A register
    beq WaitKey             // If no key was pressed (A = 0), branch back and wait again

    // --- Figure out which function key was pressed ---
    ldx #0                  // Start with index 0 (we will use this for the jump table)
    cmp #$85                // Compare the pressed key with F1's code ($85)
    beq DoJump              // If it matches F1, go to DoJump
    inx                     // Increase index to 1
    cmp #$86                // Compare with F3's code ($86)
    beq DoJump              // If it matches F3, go to DoJump
    inx                     // Increase index to 2
    cmp #$87                // Compare with F5's code ($87)
    beq DoJump              // If it matches F5, go to DoJump

    jmp WaitKey             // If none of the three keys, ignore it and wait again

// This part prepares the indirect jump using the table
DoJump:
    txa                     // Copy the index number (0, 1 or 2) from X into A
    asl                     // Shift left = multiply by 2 (because each table entry uses 2 bytes)
    tax                     // Put the multiplied value back into X (now 0, 2 or 4)

    // Copy the correct address from the jump table into our pointer
    lda KeyTable,x          // Load low byte of the address
    sta JUMP_PTR            // Store it in the low byte of the pointer
    lda KeyTable+1,x        // Load high byte of the address
    sta JUMP_PTR+1          // Store it in the high byte of the pointer

    jmp (JUMP_PTR)          // Indirect jump: go to whatever address is stored in JUMP_PTR

// ------------------------------------------------------------
// Jump Table - list of addresses to the three handlers
// ------------------------------------------------------------
KeyTable:
    .word PressedF1         // Address of the code that handles F1
    .word PressedF3         // Address of the code that handles F3
    .word PressedF5         // Address of the code that handles F5

// ------------------------------------------------------------
// The three short handlers (one for each key)
// ------------------------------------------------------------
PressedF1:
    lda #2                  // Load color number 2 (red) into A
    sta BORDER              // Store it in the border color register → border turns red
    lda #50                 // Load a low number for pitch (lower = deeper sound)
    jsr PlayBeep            // Call the sound subroutine to play a beep
    lda #'1'                // Load the character '1' (we will print this later)
    jmp PrintPressed        // Jump to the common printing routine

PressedF3:
    lda #1                  // Load color number 1 (white)
    sta BORDER              // Change border to white
    lda #80                 // Load a medium number for pitch
    jsr PlayBeep            // Play the beep
    lda #'3'                // Load the character '3'
    jmp PrintPressed        // Go to printing routine

PressedF5:
    lda #6                  // Load color number 6 (blue)
    sta BORDER              // Change border to blue
    lda #120                // Load a higher number for pitch (higher = higher sound)
    jsr PlayBeep            // Play the beep
    lda #'5'                // Load the character '5'
    jmp PrintPressed        // Go to printing routine

// ------------------------------------------------------------
// Common routine: print "YOU PRESSED F" + the number
// ------------------------------------------------------------
PrintPressed:
    sta keyStore            // Save the digit character ('1', '3' or '5') in memory
    jsr PrintYouPressed     // Call subroutine to print "YOU PRESSED F"
    lda keyStore            // Load the saved digit back into A
    jsr CHROUT              // Print the digit on the screen
    jsr NewLine             // Print a new line so the next message is below
    jmp WaitKey             // Go back to waiting for the next key press

// ------------------------------------------------------------
// Sound routines
// ------------------------------------------------------------
PlayBeep:
    pha                     // Push (save) the pitch value on the stack so we don't lose it

    // Quickly silence the sound chip before making a new sound
    ldx #0                  // Start X at 0
    txa                     // Put 0 into A
ClearSID:
    sta SID,x               // Store 0 into every SID register to clear old sound
    inx                     // Increase X
    cpx #29                 // Have we cleared 29 bytes?
    bne ClearSID            // If not, loop again

    pla                     // Pull (restore) the pitch value from the stack into A
    sta SID+1               // Store pitch in the frequency high byte of Voice 1

    lda #15                 // Load maximum volume value
    sta SID+24              // Set overall volume to maximum

    lda #9                  // Attack/Decay settings (quick attack, short decay)
    sta SID+5
    lda #0                  // Sustain/Release settings
    sta SID+6

    lda #$21                // Waveform = Triangle ($20) + Gate on ($01) = $21
    sta SID+4               // Start the sound

    // Short delay so the beep lasts a moment (you can change 80 for longer/shorter)
    ldy #80
DelayBeep:
    ldx #0
Inner:
    dex                     // Inner delay loop (counts down from 255 to 0)
    bne Inner
    dey                     // Outer delay loop
    bne DelayBeep

    lda #$20                // Gate off ($20) - stop the sound
    sta SID+4
    rts                     // Return from subroutine

InitSID:
    ldx #0                  // Same as ClearSID - make sure sound chip starts silent
    txa
InitLoop:
    sta SID,x
    inx
    cpx #29
    bne InitLoop
    rts

// ------------------------------------------------------------
// Printing subroutines
// ------------------------------------------------------------
PrintMessage:
    ldx #0                  // Start at first character of the message
PM_Loop:
    lda Message,x           // Load next character from the Message data
    beq PM_Done             // If we reach the 0 byte, we are at the end
    jsr CHROUT              // Print the character
    inx                     // Move to next character
    bne PM_Loop             // Loop until done
PM_Done:
    rts                     // Return to caller

PrintYouPressed:
    ldx #0                  // Start at first character of "YOU PRESSED F"
PYP_Loop:
    lda YouPressed,x        // Load next character
    beq PYP_Done            // End when we hit 0
    jsr CHROUT              // Print it
    inx
    bne PYP_Loop
PYP_Done:
    rts

NewLine:
    lda #13                 // PETSCII code 13 = carriage return (new line)
    jsr CHROUT              // Print the new line
    rts

// ------------------------------------------------------------
// Data (text and storage)
// ------------------------------------------------------------
Message:
    .text "PRESS F1, F3 OR F5"  // The starting message
    .byte 0                     // 0 marks the end of the text

YouPressed:
    .text "YOU PRESSED F"       // The text printed when a key is pressed
    .byte 0                     // End marker

keyStore:
    .byte 0                     // One byte of memory to temporarily save the digit ('1','3','5')