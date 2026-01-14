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

; 定义临时目录 (用于释放托盘图标)
global ICON_DIR := A_Temp "\GlobalVimAssets\"

; 确保目录存在
if !DirExist(ICON_DIR)
    DirCreate(ICON_DIR)

; ==========================================================
; 2. 资源打包 (修复 EXE 移动后托盘图标丢失问题)
; ==========================================================
; 只用于托盘显示的图标，必须打包
try {
    FileInstall("icon\assets\arrows.ico", ICON_DIR "arrows.ico", 1)
    FileInstall("icon\assets\selection.ico", ICON_DIR "selection.ico", 1)
    FileInstall("icon\assets\pencil.ico", ICON_DIR "pencil.ico", 1)
} catch {
    ; 开发模式下跳过错误
}

; 注册退出钩子：确保脚本关闭时恢复鼠标
OnExit(RestoreCursorAndExit)

; 初始更新状态
UpdateStatus()

; ==========================================================
; 3. 状态更新 (使用 Windows 原生系统光标)
; ==========================================================
UpdateStatus(msg := "") {
    ; Windows 系统光标 ID:
    ; 32512 = 标准箭头 (Normal)
    ; 32513 = 工字标 (I-Beam)
    ; 32646 = 四向移动 (SizeAll) -> 用于 Normal 模式
    ; 32515 = 十字准星 (Cross)   -> 用于 Visual 模式
    
    if (IsNavMode) {
        if (IsShiftSticky) {
            ; 【Visual 模式】(默认状态)
            TrySetModeIcon(ICON_DIR "selection.ico", "🔥 Visual Mode (选中)")
            ChangeSystemCursor(32515) ; 十字准星
        } else {
            ; 【Normal 模式】(按 v 切换)
            TrySetModeIcon(ICON_DIR "arrows.ico", "💡 Normal Mode (移动)")
            ChangeSystemCursor(32646) ; 移动图标
        }
    } else {
        ; 【编辑模式】
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
; 4. 系统光标控制 (Windows API)
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
; 5. 辅助功能 (Typeout / TabOut)
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
    ; 1. 如果在导航模式，直接发 Tab
    if (IsNavMode) {
        Send("{Tab}")
        return
    }

    ; 2. 【修复终端冲突】如果是终端窗口，直接发 Tab，不执行跳出检测
    ; ConsoleWindowClass = CMD / PowerShell (Legacy)
    ; CASCADIA_HOSTING_WINDOW_CLASS = Windows Terminal
    if (WinActive("ahk_class ConsoleWindowClass") || WinActive("ahk_class CASCADIA_HOSTING_WINDOW_CLASS")) {
        Send("{Tab}")
        return
    }

    ; 3. 常规编辑器中的跳出逻辑
    savedClip := ClipboardAll()
    A_Clipboard := ""
    Send("+{Right}^c")
    if ClipWait(0.05) {
        char := A_Clipboard
        targetChars := ')]}">;,`'' 
        if (char != "" && InStr(targetChars, char)) {
            Send("{Right}")
        } else {
            Send("{Left}{Tab}")
        }
    } else {
        Send("{Left}{Tab}")
    }
    A_Clipboard := savedClip
}

; ==========================================================
; 6. 模式切换逻辑
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
        ; 【核心设置】默认开启 Visual Mode (选中模式)
        global IsShiftSticky := true  
        global HasMoved := false  
        UpdateStatus() 
    } else {
        ExitNav(HasMoved ? true : false) 
    }
}

; ==========================================================
; 7. 导航模式按键绑定
; ==========================================================
#HotIf IsNavMode

; --- HJKL 移动 ---
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

; --- 功能键 ---
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

; --- 拦截与警告 ---
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

; --- 核心操作符 ---
d:: {
    global HasMoved 
    if (HasMoved) {
        Send("{Del}")
        ExitNav(false)
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
        Send("+{End}{BackSpace}{Delete}")
        ExitNav(false) 
    } else if (ih.Input == "w") { 
        Send("^{Del}")
        ExitNav(false)
    } else if (ih.Input == "b") { 
        Send("^{BackSpace}")
        ExitNav(false)
    } else {
        UpdateStatus() 
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

; --- 其他动作 ---
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
        ; 【逻辑修复】从 Visual 切换到 Normal 时：
        ; 释放 Shift 并向右一格，取消当前选区，回到纯移动状态
        Send("{Shift Up}{Right}")
    }
    ; 从 Normal 切换到 Visual 时：
    ; 什么都不用做，下一按移动键会自动带上 Shift
    
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

; ==========================================================
; 8. 全局组合键
; ==========================================================
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