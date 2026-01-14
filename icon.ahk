#Requires AutoHotkey v2.0
MyGui := Gui(, "图标查看器 - 点击编号复制")
LV := MyGui.Add("ListView", "r20 w300", ["编号", "图标"])
ImageListID := IL_Create(100, 10, true) ; 预设图标列表
LV.SetImageList(ImageListID)

; 加载 imageres.dll 中的前 300 个图标
Loop 300 {
    IL_Add(ImageListID, "imageres.dll", A_Index)
    LV.Add("Icon" . A_Index, A_Index)
}

LV.OnEvent("Click", (LV, RowNumber) => (A_Clipboard := LV.GetText(RowNumber), MsgBox("编号 " A_Clipboard " 已复制")))
MyGui.Show()