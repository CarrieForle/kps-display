/*
 * Copyright (c) 2024 CarrieForle
 * This file is part of KPS Display.
 *
 * KPS Display is free software: you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation, either
 * version 3 of the License, or (at your option) any later version.
 *
 * KPS Display is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with KPS Display. If not, see <https://www.gnu.org/licenses/>.
 */

class Font
{
    typeface := ""
    weight := 400,
    italic := false
    underline := false
    strikethrough := false
    height := 12

    static Make(typeface, height, weight, italic, underline, strikethrough)
    {
        res := Font()
        
        res.typeface := typeface
        res.height := height
        res.weight := weight
        res.italic := italic
        res.underline := underline
        res.strikethrough := strikethrough

        return res
    }

    static from_config(style_str)
    {
        config_font := Font()
        is_weight_specified := false
        style_str := StrUpper(style_str)

        Loop Parse style_str, ",", A_Space A_Tab
        {
            match := true

            switch A_LoopField
            {
                case "BOLD":
                    if !is_weight_specified
                    {
                        config_font.weight := 700
                    }
                case "ITALIC":
                    config_font.italic := true
                case "STRIKE":
                    config_font.strikethrough := true
                case "UNDERLINE":
                    config_font.underline := true
                case "NORMAL":
                    if !is_weight_specified
                    {
                        config_font.weight := 400
                        config_font.underline := false
                        config_font.strikethrough := false
                        config_font.italic := false
                    }
                default:
                    match := false
            }

            if match
            {
                continue
            }

            if RegExMatch(A_LoopField, "^S(\d+)$", &match)
            {
                height := Integer(match[1])

                if height <= 0
                {
                    throw ValueError("Font size must be positive. Found " height)
                }

                config_font.height := height
            }
            else if RegExMatch(A_LoopField, "^W(\d+)$", &match)
            {
                weight := Integer(match[1])

                if weight <= 0 || weight > 1000
                {
                    throw ValueError("Font weight must be between 0 and 1000. Found " weight)
                }

                config_font.weight := weight
                is_weight_specified := true
            }
            else if A_LoopField
            {
                config_font.typeface := A_LoopField
            }
        }

        return config_font
    }

    to_config()
    {
        result := StrTitle(this.typeface) ", s" this.height
        
        switch this.weight
        {
            case 700:
                result .= ", bold"
            case 400:
                _ := 0
            default:
                result .= ", w" this.weight
        }

        if this.italic
        {
            result .= ", italic"
        }
        if this.underline
        {
            result .= ", underline"
        }
        if this.strikethrough
        {
            result .= ", strike"
        }

        return result
    }

    set(my_gui, color, quality := "Q2")
    {
        style := ""

        if this.italic
        {
            style .= "italic "
        }
        if this.strikethrough
        {
            style .= "strike "
        }
        if this.underline
        {
            style .= "underline "
        }

        my_gui.SetFont("norm " quality " " style "s" this.height " w" this.weight " c" color, this.typeface)
    }

    equal(other)
    {
        res := this.typeface = other.typeface &&
            this.weight = other.weight &&
            this.italic = other.italic &&
            this.underline = other.underline &&
            this.strikethrough = other.strikethrough &&
            this.height = other.height
        
        return res
    }
}
; https://learn.microsoft.com/en-us/windows/win32/api/wingdi/ns-wingdi-logfontw#members
_muldiv(a, b, c)
{
    return a * b // c
}

_rev_muldiv(muldiv, b, c)
{
    return muldiv * c // b
}

choose_font(owner_hwnd := 0, &output?)
{
    logfont := Buffer(91)
    dc := DllCall("GetDC", "Ptr", 0)
    LOGPIXELY := DllCall("GetDeviceCaps", "Ptr", dc, "Int", 90)

    if !DllCall("ReleaseDC", "Ptr", 0, "Ptr", dc)
    {
        MsgBox "Couldn't release Device Context. The program will be terminate.", "Fatal Error", 16
        ExitApp
    }
    font_height := -_muldiv(IsSet(output) ? output.height : 12, LOGPIXELY, 72)

    offset := NumPut(
        "Int", font_height,
        "Int", 0, ; width (idk)
        "Int", 0, ; escapement (idk)
        "Int", 0, ; orientation (idk)
        "Int", IsSet(output) ? output.weight : 0,
        "UChar", IsSet(output) ? output.italic : 0,
        "UChar", IsSet(output) ? output.underline : 0,
        "UChar", IsSet(output) ? output.strikethrough : 0,
        "UChar", 0, ; not used
        "UChar", 0, ; not used
        "UChar", 0, ; not used
        "UChar", 0, ; not used
        "UChar", 0, ; not used
        logfont
    ) - logfont.Ptr

    if IsSet(output)
    {
        before_offset := offset
        written_bytes := StrPut(output.typeface, logfont.Ptr + offset, , "UTF-16")
        NumPut("Char", 0, logfont.ptr + offset + written_bytes)
        written_bytes++
    }

    if A_PtrSize = 8
    { 
        tag_choose_font := Buffer(104)

        NumPut "UInt", tag_choose_font.Size,
            "Int", 0, ; padding
            "Ptr", owner_hwnd,
            "Ptr", 0, ; not used
            "Ptr", logfont.Ptr, 
            "Int", 0, ; return font size
            ; CF_INACTIVEFONTS, CF_FORCEFONTEXIST, CF_NOSCRIPTSEL, CF_NOVERTFONTS, CF_INITTOLOGFONTSTRUCT
            "UInt", 0x03810040, ; flags
            "UInt", 0, ; not used
            "Int", 0, ; padding
            "Ptr", 0, ; not used
            "Ptr", 0, ; not used
            "Ptr", 0, ; not used
            "Ptr", 0, ; not used
            "Ptr", 0, ; not used
            "UShort", 0, ; return font style (duplicate of logfont fields)
            "UShort", 0, ; __MISSING_ALIGNMENT__ (WTF does that mean?)
            "Int", 0, ; min font pt (not used)
            "Int", 0, ; max font pt (not used)
            "Int", 0, ; padding
            tag_choose_font
    }
    ; TODO: Test on 32-bit
    else
    {
        tag_choose_font := Buffer(92)

        NumPut "UInt", tag_choose_font.Size,
            "Ptr", owner_hwnd,
            "Ptr", 0,
            "Ptr", logfont.Ptr,
            "Int", 0,
            "UInt", 0x03810040,
            "UInt", 0,
            "Ptr", 0,
            "Ptr", 0,
            "Ptr", 0,
            "Ptr", 0,
            "Ptr", 0,
            "UShort", 0,
            "UShort", 0,
            "Int", 0,
            "Int", 0,
            tag_choose_font
    }

    result := DllCall("Comdlg32\ChooseFont", "Ptr", tag_choose_font, "Cdecl")

    if !result
    {
        if errno := DllCall("Comdlg32\CommDlgExtendedError")
        {
            MsgBox Format("Error: 0x{:x}`nFont is not chosen.", errno), "Error", 16
        }

        return output ?? Font()
    }

    height := -_rev_muldiv(NumGet(logfont, "Int"), LOGPIXELY, 72)
    weight := NumGet(logfont, 16, "Int")
    italic := NumGet(logfont, 20, "UChar") ? true : false ; originally return 255 or 0
    ; underline := NumGet(logfont, 21, "UChar")
    ; strikethrough := NumGet(logfont, 22, "UChar")
    typeface := StrGet(logfont.ptr + 28, , "UTF-16")

    return output := Font.Make(typeface, height, weight, italic, output.underline, output.strikethrough)
}