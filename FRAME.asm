.model tiny
.286
.code
org 100h

locals @@

Start:
            call SaveVideoMem
            call MakeNew08
            call MakeNew09

            call Exit

videomem db 25 * 80 * 2 dup(0)
activate db 0
x       dw 10
y       dw 7
x0      dw 10
y0      dw 5
color       db 4eh
type_sym    dw 1

set1: db 'ÉÍ»º ºÈÍ¼'
set2: db 'ÅÄÅ³ ³ÅÄÅ'
set3: db '/Ä\³ ³\_/'
regs: db 'AXBXCXDXSIDI'

;---------------------------------------------
; finish main program
; Entry:    
; Assumes:  
; Destr:    AX, DX
;---------------------------------------------
Exit    proc 

        mov ax, 3100h
        mov dx, offset EOP
        shr dx, 4
        inc dx
        int 21h
    
        ret
endp

;---------------------------------------------
; save video memory in videomem
; Entry:    
; Assumes:  
; Destr:    
;---------------------------------------------
SaveVideoMem    proc 
        push cx
        push ds
        push es
        push si
        push di

        mov di, offset videomem
        push ds
        pop es
        push 0b800h
        pop ds
        mov si, 0
        mov cx, 25 * 80 * 2
        rep movsb

        pop di
        pop si
        pop es
        pop ds
        pop cx
        ret
endp

;---------------------------------------------
; rewrite 09 intr
; Entry:    
; Assumes:  
; Destr:    
;---------------------------------------------
MakeNew09   proc
            push ax
            push bx
            push es

            mov ax, 3509h
            int 21h
            mov old09Ofs, bx
            mov bx, es
            mov old09Seg, bx
            xor ax, ax
            mov es, ax
            mov bx, 4 * 9

            cli
            mov es:[bx], offset New09
            push cs
            pop ax
            mov es:[bx+2], ax
            sti
    
            pop es
            pop bx
            pop ax
            ret
endp

;---------------------------------------------
; print frame if '1' activate
; Entry:    
; Assumes:  
; Destr:    
;---------------------------------------------
New09   proc 
        push ax
        push bx
        push es
		push ds

        in al, 60h

        cmp al, 02h
        jne @@Next1
        mov cs:activate, 01h
        jmp @@Exit

        @@Next1:
        cmp al, 03h
        jne @@Next2
        mov cs:activate, 00h
        call PrintFilledFrame
        jmp @@Exit

        @@Next2:
        cmp al, 04h
        jne @@Exit
        mov cs:activate, 00h
        call ClearWindow

        @@Exit:
		pop ds
        pop es
        pop bx
        pop ax

        db 0EAh
old09Ofs dw 0
old09Seg dw 0

        iret
endp

;---------------------------------------------
; rewrite 08 intr
; Entry:    
; Assumes:  
; Destr:    
;---------------------------------------------
MakeNew08   proc
            push ax
            push bx
            push es

            mov ax, 3508h
            int 21h
            mov old08Ofs, bx
            mov bx, es
            mov old08Seg, bx
            xor ax, ax
            mov es, ax
            mov bx, 4 * 8

            cli
            mov es:[bx], offset New08
            push cs
            pop ax
            mov es:[bx+2], ax
            sti
    
            pop es
            pop bx
            pop ax
            ret
endp

;---------------------------------------------
; print frame if '1' activate
; Entry:    
; Assumes:  
; Destr:    
;---------------------------------------------
New08   proc 
        push ax
        push bx
        push es
        push ds

        cmp cs:activate, 01h
        jne @@Exit
        call PrintFilledFrame

        @@Exit:
        pop ds
        pop es
        pop bx
        pop ax

        db 0EAh
old08Ofs dw 0
old08Seg dw 0

        iret
endp

;---------------------------------------------
; print frame with registers
; Entry:    
; Assumes:  
; Destr:    
;---------------------------------------------
PrintFilledFrame   proc 
            push bx
            push es
            push ds
            
            mov bx, 0b800h
            mov es, bx
            push cs
            pop ds
            call PrintFrame
            call PrintRegisters

            pop ds
            pop es
            pop bx
            ret
endp

;---------------------------------------------
; clear video memory
; Entry:    x & y - width & height of frame
;           x0 & y0 - left & upper x and y of frame
; Assumes:  ES
;           videomem (saved video memory)
; Destr:    
;---------------------------------------------
ClearWindow  proc
            push cx
            push ds
            push es
            push si
            push di

            push cs
            pop ds
            push 0b800h
            pop es
            mov di, 0
            mov si, offset videomem
            mov cx, 25 * 80 * 2
            rep movsb

            pop di
            pop si
            pop es
            pop ds
            pop cx
            ret
