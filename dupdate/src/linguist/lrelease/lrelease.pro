option(host_build)
QT = core-private
DEFINES += QT_NO_CAST_FROM_ASCII QT_NO_CAST_TO_ASCII

SOURCES += main.cpp

include(../shared/formats.pri)
include(../shared/proparser.pri)

qmake.name = QMAKE
qmake.value = $$shell_path($$QMAKE_QMAKE)
QT_TOOL_ENV += qmake

load(qt_tool)

# When linking with libQt5Boostrap.a we need zlib too
LIBS += -Wl,--no-as-needed
LIBS += -lz
