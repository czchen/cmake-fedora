# Unit test for ManageString
INCLUDE(test/testCommon.cmake)
INCLUDE(ManageString)

## STRING APPEND
MACRO(STRING_APPEND_TEST testName expected var str)
    STRING_APPEND(${var} "${str}" ${ARGN})
    IF("${${var}}" STREQUAL "${expected}")
	MESSAGE(STATUS "Test STRING_APPEND_${testName} passed")
    ELSE("${${var}}" STREQUAL "${expected}")
	MESSAGE(SEND_ERROR "Test STRING_APPEND_${testName} failed: actual=|${${var}}| expected=|${expected}|")
    ENDIF("${${var}}" STREQUAL "${expected}")
ENDMACRO(STRING_APPEND_TEST testName expected var var)
SET(_str "")
STRING_APPEND_TEST("no_prev" "Hi" _str "Hi")
STRING_APPEND_TEST("default" "Hi Hello" _str " Hello")
STRING_APPEND_TEST("linebreak" "Hi Hello\nHow are you" _str
    "How are you" "\n")
STRING_APPEND_TEST("noseparator" "Hi Hello\nHow are you?" _str
    "?")
SET(_str "%find_lang")
STRING_APPEND_TEST("1" "%find_lang %{name}" _str " %{name}")
SET(_str "%find_lang")
STRING_APPEND_TEST("1" "%find_lang %{name}" _str "%{name}" " ")


## STRING QUOTE
SET(STR_QUOTE_1 "\"hi=hello=how are you=fine\"")
STRING_UNQUOTE(str_quote_1 "${STR_QUOTE_1}")
TEST_STR_MATCH(str_quote_1 "hi=hello=how are you=fine")

SET(STR_QUOTE_2 "hi=hello=how are you=fine")
STRING_UNQUOTE(_str_quote_2 "${STR_QUOTE_2}")
TEST_STR_MATCH(_str_quote_2 "hi=hello=how are you=fine")
SET(STR_QUOTE_3 "'hi=hello=how are you=fine'")
STRING_UNQUOTE(_str_quote_3 "${STR_QUOTE_3}")
TEST_STR_MATCH(_str_quote_3 "hi=hello=how are you=fine")

SET(STR_QUOTE_4 "\"   many space  \"")
STRING_UNQUOTE(_str_quote_4 "${STR_QUOTE_4}")
TEST_STR_MATCH(_str_quote_4 "   many space  ")

SET(STR_QUOTE_5 "Not quoted")
STRING_UNQUOTE(_str_quote_5 "${STR_QUOTE_5}")
TEST_STR_MATCH(_str_quote_5 "Not quoted")

# Quoted empty string
SET(STR_QUOTE_6 "\"\"")
STRING_UNQUOTE(_str_quote_6 "${STR_QUOTE_6}")
TEST_STR_MATCH(_str_quote_6 "")

SET(STR_QUOTE_7 "\"Left inside \" Right Outside ")
STRING_UNQUOTE(_str_quote_7 "${STR_QUOTE_7}")
TEST_STR_MATCH(_str_quote_7 "\"Left inside \" Right Outside ")

SET(STR_QUOTE_8 " Left outside \" Right Inside \" ")
STRING_UNQUOTE(_str_quote_8 "${STR_QUOTE_8}")
TEST_STR_MATCH(_str_quote_8 " Left outside \" Right Inside \" ")


# STRING TRIM
SET(STR_TRIM_1 " \"hi=hello=how are you=fine\" ")
STRING_TRIM(str_trim_1 "${STR_TRIM_1}")
TEST_STR_MATCH(str_trim_1 "hi=hello=how are you=fine")
SET(STR_TRIM_2 "  hi=hello=how are you=fine2  3   ")
STRING_TRIM(str_trim_2 "${STR_TRIM_2}")
TEST_STR_MATCH(str_trim_2 "hi=hello=how are you=fine2  3")

SET(STR_TRIM_3 "")
STRING_TRIM(str_trim_3 "${STR_TRIM_3}")
TEST_STR_MATCH(str_trim_3 "")

