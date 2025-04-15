#Requires AutoHotkey v2.0
#include Array.ahk
#include DPI.ahk
; 实现窗口平滑移动，越小越平滑，最小为-1
SetWinDelay(5)

; 隐藏时留出的长度以及显示时距离屏幕边缘的长度
; 由于DPI关系，margin设置，不同DPI可能不同
margin := 10
showMargin := 0
global margin
global showMargin
; 移动范围
moveDistance := 30
global moveDistance

; 隐藏的窗口
hiddenWindowList := []
global hiddenWindowList
; 中间态窗口，鼠标放置暂时显示的窗口
suspendWindowList := []
global suspendWindowList

maxHeight := 800

; 设置托盘图标
TraySetIcon("./assest/自动贴边.png")
; 加入右键菜单
myMenu := A_TrayMenu
myMenu.Delete()
myMenu.Add("重置所有贴边窗口", Reset)
myMenu.SetIcon("重置所有贴边窗口", "imageres.dll", 230)
myMenu.Add("退出", (*) => ExitApp())
myMenu.SetIcon("退出", "imageres.dll", 231)


Reset(*){
	results := getSide()
	leftMonitor := results[1]
	rightMonitor := results[2]
	leftEdge := results[3]
	rightEdge := results[4]
	MonitorGet leftMonitor,,&leftTopEdge
	MonitorGet rightMonitor,,&rightTopEdge
	leftDPI := getDPI(leftMonitor)
	rightDPI := getDPI(rightMonitor)
	; 多显示器支持
	global leftEdge
	global rightEdge
	global leftTopEdge
	global rightTopEdge
	global leftDPI
	global rightDPI

	hiddenLength := hiddenWindowList.Length
	Loop hiddenLength {
		window := hiddenWindowList.Get(hiddenWindowList.Length)
		hiddenWindowList.RemoveAt(hiddenWindowList.Length)
		WinMove(showMargin+leftEdge,showMargin+leftTopEdge,,,"ahk_id" window.id)
		WinSetAlwaysOnTop(0,"ahk_id" window.id)
	}
	suspendLength := suspendWindowList.Length
	Loop suspendLength {
		suspendWindowList.RemoveAt(suspendWindowList.Length)
	}

}



SetTimer WatchCursor, 200

WatchCursor(){
	; DPI.MouseGetPos 某些时候会出错
	Try{
		DPI.MouseGetPos , , &ahkId, &control
	    ; 判断是否为中间态，是则不需要移动
	    suspendWindowIndex := suspendWindowList.Find((v) => (v.id =ahkId))
	    if suspendWindowIndex > 0{
	    	;拖动窗口去除隐藏
	    	window := suspendWindowList.Get(suspendWindowIndex)
	    	if (isWindowMove(window)=1){
	    		hiddenWindowIndex := hiddenWindowList.Find((v) => (v.id =ahkId))
	    		hiddenWindowList.RemoveAt(hiddenWindowIndex)
	    		suspendWindowList.RemoveAt(suspendWindowIndex)
	    		WinSetAlwaysOnTop(0,"ahk_id" ahkId)
	    	}
	    }
	    else{
	    	; 不为中间态时，则若为其他隐藏窗口则不隐藏，接着判断是否为隐藏的窗口
		    hiddenWindowIndex := hiddenWindowList.Find((v) => (v.id =ahkId))
		    ; 隐藏窗口则显示
		    if hiddenWindowIndex>0 {
		    	window := hiddenWindowList.Get(hiddenWindowIndex)
		    	showWindow(window)
		    }
		    else{
		    	;按顺序隐藏
		    	if suspendWindowList.Length > 0{
		    		suspendWindow := suspendWindowList.Get(suspendWindowList.Length)
			    	suspendWindowList.RemoveAt(suspendWindowList.Length)
			    	hideWindow(suspendWindow)
	    		} 
		    }
	    }

	    ; else{
	    ; 	; 不为中间态时，则直接隐藏，接着判断是否为隐藏的窗口
		;     isHidden := hiddenWindowList.Find((v) => (v =id))
		;     ; 切换到其他窗口继续隐藏
	    ; 	if suspendWindowList.Length > 0{
	    ; 		suspendId := suspendWindowList.Get(1)
		;     	suspendWindowList.RemoveAt(1)
		;     	hideWindow(suspendId)
	    ; 	} 
		;     ; 隐藏窗口则显示
		;     if isHidden>0 {
		;     	showWindow(id)
		;     }
	    ; }
	}
}



#!Left::{
	results := getSide()
	leftMonitor := results[1]
	rightMonitor := results[2]
	leftEdge := results[3]
	rightEdge := results[4]
	MonitorGet leftMonitor,,&leftTopEdge
	MonitorGet rightMonitor,,&rightTopEdge
	leftDPI := getDPI(leftMonitor)
	rightDPI := getDPI(rightMonitor)
	; 多显示器支持
	global leftEdge
	global rightEdge
	global leftTopEdge
	global rightTopEdge
	global leftDPI
	global rightDPI

	ahkId := WinGetID("A")
	hiddenWindowIndex := hiddenWindowList.Find((v) => (v.id =ahkId))
	suspendWindowIndex := suspendWindowList.Find((v) => (v.id =ahkId))
	if hiddenWindowIndex >0 {
		hiddenWindowList.RemoveAt(hiddenWindowIndex)
	}
	if suspendWindowIndex > 0{
		suspendWindowList.RemoveAt(suspendWindowIndex)
	}
	hideWindow({id:ahkId,mode:"left"})
}

