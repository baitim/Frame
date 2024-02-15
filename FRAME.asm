.model tiny
.286
.code
org 100h

locals @@

Start:
            mov bx, 0b800h
            mov es, bx
            mov si, 80h
            xor ch, ch
            mov cl, ds:[si]
            inc si

            call ParseCmd
            call PrintFrame
            call PrintText

            mov ax, 4c13h
	        int 21h

x       dw ?
y       dw ?
x0      dw ?
y0      dw ?
color       db ?
type_sym    dw ?
text    db ?

ch_      db ?

set1: db 'ÉÍ»º ºÈÍ¼'
set2: db 'ÅÄÅ³ ³ÅÄÅ'
set3: db '/Ä\³ ³\_/'

;---------------------------------------------
; writes x, y, x0, y0 color, text from cmd
; Entry:    
; Assumes:  ES
; Destr:    
;---------------------------------------------
ParseCmd    proc
            push ax

            call SkipSpaces
            call GetNumberDec
            mov x, ax

            call SkipSpaces
            call GetNumberDec
            mov y, ax

            call SkipSpaces
            call GetNumberDec
            mov x0, ax

            call SkipSpaces
            call GetNumberDec
            mov y0, ax

            call SkipSpaces
            call GetNumberDec
            mov type_sym, ax

            call SkipSpaces
            call GetNumberHex
            mov color, al

            call SkipSpaces
            pop ax
            ret
endp

;---------------------------------------------
; skip spaces in cmd string (Somitelno, no okeeeeey (c)Tinkoff)
; Entry:    
; Assumes:  DS
; Destr:    si
;---------------------------------------------
SkipSpaces  proc
            @@Next:
                cmp byte ptr ds:[si], ' '
                jne @@End
                inc si
            loop @@Next
            @@End:

            ret
endp

;---------------------------------------------
; get number from cmd string(decimal)
; Entry:    
; Assumes:  DS
; Destr:    si, ax
;---------------------------------------------
GetNumberDec   proc
            push bx
            
            xor ax, ax

            @@Next:
                cmp byte ptr ds:[si], ' '
                je @@End
                
                mov bx, 10
                mul bx
                add al, ds:[si]
                sub ax, 30h

                inc si

            loop @@Next
            @@End:

            pop bx
            ret
endp

;---------------------------------------------
; get number from cmd string(hex)
; Entry:    
; Assumes:  DS
; Destr:    si, ax
;---------------------------------------------
GetNumberHex   proc
            push bx
            
            xor ax, ax

            @@Next:

                cmp byte ptr ds:[si], 20h
                je @@End
                cmp byte ptr ds:[si], 'h'
                je @@End

                shl bx, 4

                cmp byte ptr ds:[si], 39h
                jbe @@Digit
                jmp @@Letter
                
                @@Digit:
                    add al, ds:[si]
                    sub al, 30h
                    inc si
                    loop @@Next

                @@Letter:
                    add al, ds:[si]
                    sub al, 'a' - 10
                    inc si
                    loop @@Next

            @@End:
            inc si
            xor ah, ah
            pop bx
            ret
endp

;---------------------------------------------
; print frame to video memory
; Entry:    x & y - width & height of frame
;           x0 & y0 - left & upper x and y of frame
;           type_sym - type of output symbols
;           color - color of output
; Assumes:  ES
; Destr:    
;---------------------------------------------
PrintFrame  proc
            push ax
            push bx
            push cx
            push dx
            push di
            push si

            call ChooseType
            mov ax, 0
            mov dl, color

            call PrintStr
            add si, 3
            inc ax

            WriteFrame:
                call PrintStr
            inc ax
            cmp ax, y
            jb WriteFrame

            add si, 3
            call PrintStr

            pop si
            pop di
            pop dx
            pop cx
            pop bx
            pop ax
            ret
endp

;---------------------------------------------
; prints string to video memory
; Entry:    x & y - width & height of frame
;           x0 & y0 - left & upper x and y of frame
;           type_sym - type of output symbols
;           DL - color of output
; Assumes:  ES
; Destr:    
;---------------------------------------------
PrintStr    proc
            push si

            call SetPosition

            call SetChar
            call PUTC

            call SetChar
            call MEMSET

            call SetChar
            call PUTC

            pop si
            ret
