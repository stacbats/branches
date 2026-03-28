// ------------------------------------------------------------
// C64 Compare Demo - Learning CMP (Compare)
// Fully commented line-by-line for absolute beginners
// Press number keys 1, 2, 3, 4 or 5 on the keyboard
// Each key changes the border color, plays a different beep, and prints a message
// ------------------------------------------------------------

BasicUpstart2(main)         // Add a BASIC line at the start so we can type RUN to start the program

* = $1000                   // Tell the assembler to place our machine code at memory address $1000

// Kernal routines (ready-made functions built into the C64 ROM)
.const CHROUT = $FFD2       // CHROUT = Print one character to the screen
.const GETIN  = $FFE4       // GETIN  = Check keyboard and return the key pressed (or 0 if none)

// Hardware registers
.const BORDER = $D020       // BORDER = Location that controls the color of the screen border
.const SID    = $D400       // SID    = Start of the sound chip (SID) memory

main:
    cli                     // Enable interrupts so the keyboard scanning works properly

    jsr InitSID             // Call subroutine to turn off any old sound
    jsr PrintMessage        // Call subroutine to print the instruction message
    jsr NewLine             // Print a blank line for nicer spacing

// Main loop - waits for the player to press a key
WaitKey:
    jsr GETIN               // Ask the keyboard if any key was pressed. Result goes into A register
    beq WaitKey             // If A is 0 (no key pressed), branch back and keep waiting

    pha                     // Save the pressed key value on the stack (we need it later)

    // ------------------------------------------------------------
    // Compare the actual key that was pressed using CMP
    // CMP sets flags so we can use BEQ to jump if values are equal
    // ------------------------------------------------------------
    cmp #'1'                // Compare the key in A with the character '1'
    beq Pressed1            // If they are equal, jump to the Pressed1 handler

    cmp #'2'                // Compare with '2'
    beq Pressed2            // If equal, jump to Pressed2

    cmp #'3'                // Compare with '3'
    beq Pressed3            // If equal, jump to Pressed3

    cmp #'4'                // Compare with '4'
    beq Pressed4            // If equal, jump to Pressed4

    cmp #'5'                // Compare with '5'
    beq Pressed5            // If equal, jump to Pressed5

    // If none of the keys 1-5 were pressed, ignore it
    pla                     // Remove the saved key from the stack (cleanup)
    jmp WaitKey             // Go back to waiting for a new key

// ------------------------------------------------------------
// Handler routines - one for each number key
// ------------------------------------------------------------
Pressed1:
    pla                     // Remove the saved key from the stack (important cleanup)
    lda #2                  // Load color value 2 (which is red) into A
    sta BORDER              // Store it in the border register → border becomes red
    lda #40                 // Load a low number (low pitch sound)
    jsr PlayBeep            // Call the sound subroutine to play a short beep
    lda #'1'                // Load the character '1' so we can print it later
    jmp PrintNumberPressed  // Jump to the common printing routine

Pressed2:
    pla                     // Cleanup stack
    lda #1                  // Load color 1 (white)
    sta BORDER              // Change border to white
    lda #60                 // Medium-low pitch
    jsr PlayBeep            // Play beep
    lda #'2'                // Prepare to print '2'
    jmp PrintNumberPressed

Pressed3:
    pla
    lda #5                  // Load color 5 (green)
    sta BORDER
    lda #80                 // Medium pitch
    jsr PlayBeep
    lda #'3'
    jmp PrintNumberPressed

Pressed4:
    pla
    lda #6                  // Load color 6 (blue)
    sta BORDER
    lda #100                // Medium-high pitch
    jsr PlayBeep
    lda #'4'
    jmp PrintNumberPressed

Pressed5:
    pla
    lda #4                  // Load color 4 (purple)
    sta BORDER
    lda #130                // Higher pitch
    jsr PlayBeep
    lda #'5'
    jmp PrintNumberPressed

// ------------------------------------------------------------
// Common routine: prints "YOU PRESSED " + the number
// ------------------------------------------------------------
PrintNumberPressed:
    sta keyStore            // Save the digit character ('1' to '5') in memory for later
    jsr PrintYouPressed     // Call subroutine to print "YOU PRESSED "
    lda keyStore            // Load the saved digit back into A
    jsr CHROUT              // Print the number on the screen
    jsr NewLine             // Move cursor to the next line
    jmp WaitKey             // Return to the main waiting loop

// ------------------------------------------------------------
// Sound subroutine - plays a short beep
// ------------------------------------------------------------
PlayBeep:
    pha                     // Save the pitch value (A) on the stack so we don't lose it

    // Clear all SID registers to stop any previous sound
    ldx #0                  // Start counter at 0
    txa                     // Put 0 into A
ClearSID:
    sta SID,x               // Store 0 into each SID register
    inx                     // Move to next register
    cpx #29                 // Have we cleared enough registers?
    bne ClearSID            // If not, keep looping

    pla                     // Restore the pitch value from the stack
    sta SID+1               // Store pitch into frequency high byte of Voice 1

    lda #15                 // Load maximum volume value
    sta SID+24              // Set overall volume to loud

    lda #9                  // Attack/Decay settings (quick start, short decay)
    sta SID+5
    lda #0                  // Sustain/Release = 0
    sta SID+6

    lda #$21                // Triangle waveform + gate on (start the note)
    sta SID+4

    // Simple delay loop so the beep lasts long enough to hear
    ldy #60                 // Outer delay counter (change this number for longer/shorter beep)
DelayBeep:
    ldx #0                  // Inner delay counter
Inner:
    dex                     // Count down X from 255 to 0
    bne Inner               // Loop until X reaches 0
    dey                     // Decrease outer counter
    bne DelayBeep           // Keep delaying until Y reaches 0

    lda #$20                // Gate off (stop the sound)
    sta SID+4
    rts                     // Return from the PlayBeep subroutine

// Initialize sound chip at the start (make sure it's silent)
InitSID:
    ldx #0                  // Start at register 0
    txa                     // A = 0
InitLoop:
    sta SID,x               // Clear each register
    inx
    cpx #29
    bne InitLoop
    rts

// ------------------------------------------------------------
// Printing subroutines
// ------------------------------------------------------------
PrintMessage:
    ldx #0                  // Start at the first character of the message
PM_Loop:
    lda Message,x           // Load next character from Message data
    beq PM_Done             // If we read a 0 byte, we reached the end of text
    jsr CHROUT              // Print the character to screen
    inx                     // Move to next character
    bne PM_Loop             // Continue until done
PM_Done:
    rts                     // Return to where we were called from

PrintYouPressed:
    ldx #0                  // Start at first character of "YOU PRESSED "
PYP_Loop:
    lda YouPressed,x        // Load next character
    beq PYP_Done            // Stop when we hit the 0 byte
    jsr CHROUT              // Print it
    inx
    bne PYP_Loop
PYP_Done:
    rts

NewLine:
    lda #13                 // PETSCII code for carriage return (moves to new line)
    jsr CHROUT              // Print the new line
    rts

// ------------------------------------------------------------
// Data section - text messages and temporary storage
// ------------------------------------------------------------
Message:
    .text "PRESS A NUMBER KEY 1-5"   // Message shown at the start
    .byte 0                          // 0 marks the end of the text string

YouPressed:
    .text "YOU PRESSED "             // Text printed before the number
    .byte 0                          // End of string marker

keyStore:
    .byte 0                          // One byte of memory to temporarily save the digit we want to print