#!Right::{
	results := getSide()
	leftMonitor := results[1]
	rightMonitor := results[2]
	leftEdge := results[3]
	rightEdge := results[4]
	MonitorGet leftMonitor,,&leftTopEdge
	MonitorGet rightMonitor,,&rightTopEdge
	leftDPI := getDPI(leftMonitor)
	rightDPI := getDPI(rightMonitor)
	; 多显示器支持
	global leftEdge
	global rightEdge
	global leftTopEdge
	global rightTopEdge
	global leftDPI
	global rightDPI

	ahkId := WinGetID("A")
	;判断当前窗口是否已经隐藏，若已存在则删除
	hiddenWindowIndex := hiddenWindowList.Find((v) => (v.id =ahkId))
	suspendWindowIndex := suspendWindowList.Find((v) => (v.id =ahkId))
	if hiddenWindowIndex >0 {
		hiddenWindowList.RemoveAt(hiddenWindowIndex)
	}
	if suspendWindowIndex > 0{
		suspendWindowList.RemoveAt(suspendWindowIndex)
	}
	hideWindow({id:ahkId,mode:"right"})
	
}

^!r::{
	Reset()
}


hideWindow(window){
	
	windowText := "ahk_id" window.id

	;最大化窗口不可隐藏
	if WinExist(windowText) and WinGetMinMax(windowText) != 1{
		DPI.WinGetPos(&X, &Y, &W, &H,windowText)
		; 乘以dpi 使用DPI缩放
		mode := window.mode
		if mode="left"{
			NewX := -Round(W*leftDPI)+leftEdge+Round(margin*leftDPI)
			Y :=Max(Y,leftTopEdge)
		}
		else if mode="right"{
			NewX := rightEdge-Round(margin*rightDPI)
			Y :=Max(Y,rightTopEdge)
		}
		
		if H>maxHeight{
			WinMove(,Y,,H,windowText)
		}
		winSmoothMove(newX,Y,windowText)
		WinSetAlwaysOnTop(1, windowText)
		pushTo(hiddenWindowList,window)
	}
}

showWindow(window){
	windowText := "ahk_id" window.id
	mode := window.mode
	DPI.WinGetPos(&X, &Y, &W, &H,windowText)
	if mode="left"{
		NewX := showMargin+leftEdge
	}
	else if mode="right"{
		NewX := rightEdge-Round(showMargin*rightDPI)-Round(W*rightDPI)+5
	}
	; WinMove(NewX, Y,,,window)
	winSmoothMove(newX,Y,windowText)
	pushTo(suspendWindowList,window)
}
isWindowMove(window){
	windowText := "ahk_id" window.id
	mode := window.mode
	DPI.WinGetPos(&X, &Y, &W, &H,windowText)
	; 当窗口横坐标大于margin一定程度，认为移动
	if mode = "left"{
		if (X>Round(showMargin*leftDPI)+leftEdge+moveDistance){
			return 1
		}
		else{
			return 0
		}
	}
	else if mode="right"{
		if (X<rightEdge-moveDistance-Round(showMargin*rightDPI) - Round(W*rightDPI)){
			return 1
		}
		else{
			return 0
		}
	}
	
}
; 列表不允许存在相同的窗口
pushTo(array,value){
	if array.Find((v) => (v.id =value.id)) <= 0{
		array.push(value)
	}
}
;从a到b的数组
createArray(a, b,length) {
	; Calculate the step to divide the range into length parts
    arr := []
    step := (b - a) / (length-1)  
    value := a
    Loop length {
        arr.Push(Round(value))
        value += step  ; Increase each value by step
    }
    arr.Push(b)
    return arr
}
; 平滑移动
winSmoothMove(newX,newY,windowText){
	DPI.WinGetPos(&X,, ,, windowText)
	arr := createArray(X,NewX,10)
	for i,v in arr{
		WinMove(v,newY,,,windowText)
	}
}

;多显示器支持
;获取左右边界和显示器索引
getSide(){
	leftEdge := 1
	rightEdge := -1
	leftMonitor :=0
	rightMonitor :=0
	i:=1
	while i<=MonitorGetCount(){
		MonitorGet i, &leftEdgeTemp,,&rightEdgeTemp
		if leftEdge > leftEdgeTemp{
			leftEdge := leftEdgeTemp
			leftMonitor := i
		}
		if rightEdge<rightEdgeTemp{
			rightEdge:=rightEdgeTemp
			rightMonitor:=i
		}
		i+=1
	}
	return [leftMonitor,rightMonitor,leftEdge,rightEdge]
}

getDPI(monitorIndex){
	monitorHandles := DPI.GetMonitorHandles()
	dpiValue := DPI.GetForMonitor(monitorHandles.Get(monitorIndex))
	dpiValue := dpiValue / 96
	return dpiValue
}

