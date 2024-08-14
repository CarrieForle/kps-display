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

class RGB
{
    r := 0
    g := 0
    b := 0

    __New(r, g, b)
    {
        if r > 255 || g > 255 || b > 255 || r < 0 || g < 0 || b < 0
        {
            throw ValueError("Invalid RGB")
        }

        this.r := Integer(r)
        this.g := Integer(g)
        this.b := Integer(b)
    }

    static from_int(color, is_from_win32 := true)
    {
        if is_from_win32
        {
            return RGB(
                color & 0xff,
                color >> 8 & 0xff,
                color >> 16 & 0xff
            )
        }
        else
        {
            return RGB(
                color >> 16 & 0xff,
                color >> 8 & 0xff,
                color & 0xff,
            )
        }
    }

    static from_config(rgb_str)
    {
        return RGB.from_string(rgb_str)
    }

    static from_string(rgb_str)
    {
        if "#" = SubStr(rgb_str, 1, 1)
        {
            rgb_str := "0x" SubStr(rgb_str, 2)
        }
        else if "0x" != SubStr(rgb_str, 1, 2)
        {
            rgb_str := "0x" rgb_str
        }

        ; https://www.autohotkey.com/boards/viewtopic.php?t=3925
        try
        {
            if StrLen(rgb_str) == 8
            {
                return RGB(
                    rgb_str >> 16 & 0xff,
                    rgb_str >> 8 & 0xff,
                    rgb_str & 0xff,
                )
            }
        }

        throw ValueError("Invalid RGB: " SubStr(rgb_str, 3))
    }

    to_string()
    {
        return Format("{:02x}{:02x}{:02x}", this.r, this.g, this.b)
    }

    to_config()
    {
        return this.to_string()
    }
    
    ; use rev when the return value is used in win32
    to_int(is_to_win32 := true)
    {
        if is_to_win32 {
            return (this.b << 16) + (this.g << 8) + (this.r)
        } else {
            return (this.r << 16) + (this.g << 8) + (this.b)
        }
    }

    lum()
    {
        return 0.2126 * this.r + 0.7152 * this.g + 0.0722 * this.b
    }

    equal(other)
    {
        return this.to_int() = other.to_int()
    }

    static color_boxes()
    {
        static result := [
            RGB(91, 206, 250),
            RGB(245, 169, 184),
            RGB(255, 255, 255),
            RGB(245, 169, 184),
            RGB(91, 206, 250),
            RGB(255, 255, 255),
            RGB(255, 255, 255),
            RGB(255, 255, 255),
            RGB(228, 3, 3),
            RGB(255, 140, 0),
            RGB(255, 237, 0),
            RGB(0, 128, 38),
            RGB(0, 76, 255),
            RGB(115, 41, 130),
            RGB(255, 255, 255),
            RGB(255, 255, 255)
        ]

        return result
    }
}

choose_color(hwnd_owner := 0, &output?, predefined_color_boxes?)
{
    color_boxes := Buffer(64, 0)

    if IsSet(predefined_color_boxes)
    {
        bytes := 0

        for my_rgb in predefined_color_boxes
        {
            bytes := NumPut("UInt", my_rgb.to_int(), color_boxes, bytes) - color_boxes.Ptr
        }

        while bytes < 64
        {
            bytes := NumPut("UInt", 0xffffff, color_boxes, bytes) - color_boxes.Ptr
        }
    }
    else
    {
        bytes := 0

        while bytes < 64
        {
            bytes := NumPut("UInt", 0xffffff, color_boxes, bytes) - color_boxes.Ptr
        }
    }

    if A_PtrSize = 8
    {
        tag_choose_color := Buffer(72)

        NumPut(
            "UInt", tag_choose_color.Size,
            "Int", 0, ; padding
            "Ptr", hwnd_owner,
            "Ptr", 0, ; not used
            "UInt", IsSet(output) ? output.to_int() : 0xffffff, ; output rgb
            "UInt", 0, ; padding
            "Ptr", color_boxes.Ptr, ; get the rgb of 16 custom boxes (not used)
            ; CC_RGBINIT, CC_FULLOPEN, CC_ANYCOLOR
            "UInt", 0x00000103,
            "UInt", 0, ; padding
            "Ptr", 0, ; not used
            "Ptr", 0, ; not used
            "Ptr", 0, ; not used
            tag_choose_color
        ) - tag_choose_color.Ptr
    }
    else
    {
        tag_choose_color := Buffer(36)
        
        bytes := NumPut(
            "UInt", tag_choose_color.Size,
            "Ptr", hwnd_owner,
            "Ptr", 0, ; not used
            "UInt", IsSet(output) ? output.to_int() : 0xffffff, ; output rgb
            "Ptr", color_boxes.Ptr, ; get the rgb of 16 custom boxes (not used)
            ; CC_RGBINIT, CC_FULLOPEN, CC_ANYCOLOR
            "UInt", 0x00000103,
            "Ptr", 0, ; not used
            "Ptr", 0, ; not used
            "Ptr", 0, ; not used
            tag_choose_color
        )
    }
    
    if !DllCall("Comdlg32\ChooseColor", "Ptr", tag_choose_color)
    {
        if errno := DllCall("Comdlg32\CommDlgExtendedError")
        {
            MsgBox(Format("Failed to choose color: 0x{:x}", errno), "Error", 16)
        }

        return output ?? RGB(255, 255, 255)
    }

    selected_rgb := A_PtrSize = 8 ? NumGet(tag_choose_color, 24, "UInt") : NumGet(tag_choose_color, 12, "UInt")
    
    return output := RGB.from_int(selected_rgb)
}