endp

;---------------------------------------------
; prints text in frame to video memory
; Entry:    x & y - width & height of frame
;           x0 & y0 - left & upper x and y of frame
;           si - offset to text
;           DL - color of output
; Assumes:  ES
; Destr:    
;---------------------------------------------
PrintText   proc
            push si
            push ax
            push bx

            mov dl, color
            dec cx

            mov ax, 0
            call SetPosition
            add di, 2

            mov bl, 2dh
            call MEMCPYN ; author

            mov ax, 1
            call SetPosition
            add di, 2

            mov bl, 24h
            call MEMCPYN ; text

            pop bx
            pop ax
            pop si
            ret
endp

;---------------------------------------------
; copy bytes between indexes in memory
; Entry:    SI - offset in ds
;           DI - offset in es
;           CX - count bytes to copy
;           DL - color of output
;           BL - break byte 
; Assumes:  ES
;           DS
; Destr:    
;---------------------------------------------
MEMCPYN     proc
            push ax

            @@Next:
                cmp bl, ds:[si]
                je @@End1

                mov al, ds:[si]
                mov es:[di], al
                inc si
                inc di
                mov es:[di], dl
                inc di
            loop @@Next
            jmp @@End2

            @@End1:
                add si, 1
                dec cx
            @@End2:
            pop ax
            ret
endp

;---------------------------------------------
; set bytes in memory
; Entry:    DI - offset in es
;           DH - src byte
;           DL - color of output
; Assumes:  ES
; Destr: lier
;---------------------------------------------
PUTC        proc

            mov es:[di], dh
            inc di
            mov es:[di], dl
            inc di

            ret
endp

;---------------------------------------------
; set bytes in memory
; Entry:    DI - offset in es
;           DH - src byte
;           CX - count bytes to check
; Assumes:  ES
;           DS
;           CX - count of bytes
; Destr: 
;---------------------------------------------
MEMSET      proc
            push ax

            mov cx, x
            @@Next:
                mov es:[di], dh
                inc di
                mov es:[di], dl
                inc di
            loop @@Next

            pop ax
            ret
endp

;---------------------------------------------
; save in dh byte from ds[si]
; Entry:    SI - offset to byte
; Assumes:  DS
; Destr:    DH, SI
;---------------------------------------------
SetChar     proc
            push ax

            lodsb
            mov dh, al

            pop ax
            ret
endp

;---------------------------------------------
; save in si offset to symbols in ds
; Entry:    type_sym - type of symbols
; Assumes:  DS
; Destr:    SI
;---------------------------------------------
ChooseType  proc

            cmp type_sym, 1
            jne @@Type2
            mov si, offset set1
            jmp @@End

            @@Type2:
            cmp type_sym, 2
            jne @@Type3
            mov si, offset set2
            jmp @@End

            @@Type3:
            cmp type_sym, 3
            mov si, offset set3
            jmp @@End

            @@End:
            ret
endp

;---------------------------------------------
; set index in video mem by (x0, y0)
; Entry:    AX - y in frame
;           x0 & y0 - left & upper x and y of frame
; Assumes:  ES
; Destr:    DI
;---------------------------------------------
SetPosition proc
            push ax
            push dx

            add ax, y0
            mov bx, 160
            mul bx
            add ax, x0
            mov di, ax

            pop dx
            pop ax
            ret
endp

;---------------------------------------------
; print ax to memory
; Entry:    ax
; Assumes:  ax = [0, 99]
; Destr:    
;---------------------------------------------
OUTAX       proc
            push ax
            push dx

            aam
            add ax, 3030h
            mov dl, ah
            mov dh, al
            mov ah, 02h
            int 21h
            mov dl, dh
            int 21h

            call OUTNEXTSTR

            pop dx
            pop ax
            ret
endp

;---------------------------------------------
; print 0ah
; Entry:    
; Assumes:  
; Destr:    
;---------------------------------------------
OUTNEXTSTR  proc
            push ax
            push dx
            
            mov ah, 02h
            mov dl, 0ah
            int 21h

            pop dx
            pop ax
            ret
endp

end Start