# Unit test for ManageString
INCLUDE(test/testCommon.cmake)
INCLUDE(ManageString)

# STRING QUOTE
SET(STR_QUOTE_1 "\"hi=hello=how are you=fine\"")
STRING_UNQUOTE(str_quote_1 "${STR_QUOTE_1}")
TEST_STR_MATCH(str_quote_1 "hi=hello=how are you=fine")
SET(STR_QUOTE_2 "hi=hello=how are you=fine")
STRING_UNQUOTE(_str_quote_2 "${STR_QUOTE_2}")
TEST_STR_MATCH(_str_quote_2 "")
SET(STR_QUOTE_3 "'hi=hello=how are you=fine'")
STRING_UNQUOTE(_str_quote_3 "${STR_QUOTE_3}")
TEST_STR_MATCH(_str_quote_3 "hi=hello=how are you=fine")

SET(STR_QUOTE_4 "\"   many space  \"")
STRING_UNQUOTE(_str_quote_4 "${STR_QUOTE_4}")
TEST_STR_MATCH(_str_quote_4 "   many space  ")

SET(STR_QUOTE_5 "Not quoted")
STRING_UNQUOTE(_str_quote_5 "${STR_QUOTE_5}")
TEST_STR_MATCH(_str_quote_5 "")

# Quoted empty string
SET(STR_QUOTE_6 "\"\"")
STRING_UNQUOTE(_str_quote_6 "${STR_QUOTE_6}")
TEST_STR_MATCH(_str_quote_6 "")


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

# STRING JOIN
STRING_JOIN(str_join_1 " " "Are" "you sure" " it" "is" "right?" " ")
TEST_STR_MATCH(str_join_1 "Are you sure  it is right?  ")

# STRING_SPLIT
SET(STR_SPLIT_1 "hi=hello=how are you=fine")
STRING_SPLIT(_str_split_1 "=" "${STR_SPLIT_1}")
#MESSAGE("_str_split_1=${_str_split_1}")
TEST_STR_MATCH(_str_split_1 "hi;hello;how are you;fine")
STRING_SPLIT(_str_split_1 "=" "${STR_SPLIT_1}" 2)
TEST_STR_MATCH(_str_split_1 "hi;hello=how are you=fine")

SET(STR_SPLIT_2 "hi; hello; how are you;I am fine")

STRING_SPLIT(_str_split_2a " " "${STR_SPLIT_2}")
SET(_str_split_2a_a "hi\\;" "hello\\;" "how" "are" "you\\;I" "am" "fine")
TEST_STR_MATCH(_str_split_2a "${_str_split_2a_a}")

STRING_SPLIT(_str_split_2b " " "${STR_SPLIT_2}" 2)
SET(_str_split_2b_a "hi\\;" "hello\\; how are you\\;I am fine")
#FOREACH(_tok ${_str_split_2b})
#    MESSAGE("  2b_tok=${_tok}")
#ENDFOREACH()
TEST_STR_MATCH(_str_split_2b "${_str_split_2b_a}")

STRING_SPLIT(_str_split_2c ";" "${STR_SPLIT_2}")
SET(_str_split_2c_a "hi" " hello" " how are you" "I am fine")
TEST_STR_MATCH(_str_split_2c "${_str_split_2c_a}")

STRING_SPLIT(_str_split_2d ";" "${STR_SPLIT_2}" 2)
SET(_str_split_2d_a "hi" " hello\\; how are you\\;I am fine")
TEST_STR_MATCH(_str_split_2d "${_str_split_2d_a}")


