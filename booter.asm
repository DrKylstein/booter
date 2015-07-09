timer_data      = 40h
timer_counter	= 42h
timer_control	= 43h
speaker_port	= 61h
countdown = 1193180/16000
BLOCK_SIZE = 1

    .8086
    .model tiny
.code
    org 7c00h
    jmp start
    org 7c03h
    db "CONHGECO" ;vendor name
    dw 512 ;bytes per sector
    db 1 ;sectors per logical sector
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
    
    ReadSectors proc
        push bp
        mov bp,sp
        xor ax,ax
        push ax ; retry count bp+0
        
        ;reset disk
        mov ah,0
        mov dl,0
        int 13h
        
    read:
    ;set up read
        mov ax,[bp+4] ;dest segment
        mov es,ax
        mov bx,[bp+6] ;dest offset
        mov ax,BLOCK_SIZE ;# logical sectors
        mov cx,[bp+10] ;start logical sector
        
     ;do read   
        push ax ;al contains number of sectors
        mov dx,0
        mov ax,cx
        mov cx,18
        div cx
        mov ch,al ;track = logical sector/18
        mov dh,ch
        and dh,1 ;head = logical sector/18 % 1
        shr ch,1 ;track = logical sector/18/2 = logical sector/36
        mov cl,dl
        inc cl ;sector = (logical sector%18) + 1
        pop ax ;retrieve input ax, al = logical sector count
        mov ah,02h ;mode = read sectors
        mov dl,0 ;drive number
        int 13h
        
    ;retry
        jnc correct
        cmp word ptr [bp+0],1
        jge correct
        inc word ptr [bp+0]
        ;reset disk
        mov ah,0
        mov dl,0
        int 13h
        jmp read
        correct:
        
        sub word ptr [bp+8],BLOCK_SIZE
        add word ptr [bp+10],BLOCK_SIZE
        add word ptr [bp+4],BLOCK_SIZE*512/16
        cmp word ptr [bp+8],0
        jne read
        
        inc sp
        inc sp
        pop bp
        ret
    ReadSectors endp
    
    start proc far
        cli
        ;attempted to force segment, failed in DosBox
        ;xor ax,ax
        ;mov cs,ax
        mov ax,cs
        mov ds,ax
        ;grow stack from before the code down to 0000:0000
        mov ss,ax
        mov bp,7c00h 
        mov sp,7c00h
        
        ;change timer interrupt vector
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
        
        ;load image
        mov ax,1 ;start sector
        push ax
        mov ax,32 ;number of sectors
        push ax
        mov ax,0000h ;offset
        push ax
        mov ax,0b800h ;segment
        push ax
        call ReadSectors
        add sp,8
        
        ;load music
        mov ax,34 ;start sector
        push ax
        mov ax,448;438;73 ;number of sectors
        push ax
        mov ax,0000h ;offset
        push ax
        mov ax,1000h ;segment
        push ax
        call ReadSectors
        add sp,8
        
        ; Set timer 0 up with the specified playback frequency
        mov al,36h
        out timer_control,al
        mov cx,countdown
        mov al,cl
        out timer_data,al
        mov al,ch
        out timer_data,al
    music_start:
        mov ax,1000h
        mov ds,ax
        xor bx,bx
    play_music:
        hlt
        mov al, [bx]
        out	timer_counter,al
        hlt
        out timer_counter,al
        
        inc bx
        cmp bx,16
        jne nowrap
        mov ax,ds
        inc ax
        mov ds,ax
        xor bx,bx
    nowrap:
        cmp byte ptr [bx], 0ffh
        jne play_music
        jmp music_start

        org 7dfeh
        dw 55aah ; boot sector signature
    start endp
    end start
