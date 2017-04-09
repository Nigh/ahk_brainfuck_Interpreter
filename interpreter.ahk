#SingleInstance Force

debug:=0

if debug
{
	path:="F:\github\ahk_brainfuck_Interpreter\primes.bf"
}
Else
{
	if(A_Args.Length()<=0){
		Msgbox, drop file on it, Please.
		ExitApp, -5
	}

	path:=A_Args[1]
	if !FileExist(path)
	{
		Msgbox, drop file on it, Please.
		ExitApp, -4
	}
}

hFile:=FileOpen(path,"r")
if !hFile
{
	MsgBox, [%GetLastError()%]Something goes wrong while trying open the source file.
	ExitApp, -3
}

Gui, -Owner +Caption hwndgui_id
Gui, Add, Edit, w640 r40 -Wrap Multi readonly +Disabled vediter hwndhEdit1,
Gui, Add, Edit, w600 r1 vinput disabled hwndhInput1,
gui, Add, button, x+5 w35 gsend vbt disabled Default, \n
gui, show,, brainfuck

source:=""
VarSetCapacity, _, source, 0xFFFF, 0

while(!hFile.AtEOF){
	translate(hFile.ReadUChar())
}

DllCall("QueryPerformanceFrequency", "Int64*", clock)
printBuffer:=""
_ptr:=1
_ram:=Object()
loop, 32768
_ram.Push(0)
scode:="
(
; _ptr:=1
; _ram:=Object()
; loop, 32768
; _ram.Push(0)
)"
DllCall("QueryPerformanceCounter", "Int64*", CounterBefore)
compile2ahk()
; Clipboard:=scode
; msgbox(scode)
SetTimer, print, 1000
inputTimeAdj:=0
ahkExec(scode)
DllCall("QueryPerformanceCounter", "Int64*", CounterAfter)
SetTimer, print, Off
Gosub, print
gui, show,, % "complete in " (inputTimeAdj + CounterAfter - CounterBefore)/clock "s"
Return

print:
if printBuffer=""
Return
GuiControl, -Redraw -Disabled, ahk_id %hEdit1%
printBuffer := StrReplace(printBuffer, "`n", "`r`n")
Control, EditPaste, % printBuffer,, ahk_id %hEdit1%
printBuffer:=""
GuiControl, +Redraw +Disabled, ahk_id %hEdit1%
Return

send:
GuiControl,, input, `n
Control, EditPaste, `r`n,, ahk_id %hEdit1%
Return

guiclose:
ExitApp

_get() {
	global
	DllCall("QueryPerformanceCounter", "Int64*", CounterAfter)
	inputTimeAdj+=CounterAfter - CounterBefore
	GuiControl, -Disabled, input
	GuiControl, -Disabled, bt
	sleep 10
	GuiControl, Focus, input
	gui, show,, Wait for input ...
	loop
	{
		sleep, 50
		GuiControlGet, txt1,, input
		if(txt1!="")
		{
			_ram[_ptr]:=Ord(txt1)&0xFF
			Control, EditPaste, % chr(_ram[_ptr]),, ahk_id %hEdit1%
			GuiControl,,input,
			GuiControl,+Disabled,input,
			GuiControl,+Disabled, bt
			gui, show,, brainfuck
			break
		}
	}
	DllCall("QueryPerformanceCounter", "Int64*", CounterBefore)
}

translate(byte)
{
	global
	if(InStr("+-<>.,[]", chr(byte)))
	{
		NumPut(byte, source, sptr++,"UChar")
		if(sptr>0xFFFF)
		{
			MsgBox, Program larger than 65535. Exit for safe.
			ExitApp, -1
		}
	}
}

compile2ahk()
{
	global
	local statu:=NumGet(&source,0,"UChar")
	local cnt:=0
	loop
	{
		op:=NumGet(&source,A_Index-1,"UChar")
		if op=Ord("+") and statu=op
		{
			cnt+=1
		}
		else if op=Ord("-") and statu=op
		{
			cnt+=1
		}
		else if op=Ord(">") and statu=op
		{
			cnt+=1
		}
		else if op=Ord("<") and statu=op
		{
			cnt+=1
		}
		else if cnt!=0
		{
			; msgbox(scode "," statu "," cnt)
			if statu=0
				Return
			if statu=Ord(">")
				scode.="`r`n_ptr+=" cnt
			else if statu=Ord("<")
				scode.="`r`n_ptr-=" cnt
			else if statu=Ord("+")
			{
				while(cnt>256)
					cnt-=256
				scode.="`r`n_ram[_ptr]:=(_ram[_ptr]+" cnt ")&0xFF"
			}
			else if statu=Ord("-")
			{
				while(cnt>256)
					cnt-=256
				scode.="`r`n_ram[_ptr]:=(_ram[_ptr]+256-" cnt ")&0xFF"
			}
			else if statu=Ord("[")
			{
				scode.="`r`nwhile(_ram[_ptr]!=0)`r`n{"
			}
			else if statu=Ord("]")
			{
				scode.="`r`n}"
			}
			Else if statu=Ord(".")
			{
				; MsgBox(A_Index "," statu "," op)
				scode.="`r`nprintBuffer.=Chr(_ram[_ptr])"
			}
			Else if statu=Ord(",")
			{
				scode.="`r`nGosub, print"
				scode.="`r`n_get()"
			}
			statu:=op
			cnt:=1
			if op=0
				Return
		}
		Else
		{
			statu:=op
			cnt:=1
		}
	}
}
