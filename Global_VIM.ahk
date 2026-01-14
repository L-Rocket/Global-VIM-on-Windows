#Requires AutoHotkey v2.0
#SingleInstance Force

; ==========================================================
; 1. 初始化与全局变量
; ==========================================================
SetCapsLockState "AlwaysOff"
global IsNavMode := false
global IsShiftSticky := false
global HasMoved := false 
global IsHookActive := false 

global ICON_DIR := A_Temp "\GlobalVimAssets\"
if !DirExist(ICON_DIR)
    DirCreate(ICON_DIR)

; ==========================================================
; 2. 资源打包
; ==========================================================
try {
    FileInstall("icon\assets\arrows.ico", ICON_DIR "arrows.ico", 1)
    FileInstall("icon\assets\selection.ico", ICON_DIR "selection.ico", 1)
    FileInstall("icon\assets\pencil.ico", ICON_DIR "pencil.ico", 1)
} catch {
}

OnExit(RestoreCursorAndExit)
UpdateStatus()

; ==========================================================
; 3. 状态更新
; ==========================================================
UpdateStatus(msg := "") {
    if (IsNavMode) {
        if (IsShiftSticky) {
            TrySetModeIcon(ICON_DIR "selection.ico", "🔥 Visual Mode (选中)")
            ChangeSystemCursor(32515) 
        } else {
            TrySetModeIcon(ICON_DIR "arrows.ico", "💡 Normal Mode (移动)")
            ChangeSystemCursor(32646) 
        }
    } else {
        TrySetModeIcon(ICON_DIR "pencil.ico", "模式: 编辑")
        RestoreSystemCursor()
        ToolTip() 
    }
}

TrySetModeIcon(iconPath, tipText) {
    if FileExist(iconPath) {
        TraySetIcon(iconPath)
    } else {
        TraySetIcon("*") 
    }
    A_IconTip := tipText
}

; ==========================================================
; 4. 光标控制
; ==========================================================
ChangeSystemCursor(CursorID) {
    CursorHandle := DllCall("LoadCursor", "Ptr", 0, "Int", CursorID, "Ptr")
    DllCall("SetSystemCursor", "Ptr", DllCall("CopyImage", "Ptr", CursorHandle, "Int", 2, "Int", 0, "Int", 0, "Int", 0, "Ptr"), "Int", 32512)
    DllCall("SetSystemCursor", "Ptr", DllCall("CopyImage", "Ptr", CursorHandle, "Int", 2, "Int", 0, "Int", 0, "Int", 0, "Ptr"), "Int", 32513)
}

RestoreSystemCursor() {
    DllCall("SystemParametersInfo", "Int", 0x0057, "Int", 0, "Ptr", 0, "Int", 0)
}

RestoreCursorAndExit(*) {
    RestoreSystemCursor()
    ExitApp
}

; ==========================================================
; 5. 辅助功能
; ==========================================================
TypeOut(text, minDelay := 20, maxDelay := 60) {
    if (text == "") 
        return
    Send("{Shift}") 
    Sleep(50)
    Loop Parse, text {
        Send("{Blind}" A_LoopField)
        Sleep(Random(minDelay, maxDelay))
    }
}

$Tab:: {
    Send("{Tab}")
}

; ==========================================================
; 6. 模式切换
; ==========================================================
ExitNav(shouldCollapse := true) {
    global IsNavMode := false
    global IsShiftSticky := false
    global IsHookActive := false
    
    Send("{Shift Up}{Ctrl Up}") 
    Sleep(20)
    
    if (shouldCollapse && HasMoved) {
        Send("{Left}") 
    }
    
    global HasMoved := false
    UpdateStatus() 
}

CapsLock::
{
    global IsNavMode := !IsNavMode
    if (IsNavMode) {
        global IsShiftSticky := true  
        global HasMoved := false  
        UpdateStatus() 
    } else {
        ExitNav(HasMoved ? true : false) 
    }
}

; ==========================================================
; 7. 导航按键绑定
; ==========================================================
#HotIf IsNavMode

*i:: {
    global HasMoved := true
    Send("{Blind}" (IsShiftSticky ? "+" : "") "{Up}")
}
*k:: {
    global HasMoved := true
    Send("{Blind}" (IsShiftSticky ? "+" : "") "{Down}")
}
*j:: {
    global HasMoved := true
    Send("{Blind}" (IsShiftSticky ? "+" : "") "{Left}")
}
*l:: {
    global HasMoved := true
    Send("{Blind}" (IsShiftSticky ? "+" : "") "{Right}")
}
*u:: {
    global HasMoved := true
    Send("{Blind}" (IsShiftSticky ? "+" : "") "{Home}")
}
*o:: {
    global HasMoved := true
    Send("{Blind}" (IsShiftSticky ? "+" : "") "{End}")
}

