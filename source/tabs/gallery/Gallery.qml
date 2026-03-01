import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    anchors.fill: parent

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        Label {
            text: "Gallery"
            font.pixelSize: 22
            font.bold: true
        }

        RowLayout {
            Layout.fillWidth: true
            Button {
                text: "Refresh"
                onClicked: GALLERY.refresh()
            }
            Button {
                text: "Clear Selection"
                onClicked: GALLERY.clearSelection()
            }
        }

        ThumbnailGrid {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        Label {
            Layout.fillWidth: true
            text: "Image detail dialogs and advanced batch actions will be restored incrementally."
            wrapMode: Text.WordWrap
            opacity: 0.75
        }
    }
}
