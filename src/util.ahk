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

array_equal(a, b)
{
    if a.Length !== b.Length
    {
        return false
    }

    for _ in a
    {
        if a[A_Index] !== b[A_Index]
        {
            return false
        }
    }

    return true
}

map_equal(a, b)
{
    if a.Count != b.Count
    {
        return false
    }

    for key in a
    {
        if !b.Has(key) || a[key] !== b[key]
        {
            return false
        }
    }

    return true
}

join_array(arr, sep := A_Space)
{
    res := ""

    for s in arr
    {
        res .= sep s
    }

    return SubStr(res, 2)
}

unrecoverable_error(err)
{
    MsgBox "Error: " err.Message "(" err.What ", " err.Extra ") `nThe application will terminate.`nPlease report it to the developers. Thank you.", "Fatal Error", 16
    ExitApp
}