SET(STR_TRIM_4 "\"\"")
STRING_TRIM(str_trim_4 "${STR_TRIM_4}")
TEST_STR_MATCH(str_trim_4 "")

SET(STR_TRIM_5 "\"Left inside \" Right Outside ")
STRING_TRIM(str_trim_5 "${STR_TRIM_5}")
TEST_STR_MATCH(str_trim_5 "\"Left inside \" Right Outside")

SET(STR_TRIM_6 " Left outside \" Right Inside \" ")
STRING_TRIM(str_trim_6 "${STR_TRIM_6}")
TEST_STR_MATCH(str_trim_6 "Left outside \" Right Inside \"")

# STRING JOIN
STRING_JOIN(str_join_1 " " "Are" "you sure" " it" "is" "right?" " ")
TEST_STR_MATCH(str_join_1 "Are you sure  it is right?  ")

# STRING_PADDING
FUNCTION(STRING_PADDING_TEST testName expected str length)
    STRING_PADDING(var "${str}" "${length}" $ARGN)
    IF(var STREQUAL "${expected}")
	MESSAGE(STATUS "Test ${testName} passed")
    ELSE(var STREQUAL "${expected}")
	MESSAGE(SEND_ERROR "Test ${testName} failed: actual=|${var}| expected=|${expected}|")
    ENDIF(var STREQUAL "${expected}")
ENDFUNCTION(STRING_PADDING_TEST testName expected str length)

STRING_PADDING_TEST("STRING_PADING_TEST_need_padding_0" 
    "test      " "test" 10)

STRING_PADDING_TEST("STRING_PADING_TEST_need_padding_1" 
    "test12345 " "test12345" 10)

STRING_PADDING_TEST("STRING_PADING_TEST_no_need_padding_0" 
    "test123456" "test123456" 10)

STRING_PADDING_TEST("STRING_PADING_TEST_no_need_padding_1" 
    "test1234567" "test1234567" 10)

# STRING_SPLIT
FUNCTION(STRING_SPLIT_TEST testName expected delimiter input)
    STRING_SPLIT(var "${delimiter}" "${input}" ${ARGN})
    IF(var STREQUAL "${expected}")
	MESSAGE(STATUS "Test ${testName} passed")
    ELSE(var STREQUAL "${expected}")
	MESSAGE(SEND_ERROR "Test ${testName} failed: actual=|${var}| expected=|${expected}|")
    ENDIF(var STREQUAL "${expected}")
ENDFUNCTION(STRING_SPLIT_TEST)

STRING_SPLIT_TEST("STRING_SPLIT_1" "hi;hello;how are you;fine" "=" "hi=hello=how are you=fine")

STRING_SPLIT_TEST("STRING_SPLIT_2a" "hi\\;;hello\\;;how;are;you\\;I;am;fine" " " "hi; hello; how are you;I am fine")

STRING_SPLIT_TEST("STRING_SPLIT_2b" "hi\\;;hello\\; how are you\\;I am fine" " " "hi; hello; how are you;I am fine" 2)

STRING_SPLIT_TEST("STRING_SPLIT_2c" "hi; hello; how are you;I am fine" ";" "hi; hello; how are you;I am fine")

STRING_SPLIT_TEST("STRING_SPLIT_2d" "hi; hello\\; how are you\\;I am fine" ";" "hi; hello; how are you;I am fine" 2)

STRING_SPLIT_TEST("STRING_SPLIT_backslash" "Have '\\';Next line" "\n" "Have '\\'\nNext line")

STRING_SPLIT_TEST("STRING_SPLIT_allow_empty_0" "hi; ;hello; how are you;I'm fine" "=" "hi= ==hello= how are you=I'm fine")

STRING_SPLIT_TEST("STRING_SPLIT_allow_empty_1" "hi; ;;hello; how are you;I'm fine" "=" "hi= ==hello= how are you=I'm fine" ALLOW_EMPTY)

STRING_SPLIT_TEST("STRING_SPLIT_allow_empty_2" "* Tue;-Enhancement;;* Fri;" "\n" "* Tue\n-Enhancement\n\n* Fri\n" ALLOW_EMPTY)