endp

;---------------------------------------------
; print registers in frame to video memory
; Entry:    x & y - width & height of frame
;           x0 & y0 - left & upper x and y of frame
;           color - color of output
; Assumes:  ES
; Destr:    
;---------------------------------------------
PrintRegisters  proc
            push bp
            push ax
            push bx
            push cx
            push dx
			push si
            push di

            mov bp, sp
			mov si, offset cs:regs
            mov ax, 1
			mov dl, 4eh

            @@Next:
                call PrintRegister
                add bp, 2
            inc ax
            cmp ax, y
            jb @@Next

            pop di
			pop si
            pop dx
            pop cx
            pop bx
            pop ax
            pop bp
            ret
endp

;---------------------------------------------
; print register in frame to video memory
; Entry:    x & y - width & height of frame
;           x0 & y0 - left & upper x and y of frame
;           color - color of output
; Assumes:  ES
;           BP
; Destr:    DI
;---------------------------------------------
PrintRegister  proc
            push bx

			mov bx, ss:[bp]

            call SetPosition
            add di, 2

			call SetChar
			call PUTC
			call SetChar
			call PUTC
            mov dh, ':'
            call PUTC
            call PUTBX

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
            mov dl, cs:color

            call PrintStr
            add si, 3
            inc ax

            WriteFrame:
                call PrintStr
            inc ax
            cmp ax, cs:y
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
; set index in video mem by (x0, y0)
; Entry:    AX - y in frame
;           x0 & y0 - left & upper x and y of frame
; Assumes:  ES
; Destr:    DI
;---------------------------------------------
SetPosition proc
            push ax
            push dx
            push bx

            add ax, cs:y0
            mov bx, 160
            mul bx
            add ax, cs:x0
            mov di, ax

            pop bx
            pop dx
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
            call PUTS

            call SetChar
            call PUTC

            pop si
            ret
endp

;---------------------------------------------
; set bytes in memory
; Entry:    DI - offset in es
;           DH - src byte
;           X - count bytes to check
; Assumes:  ES
; Destr:    DI
;---------------------------------------------
PUTS        proc

            mov cx, cs:x
            @@Next:
                mov es:[di], dh
                inc di
                mov es:[di], dl
                inc di
            loop @@Next

            ret
endp

;---------------------------------------------
; set bytes in memory
; Entry:    DI - offset in es
;           DH - src byte
;           DL - color of output
; Assumes:  ES
; Destr:    DI
;---------------------------------------------
PUTC        proc

            mov es:[di], dh
            inc di
            mov es:[di], dl
            inc di

            ret
endp

;---------------------------------------------
; save in si offset to symbols in ds
; Entry:    type_sym - type of symbols
; Assumes:  DS
; Destr:    SI
;---------------------------------------------
ChooseType  proc

            cmp cs:type_sym, 1
            jne @@Type2
            mov si, offset cs:set1
            jmp @@End

            @@Type2:
            cmp cs:type_sym, 2
            jne @@Type3
            mov si, offset cs:set2
            jmp @@End

            @@Type3:
            cmp cs:type_sym, 3
            mov si, offset cs:set3
            jmp @@End

            @@End:
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
; print register bx to video memory
; Entry:    DI - index in video memory
; Assumes:  ES
; Destr:    DI
;---------------------------------------------
PUTBX       proc
            push bx
            push dx
            push ax

            mov ah, bh
            call PUTAH
            mov ah, bl
            call PUTAH

			mov dh, 'h'
            call PUTC

            pop ax
            pop dx
            pop bx
            ret
endp

;---------------------------------------------
; print register ah to video memory
; Entry:    DI - index in video memory
; Assumes:  ES
; Destr:    DI
;---------------------------------------------
PUTAH       proc
            push ax
            push bx
            push dx

            mov bh, ah
            shr ah, 4
            mov dh, ah

            cmp dh, 9h
            jbe @@Digit1
            add dh, 7h
            @@Digit1:
            add dh, 30h
            call PUTC

            shl ah, 4
            sub bh, ah
            mov dh, bh

            cmp dh, 9h
            jbe @@Digit2
            add dh, 7h
            @@Digit2:
            add dh, 30h
            call PUTC

            pop dx
            pop bx
            pop ax
            ret
endp

EOP:
end Start