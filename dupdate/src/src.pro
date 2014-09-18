TEMPLATE = subdirs

qtHaveModule(widgets) {
    no-png {
        message("Some graphics-related tools are unavailable without PNG support")
    } else {
#    unix:!mac:!embedded:!qpa:SUBDIRS += qtconfig
    }
}

SUBDIRS += linguist

qtNomakeTools( \
    pixeltool \
    qtconfig \
    macdeployqt \
)
