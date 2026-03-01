import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Frame {
    RowLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 6

        Label {
            text: "Subfolders:"
        }

        Label {
            Layout.fillWidth: true
            text: "Folder list migration in progress"
            opacity: 0.75
            elide: Text.ElideRight
        }

        Button {
            text: "Open"
            onClicked: EXPLORER.openCurrentFolder()
        }
    }
}
