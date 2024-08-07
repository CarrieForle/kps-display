; #Include "message.ahk"
; #Include "gui.ahk"

; class Keys {
;     creations := []

;     __Enum(params*) {
;         return this.creations.__Enum(params*)
;     }

;     __Item[ind] {
;         set => this.creations[ind] = value
;         get => this.creations[ind]
;     }

;     Push(val) {
;         this.creations.Push(val)
;         PostMessage KPS_CHANGE, 0x10000 + this.creations.Length,, get_kpsText()
;     }

;     RemoveAt(ind) {
;         this.creations.RemoveAt(ind)
;         PostMessage KPS_CHANGE, 0x10000 + this.creations.Length,, get_kpsText()
;     }

;     Length => this.creations.Length
; }