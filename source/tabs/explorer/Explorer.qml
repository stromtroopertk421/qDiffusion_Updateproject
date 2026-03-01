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
            text: "Explorer"
            font.pixelSize: 22
            font.bold: true
        }

        RowLayout {
            Layout.fillWidth: true
            TextField {
                id: searchField
                Layout.fillWidth: true
                placeholderText: "Search models"
                onAccepted: EXPLORER.search(text)
            }
            Button {
                text: "Refresh"
                onClicked: EXPLORER.refresh()
            }
        }

        SubfolderList {
            Layout.fillWidth: true
            Layout.preferredHeight: 80
        }

        ModelGrid {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        Label {
            Layout.fillWidth: true
            text: "Advanced explorer previews and metadata dialogs are temporarily shown as placeholders while being ported."
            wrapMode: Text.WordWrap
            opacity: 0.75
        }
    }
}
