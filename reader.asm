; Reader functions.

; A Reader record is a block of tokens, with a position.
; Pausing mid-EVAL to read a new block of text can happen, so that needs to be
; reentrant.
; However, the tokenizer and reader both run to completion.

; For speed and GC pressure, we don't convert the raw string to a Lisp string
; first.

; So the reader supports both raw text and Lisp strings.

; The tokenizer needs to process both of those forms and turn them into a list
; of tokens (substrings).

; Tokens are start-length pairs
:reader_buffer .reserve 256
:tokens .reserve 64 * 2
:token_count .dat 0
:token_index .dat 0

; Takes a raw string.
:read_string ; (buf, len) -> AST
set c, reader_buffer
set push, b
:read_string_loop
set [c], [a]
add a, 1
add c, 1
sub b, 1
ifg b, 0
  set pc, read_string_loop

; Copied into my own buffer, now tokenize it.
set a, pop
jsr tokenize

; Tokens array is now populated.
set [token_index], 0
tc read_form



; Reads a single form from the tokens, returning the AST.
:read_form ; () -> AST
jsr peek_token
ife a, 0
  brk -1

set c, [a] ; C is the first character of the token.
ife c, 0x28
  tc read_list
tc read_atom


:read_list ; token_start, token_len
pushXY
set x, empty_list ; The head of the list
set y, empty_list ; The tail of the list

:read_list_loop
jsr next_token ; Advance past the (
jsr peek_token
ife a, 0
  brk -1 ; Error: no code.
ife [a], 0x29 ; )
  set pc, read_list_end

; Otherwise, read the form.
jsr read_form  ; AST in A.
set push, a    ; Saved for later.

jsr alloc_cell ; New cell in A.
ife y, empty_list
  set pc, read_list_first

; Regular case, chaining them together.
set [a], pop
set [a+1], empty_list
set [y+1], a ; Chain this into the tail of the previous list.
set y, a     ; And this is the new tail.
set pc, read_list_loop

; This is the first cell, a special case.
:read_list_first
set x, a
set y, a
set [x], pop
set [x+1], empty_list
set pc, read_list_loop

:read_list_end
set a, x
retXY



; Reads numbers, strings and symbols.
; TODO Handle nil, true, and false.
:read_atom ; (token_start, len) -> AST
set c, [a]

; Quote -> string
ife c, 0x22 ; "
  set pc, read_atom_string

; Digit -> number
ifl c, 0x3a ; <= 9
  ifg c, 0x2f ; >= 0
    set pc, read_atom_number

ife c, 0x2d ; - (negative sign)
  set pc, read_atom_negative

; Read a symbol. That's simply converting to a Lisp string, then tucking it into
; a symbol type cell.
:read_atom_symbol
set push, a
set push, b
jsr check_special_strings
ifn a, 0
  set pc, read_atom_symbol_special

set b, pop
set a, pop
jsr str_to_lisp ; A is the Lisp string.
set push, a
jsr alloc_cell
set [a], type_symbol
set [a+1], pop
ret


:read_atom_symbol_special
add sp, 2 ; Drop the saved raw string.
ret



; Similarly to a symbol, we read the string without its quotes.
:read_atom_string
add a, 1
sub b, 2
jsr str_to_lisp
set push, a
jsr alloc_cell
set [a], type_string
set [a+1], pop
ret


; Found a negative sign. If the next character is a digit, process it as a
; number. If it's not a digit, treat this as a symbol.
:read_atom_negative
ifl [a+1], 0x3a ; <= 9
  ifg [a+1], 0x2f ; >= 0
    set pc, read_atom_number
set pc, read_atom_symbol ; Not a number, so back to treating it as a symbol.



; Convert the number to a decimal value.
:read_atom_number
pushXY
set y, 0 ; Y is the running value.
set x, 0
ifn c, 0x2d ; Not negative, so continue
  set pc, read_atom_number_loop

; Handle negatives: move ahead one, and set the flag.
set x, 1  ; Set the flag.
add a, 1
sub b, 1

:read_atom_number_loop
set c, [a]
sub c, 0x30 ; Reduce to 0-9 instead of ASCII.
ifg c, 9    ; Unsigned greater than 9? Illegal digit.
  brk -1

; Valid digit to add in.
mul y, 10
add y, c

add a, 1
sub b, 1
ifg b, 0
  set pc, read_atom_number_loop

; All done with parsing. Y is the value, X the negative flag.
ife x, 0
  set pc, read_atom_number_save

; Negate.
xor y, -1
add y, 1

:read_atom_number_save
jsr alloc_cell
set [a], type_number
set [a+1], y
retXY



; Returns the current token's details without advancing it.
:peek_token ; () -> start, len
set c, [token_index]
ife c, [token_count]
  set pc, peek_token_end
