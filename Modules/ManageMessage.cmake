# - Manage the output and debug messages.
# This module has macros that control how many messages to be shown
# by defining the desire message level.
#
# Defined variables that represent verbose levels:
#   1: M_FATAL - Critical error,Should stop immediately
#   2: M_ERROR - Error that will Eventually fail
#   3: M_WARN  - Warning.
#   4: M_INFO1 - Info/debug message
#   5: M_INFO2 - Info/debug message
#   6: M_INFO3 - Info/debug message
#
# Read following variable:
#   + MANAGE_MESSAGE_LEVEL: Message level in integer.
#     Messages with greater level will be suppressed.
#     Default is ${M_WARN}
#   + MANAGE_MESSAGE_LABELS: Labels that printed in front of the message for
#     corresponding message level.
#     Default is "[Fatal] ;[Error] ;[Warn] ;[Info1] ;[Info2] ;[Info3] "
#
# Define following macros:
#   M_MSG(level msg)
#   - Surpress the message if level is higher than MANAGE_MESSAGE_LEVEL
#     Otherwise show the message.
#     Arguments:
#     + level: level of the message.
#     + msg: Message to show.
#


IF(NOT DEFINED _MANAGE_MESSAGE_CMAKE_)
    SET(_MANAGE_MESSAGE_CMAKE_ "DEFINED")
    SET(M_FATAL 1)
    SET(M_ERROR 2)
    SET(M_WARN 3)
    SET(M_INFO1 4)
    SET(M_INFO2 5)
    SET(M_INFO3 6)
    IF(NOT DEFINED MANAGE_MESSAGE_LABELS)
	SET(MANAGE_MESSAGE_LABELS
	    "[Fatal] ;[Error] ;[Warn] ;[Info1] ;[Info2] ;[Info3] ")
    ENDIF(NOT DEFINED MANAGE_MESSAGE_LABELS)

    MACRO(M_MSG level msg)
	IF(NOT DEFINED MANAGE_MESSAGE_LEVEL)
	    SET(MANAGE_MESSAGE_LEVEL ${M_WARN})
	ENDIF(NOT DEFINED MANAGE_MESSAGE_LEVEL)
	IF(${level} GREATER ${MANAGE_MESSAGE_LEVEL})
	ELSE(${level} GREATER ${MANAGE_MESSAGE_LEVEL})
	    LIST(GET MANAGE_MESSAGE_LABELS ${level} _label)
	    IF(${level} EQUAL 1)
		MESSAGE(FATAL_ERROR "${_label}${msg}")
	    ELSE(${level} EQUAL 1)
		MESSAGE("${_label}${msg}")
	    ENDIF(${level} EQUAL 1)
	ENDIF(${level} GREATER ${MANAGE_MESSAGE_LEVEL})
    ENDMACRO(M_MSG level msg)
ENDIF(NOT DEFINED _MANAGE_MESSAGE_CMAKE_)

