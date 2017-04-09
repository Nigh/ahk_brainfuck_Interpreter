#SingleInstance Force

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
hFile:=FileOpen(path,"r")
if !hFile
{
	MsgBox, [%GetLastError()%]Something goes wrong while trying open the source file.
	ExitApp, -3
}

Gui, -Owner +Caption hwndgui_id
Gui, Add, Edit, w640 r40 -Wrap Multi readonly vediter hwndhEdit1,
Gui, Add, Edit, w600 r1 vinput disabled hwndhInput1,
gui, Add, button, x+5 w35 gsend vbt disabled Default, \n
gui, show,, brainfuck

ram:=""
source:=""
VarSetCapacity, _, ram, 0xFFFF, 0
VarSetCapacity, _, source, 0xFFFF, 0

ptr:=0
sptr:=0
glooplevel:=0
funcArr:=Object()
funcArr[43]:=Func("plus")
funcArr[45]:=Func("minus")
funcArr[60]:=Func("prev")
funcArr[62]:=Func("next")
funcArr[46]:=Func("print")
funcArr[44]:=Func("get")
funcArr[91]:=Func("loopstart")
funcArr[93]:=Func("loopend")

while(!hFile.AtEOF){
	translate(hFile.ReadUChar())
}
pc_reset()
DllCall("QueryPerformanceFrequency", "Int64*", clock)
printBuffer:=""
SetTimer, print, 1000
inputTimeAdj:=0
DllCall("QueryPerformanceCounter", "Int64*", CounterBefore)
while(1)
{
	if(interpret())
	break
}
DllCall("QueryPerformanceCounter", "Int64*", CounterAfter)
SetTimer, print, -1
gui, show,, % "complete in " (inputTimeAdj + CounterAfter - CounterBefore)/clock "s"
Return

print:
if(printBuffer="")
Return
GuiControl, -Redraw, ahk_id %hEdit1%
Control, EditPaste, % printBuffer,, ahk_id %hEdit1%
printBuffer:=""
GuiControl, +Redraw, ahk_id %hEdit1%
Return

send:
GuiControl,, input, `n
Control, EditPaste, `r`n,, ahk_id %hEdit1%
Return

guiclose:
ExitApp

plus() {
	global
	NumPut((NumGet(ram, ptr,"UChar")+0x01)&0xFF,ram, ptr,"UChar")
	sptr++
}
minus() {
	global
	NumPut((NumGet(ram, ptr,"UChar")+0xFF)&0xFF,ram, ptr,"UChar")
	sptr++
}
next() {
	global
	ptr+=1
	if(ptr>0xFFFF)
	{
		MsgBox, ptr up overflow
		ExitApp, -2
	}
	sptr++
}
prev() {
	global
	ptr-=1
	if(ptr<0)
	{
		MsgBox, ptr down overflow
		ExitApp, -3
	}
	sptr++
}
print() {
	global
	_:=chr(NumGet(ram, ptr,"UChar"))
	if(_="`n")
	_:="`r`n"
	printBuffer.=_
	sptr++
}
get() {
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
			NumPut(Ord(txt1)&0xFF,ram, ptr,"UChar")
			Control, EditPaste, % chr(Ord(txt1)&0xFF),, ahk_id %hEdit1%
			GuiControl,,input,
			GuiControl,+Disabled,input,
			GuiControl,+Disabled, bt
			gui, show,, brainfuck
			break
		}
	}
	DllCall("QueryPerformanceCounter", "Int64*", CounterBefore)
	sptr++
}

pc_reset()
{
	global
	sptr:=0
	ptr:=0
}

interpret()
{
	global
	if(sptr>0xFFFF)
	{
		MsgBox, % "Program End`nPtr=" ptr "`nsPtr=" sptr
		ExitApp, 0
	}
	op:=NumGet(source,sptr,"UChar")
	if(op=0)
		Return true
	funcArr[op].Call()
	return false
}

scode:=""
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

step() {
	global
	sptr+=1
	if(sptr>0xFFFF)
	{
		MsgBox, ptr up overflow
		ExitApp, -2
	}
}


loopstart() {
	global
	local loopLevel
	loopLevel:=gloopLevel
	gloopLevel+=1
	if(NumGet(ram, ptr,"UChar")=0)
	{
		while(gloopLevel!=loopLevel)
		{
			op:=NumGet(source, ++sptr,"UChar")
			if(op=91)
			{
				gloopLevel+=1
			}
			Else if(op=93)
			{
				gloopLevel-=1
			}
			if(sptr>0xFFFF)
			{
				MsgBox, sptr up overflow
				ExitApp, -4
			}
		}
	}
	Else
	{
		step()
	}
}
loopend() {
	global
	local loopLevel
	loopLevel:=gloopLevel
	gloopLevel-=1
	if(NumGet(ram, ptr,"UChar")=0)
	{
		step()
	}
	Else
	{
		while(gloopLevel!=loopLevel)
		{
			op:=NumGet(source, --sptr,"UChar")
			if(op=91)
			{
				gloopLevel+=1
			}
			Else if(op=93)
			{
				gloopLevel-=1
			}
			if(sptr<0)
			{
				MsgBox, sptr down overflow
				ExitApp, -5
			}
		}
	}
}
