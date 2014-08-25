timer_data      = 40h
timer_counter	= 42h
timer_control	= 43h
speaker_port	= 61h
countdown = 1193180/16000

    .8086
    .model tiny
.code
    org 7c00h
    jmp short start
    nop
    db "CONHGECO" ;vendor name
    dw 512 ;bytes per sector
    db 1 ;sectors per cluster
    dw 33 ;reserved sectors
    db 2 ;FAT copies
    dw 224 ;root directory entries
    dw 2880 ;total sectors
    db 0f0h ;media descriptor: 1.44MB floppy
    dw 9 ;sectors per FAT
    dw 18 ; sectors per track
    dw 2 ;heads (double-sided?)
    dw 0 ;hidden sectors
    ;extended:
    ;dw 0 ;extension of hidden sectors
    ;dd 2880 ;copy of total sectors
    ;db 0 ;logical drive number
    ;db 0 ;reserved
    ;db 29h ;extended signature
    ;dd 00001138h ; serial number of partition
    ;db "NO NAME    " ;volume label (MSDOS 6 only recognizes one in FAT)
    ;db "BOOTER  ";db "FAT12   " ;filesystem type  
    TimerHandler proc
        push ax
        mov al,20h
        out 20h,al
        pop ax
        iret
    TimerHandler endp
    
    start:
        cli
        mov ax,cs
        mov ds,ax
        mov ss,ax
        mov bp,7c00h
        mov sp,7c00h
        
        xor ax,ax
        mov es,ax
        mov bx,8*4
        mov word ptr es:[bx], 7C1Eh
        add bx,2
        mov word ptr es:[bx], 0000h
        sti

        ; Set up timer 2 to only expect 1 byte countdown values, and to only
        ; generate one pulse
        mov al,10010000b
        out timer_control,al
        ; Connect timer 2 to the speaker
        in al,speaker_port
        or al,03h
        out speaker_port,al

    ;set video mode    
        mov ax,0004h
        int 10h
    ;set palette
        mov ah,0bh
        mov bh,1
        mov bl,0
        int 10h

        REPEAT 3
    ;reset disk
        mov ah,0
        int 13h
    ;display image
        mov ax,0b800h ;dest segment
        mov es,ax
        mov bx,0000h ;dest offset
        mov ah,02 ;read sectors
        mov al,32 ;# sectors
        mov cl,02 ;sector
        mov ch,00h;track
        mov dl,00h;drive
        mov dh,00h;head
        int 13h
        ENDM
        
        REPEAT 3
        mov ah,0
        int 13h
        mov ax,1000h ;dest segment
        mov es,ax
        mov bx,0000h;dest offset
        mov ah,02h  ;read sectors
        mov al,36;# sectors
        mov cl, 1;sector
        mov ch, 1;track
        mov dl, 0;drive
        mov dh, 0;head
        int 13h
        ENDM
        
        ; mov al,ah
        ; mov ah,0eh
        ; mov bh,0
        ; mov bl,2
        ; int 10h
        
        REPEAT 3
        mov ah,0
        int 13h
        mov ax,1000h ;dest segment
        mov es,ax
        mov bx,4800h;dest offset
        mov ah,02h  ;read sectors
        mov al,37;# sectors
        mov cl, 1;sector
        mov ch, 2;track
        mov dl, 0;drive
        mov dh, 0;head
        int 13h
        ENDM
        
        ; mov al,ah
        ; mov ah,0eh
        ; mov bh,0
        ; mov bl,2
        ; int 10h
        
        ; Set timer 0 up with the specified playback frequency
        mov al,36h
        out timer_control,al
        mov cx,countdown
        mov al,cl
        out timer_data,al
        mov al,ch
        out timer_data,al
                
        mov ax,1000h
        mov ds,ax
        xor bx,bx
    end_of_program:
        hlt
        mov al, [bx]
        out	timer_counter,al
        hlt
        out timer_counter,al
        
        inc bx
        cmp [bx], 0ffh
        jne continue
        xor bx,bx
    continue:
        jmp end_of_program

        org 7dfeh
        dw 55aah ; boot sector signature
    end start