shl c, 1
add c, tokens
set a, [c]
set b, [c+1]
ret

:peek_token_end
set a, 0
set b, 0
ret


; Advances the token forward by one, but doesn't examine it.
:next_token ; () -> void
add [token_index], 1
ret




; The following are tokens:
; - ~@
; - Each of the special characters: []{}()'`~^@
; - "strings" (quotes included)
; - 0+ non-special characters (digits, letters, etc.)
; Whitespace and semicolon-to-newline are ignored.
:tokenize ; (len) ->
pushXY
set [token_count], 0
set x, reader_buffer
set y, a ; Save the length
add y, x ; Y is the end of the array

:tokenize_loop
ife x, y
  set pc, tokenize_done

ife [x], 0x7e ; ~
  ife [x+1], 0x40 ; @
    set pc, tokenize_tilde_at

ife [x], 0x7e ; ~
  set pc, tokenize_single
ife [x], 0x28 ; (
  set pc, tokenize_single
ife [x], 0x29 ; )
  set pc, tokenize_single

ife [x], 0x22 ; "
  set pc, tokenize_quote
ife [x], 0x3b ; ;
  set pc, tokenize_comment

ife [x], 0x20 ; space
  set pc, tokenize_whitespace

; Regular character: keep going until a non-regular character.
set a, x ; Note the start position.

:tokenize_regular_loop
add x, 1
ife x, y
  set pc, tokenize_regular_done

ife [x], 0x7e ; ~
  set pc, tokenize_regular_done
ife [x], 0x28 ; (
  set pc, tokenize_regular_done
ife [x], 0x29 ; )
  set pc, tokenize_regular_done
ife [x], 0x22 ; "
  set pc, tokenize_regular_done
ife [x], 0x3b ; ;
  set pc, tokenize_regular_done
ife [x], 0x20 ; space
  set pc, tokenize_regular_done

; If we're still here, this is fine, so loop.
set pc, tokenize_regular_loop



; Found the end of a regular character. We want to leave X where it is and
; record the token. Start position is already in A.
:tokenize_regular_done
set b, x
sub b, a ; B is the length.
jsr add_token ; Token recorded.
set pc, tokenize_loop


:tokenize_tilde_at ; Special case of a two-character special token. X is pointed
                   ; at the tilde.
set a, x
set b, 2
jsr add_token
add x, 2
set pc, tokenize_loop

; Tokenizes a single-character special token at X.
:tokenize_single
set a, x
set b, 1
jsr add_token
add x, 1
set pc, tokenize_loop

:tokenize_quote
; Run along, looking for a quote, or a backslash.
set c, 0    ; C holds the backslash state.
set a, x    ; A remembers the start position.
add x, 1

:tokenize_quote_loop
ife x, y   ; We've run out of string; that's an error.
  brk -1     ; onoes! TODO Error handling.

ife [x], 0x22 ; quote
  ife c, 1    ; escaping
    set pc, tokenize_quote_escaped_quote

ife [x], 0x22 ; quote
  set pc, tokenize_quote_done

set c, 0
ife [x], 0x5c ; \
  set c, 1

; Either way, we move past it.
add x, 1
set pc, tokenize_quote_loop


:tokenize_quote_escaped_quote
set c, 0
add x, 1
set pc, tokenize_quote_loop

; X points at the final quote.
:tokenize_quote_done
add x, 1
set b, x
sub b, a
jsr add_token
set pc, tokenize_loop


; For now, comments are the end of the whole input.
; TODO: Handle multi-line structures.
:tokenize_comment
set pc, tokenize_done


:tokenize_whitespace
add x, 1
set pc, tokenize_loop


:tokenize_done
retXY


:add_token ; (start, length)
set c, [token_count]
shl c, 1
add c, tokens
set [c], a
set [c+1], b
add [token_count], 1
ret




; Checks a handful of special strings.
:check_special_strings ; (buf, len)
set c, a ; Preparing for swift returns.
set a, 0
ifg b, 5
  ret
ifl b, 3
  ret

; It's plausible, so check each one.


ife b, 3
  set pc, check_special_strings_nil
ife b, 4
  set pc, check_special_strings_true

; False
ife [c],   0x66 ; f
ife [c+1], 0x61 ; a
ife [c+2], 0x6c ; l
ife [c+3], 0x73 ; s
ife [c+4], 0x65 ; e
  set a, false
ret

:check_special_strings_true
ife [c],   0x74 ; t
ife [c+1], 0x72 ; r
ife [c+2], 0x75 ; u
ife [c+3], 0x65 ; e
  set a, true
ret

:check_special_strings_nil
ife [c],   0x6e ; n
ife [c+1], 0x69 ; i
ife [c+2], 0x6c ; l
  set a, nil
ret


