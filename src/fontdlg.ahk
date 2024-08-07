#SingleInstance,Force
name := "Tahoma" ;Default selected font
style := { size: 14, color: 0xFF0000, strikeout: 1, underline: 1, italic: 1, bold: 1 } ;Set the style information Italic,Bold,Strikeout,and Underline are not necessary unless you want them pre-selected and order is not important
Gui, +hwndhwnd
Gui, Add, Edit, w500 h200 hwndedit, Sample Text
Gui, Add, Edit, w500 h200 hwndedit1, Sample Text
Gui, Add, Button, gfont Default, Change Font
Gui, Show, , Change Font Example
return
font:
    if !font := Dlg_Font(name, style, hwnd) ;shows the user the font selection dialog
        ;to get information from the style object use ( bold:=style.bold ) or ( underline:=style.underline )...
        return
    Gui, font, %"c" RGB(style.color)
    GuiControl, font, Edit1
    GuiControl, font, Edit2
    SendMessage, 0x30, font, 1, , ahk_id%Edit%
    SendMessage, 0x30, font, 1, , ahk_id%Edit1%
    return
    ;to get any of the style return values : value:=style.bold will get you the bold value and so on
    Dlg_Font(ByRef Name, ByRef Style, hwnd = "", effects = 1) {
        static logfont
        VarSetCapacity(logfont, 60), LogPixels := DllCall("GetDeviceCaps", "uint", DllCall("GetDC", "uint", 0), "uint", 90), Effects := 0x041 + (Effects ? 0x100 : 0)
        for a, b in fontval := { 16: style.bold ? 700 : 400, 20: style.italic, 21: style.underline, 22: style.strikeout, 0: style.size ? Floor(style.size * logpixels / 72) : 16 }
            NumPut(b, logfont, a)
        cap := VarSetCapacity(choosefont, A_PtrSize = 8 ? 103 : 60, 0)
        NumPut(hwnd, choosefont, A_PtrSize)
        for index, value in [[cap, 0, "Uint"], [&logfont, A_PtrSize = 8 ? 24 : 12, "Uptr"], [effects, A_PtrSize = 8 ? 36 : 20, "Uint"], [style.color, A_PtrSize = 4 ? 6 * A_PtrSize : 5 * A_PtrSize, "Uint"]]
            NumPut(value.1, choosefont, value.2, value.3)
        if (A_PtrSize = 8)
            strput(name, &logfont + 28), r := DllCall("comdlg32\ChooseFont", "uptr", &CHOOSEFONT, "cdecl"), name := strget(&logfont + 28)
        else
            strput(name, &logfont + 28, 32, "utf-8"), r := DllCall("comdlg32\ChooseFontA", "uptr", &CHOOSEFONT, "cdecl"), name := strget(&logfont + 28, 32, "utf-8")
        if !r
            return 0
        for a, b in { bold: 16, italic: 20, underline: 21, strikeout: 22 }
            style[a] := NumGet(logfont, b, "UChar")
        style.bold := style.bold < 188 ? 0 : 1
        style.color := NumGet(choosefont, A_PtrSize = 4 ? 6 * A_PtrSize : 5 * A_PtrSize)
        style.size := NumGet(CHOOSEFONT, A_PtrSize = 8 ? 32 : 16, "UChar") // 10
        ;charset:=NumGet(logfont,23,"UChr")
        return DllCall("CreateFontIndirect", uptr, &logfont, "cdecl")
    }
    rgb(c) {
        setformat, IntegerFast, H
        c := (c & 255) << 16 | (c & 65280) | (c >> 16), c := SubStr(c, 1)
        SetFormat, integerfast, D
        return c
    }
GuiClose:
GuiEscape:
    ExitApp
    return