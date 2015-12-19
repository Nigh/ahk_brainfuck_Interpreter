
if(%0%<=0){
	Msgbox, drop file on it, Please.
	ExitApp, -5
}
path=%1%
IfNotExist, % path
{
	Msgbox, drop file on it, Please.
	ExitApp, -4
}
SplitPath, % path, OutFileName, OutDir, OutExtension, OutNameNoExt, OutDrive

hFile:=fileOpen(path,"r")
if(ErrorLevel)
{
	MsgBox, Something goes wrong while trying open the source file.
	ExitApp, -3
}

VarSetCapacity(ram, 0xFFFF, 0)
VarSetCapacity(source, 0xFFFF, 0)
bf:=new brainfuck(ram,source)
while(!hFile.AtEOF){
	bf.translate(hFile.ReadUChar())
}
bf.pc_ret()
while(1)
	bf.interpret()




class brainfuck
{
	; static ptr:=0,sptr:=0,looplevel:=0

	__New(byref ram,byref src)
	{
		this.ptr:=0
		this.sptr:=0
		this.looplevel:=0
		this.ram:=&ram
		this.source:=&src
	}

	pc_ret()
	{
		this.sptr:=0
		this.ptr:=0
	}

	interpret()
	{
		if(this.sptr>0xFFFF)
		{
			MsgBox, % "Program End`nPtr=" this.ptr "`nsPtr=" this.sptr
			ExitApp, 0
		}
		op:=NumGet(this.source, this.sptr++,"UChar")
		; MsgBox, % op
		Loop, 1
		{
			if(!IsLabel("case-" op))
			{
				op:=0
			}
			; MsgBox, case-%op%
			goto case-%op%
			case-0:
			Return
			case-43:	;+
			this.plus()
			break
			case-45:	;-
			this.minus()
			break
			case-60:	;<
			this.prev()
			break
			case-62:	;>
			this.next()
			break
			case-46:	;.
			this.print()
			break
			case-44:	;,
			this.get()
			break
			case-91:	;[
			this.loopstart()
			break
			case-93:	;]
			this.loopend()
			break
		}
	}

	translate(byte)
	{
		if(InStr("+-<>.,[]", chr(byte)))
		{
			NumPut(byte, this.source, this.sptr++,"UChar")
			if(this.sptr>0xFFFF)
			{
				MsgBox, Program larger than 65535. Exit for safe.
				ExitApp, -1
			}
		}
	}

	plus() {
		; MsgBox, % A_ThisFunc
		NumPut((NumGet(this.ram, this.ptr,"UChar")+0x01)&0xFF,this.ram, this.ptr,"UChar")
		this.sptr++
	}
	minus() {
		; MsgBox, % A_ThisFunc
		NumPut((NumGet(this.ram, this.ptr,"UChar")+0xFF)&0xFF,this.ram, this.ptr,"UChar")
		this.sptr++
	}
	next() {
		; MsgBox, % A_ThisFunc
		this.ptr+=1
		if(this.ptr>0xFFFF)
		{
			MsgBox, ptr up overflow
			ExitApp, -2
		}
	}
	prev() {
		; MsgBox, % A_ThisFunc
		this.ptr-=1
		if(this.ptr<0)
		{
			MsgBox, ptr down overflow
			ExitApp, -3
		}
	}
	print() {
		; MsgBox, % A_ThisFunc
		MsgBox, % chr(NumGet(this.ram, this.ptr,"UChar"))
	}
	get() {
		; MsgBox, % A_ThisFunc
	}
	loopstart() {
		local loopLevel
		; MsgBox, % A_ThisFunc
		if(NumGet(this.ram, this.ptr,"UChar")=0)
		{
			loopLevel:=this.loopLevel
			this.loopLevel+=1
			while(this.loopLevel!=loopLevel)
			{
				op:=NumGet(this.source, ++this.sptr,"UChar")
				if(op=91)
				{
					this.loopLevel+=1
				}
				Else if(op=93)
				{
					this.loopLevel-=1
				}
				if(this.sptr>0xFFFF)
				{
					MsgBox, sptr up overflow
					ExitApp, -4
				}
			}
		}
		Else
		{
			this.next()
		}
	}
	loopend() {
		local loopLevel
		; MsgBox, % A_ThisFunc
		if(NumGet(this.ram, this.ptr,"UChar")=0)
		{
			this.next()
		}
		Else
		{
			loopLevel:=this.loopLevel
			this.loopLevel-=1
			while(this.loopLevel!=loopLevel)
			{
				op:=NumGet(this.source, --this.sptr,"UChar")
				if(op=91)
				{
					this.loopLevel+=1
				}
				Else if(op=93)
				{
					this.loopLevel-=1
				}
				if(this.sptr<0)
				{
					MsgBox, sptr down overflow
					ExitApp, -5
				}
			}
		}
	}

}

F5::ExitApp