h:: {
    global HasMoved := true 
    Send("{Shift Up}{Home 2}") 
    Sleep(20)
    Send("+{End}") 
    UpdateStatus()
}
w:: {
    global HasMoved := true
    Send(IsShiftSticky ? "^+{Right}" : "^{Right}")
    UpdateStatus()
}
b:: {
    global HasMoved := true
    Send(IsShiftSticky ? "^+{Left}" : "^{Left}")
    UpdateStatus()
}
t:: {
    content := A_Clipboard
    ExitNav(false)
    TypeOut(content)
}

a::
e::
f::
g::
m::
p:: 
q::
s::
r:: 
{
    UpdateStatus("⚠️ 模式锁定")
}

; --- 核心操作符 (DH 暴力修复版) ---
d:: {
    global IsHookActive := true 
    UpdateStatus("⏳ d- (指令...)")
    
    ih := InputHook("L1 T0.3", "{Esc}{CapsLock}")
    ih.Start(), ih.Wait()
    global IsHookActive := false 
    
    if (ih.Input == "h") {
        ; [dh] 删行
        Send("{Shift Up}")   ; 安全措施：先弹起 Shift
        Send("{Home 2}")     ; 1. 确保在行首
        Send("+{Down}")      ; 2. 选中当前行
        Sleep(10)            ;    稍微等一下选中生效
        Send("+{Del}")       ; 3. Shift + Del (执行剪切/删除)
        Send("{BackSpace}")  ; 4. 暴力补刀：如果留了空行，BackSpace 会把它删掉
        ExitNav(false) 
        
    } else if (ih.Input == "w") { 
        ; [dw] 删除词
        Send("^{Del}")
        ExitNav(false)
    } else if (ih.Input == "b") { 
        ; [db] 删除前词
        Send("^{BackSpace}")
        ExitNav(false)
    } else {
        ; 超时未输入指令 -> 检查是否有选区
        global HasMoved
        if (HasMoved) {
            Send("{Del}")
            ExitNav(false)
        } else {
            UpdateStatus() 
        }
    }
}

c:: {
    global HasMoved
    if (HasMoved) {
        Send("^c")
        ExitNav(true)
        return
    }
    global IsHookActive := true
    UpdateStatus("⏳ 等待指令...")
    ih := InputHook("L1 T0.5", "{Esc}{CapsLock}")
    ih.Start(), ih.Wait()
    global IsHookActive := false
    
    if (ih.Input == "h") {
        Send("{Shift Up}{Home 2}")
        Sleep(20)
        Send("+{End}^c")
        ExitNav(true) 
    } else if (ih.Input == "w") { 
        Send("{Shift Up}^+{Right}^c")
        ExitNav(true)
    } else if (ih.Input == "b") { 
        Send("{Shift Up}^+{Left}^c")
        ExitNav(true)
    } else {
        UpdateStatus()
    }
}

y::
^c:: {
    Send("^c")
    Sleep(100)
    ExitNav(true)
}

x::
^x:: {
    Send("^x")
    ExitNav(false)
}

v:: {
    global IsShiftSticky := !IsShiftSticky
    global HasMoved := false 
    
    if (!IsShiftSticky) {
        Send("{Shift Up}{Right}")
    }
    UpdateStatus() 
}

n:: {
    Send("{End}{Enter}")
    ExitNav(false)
}

z:: { 
    Send("^z")
    ExitNav(false)
}

Esc::ExitNav(true)

#HotIf

CapsLock & i::Send("{Blind}{Up}")
CapsLock & k::Send("{Blind}{Down}")
CapsLock & j::Send("{Blind}{Left}")
CapsLock & l::Send("{Blind}{Right}")
CapsLock & u::Send("{Blind}{Home}")
CapsLock & o::Send("{Blind}{End}")

^i::Send(IsNavMode && IsShiftSticky ? "+{Up 5}" : "{Up 5}")
^k::Send(IsNavMode && IsShiftSticky ? "+{Down 5}" : "{Down 5}")
^j::Send(IsNavMode && IsShiftSticky ? "^+{Left}" : "^{Left}")
^l::Send(IsNavMode && IsShiftSticky ? "^+{Right}" : "^{Right}")

+CapsLock::CapsLock