import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Frame {
    ScrollView {
        anchors.fill: parent
        anchors.margins: 8

        GridLayout {
            id: grid
            width: parent.width
            columns: 4
            columnSpacing: 8
            rowSpacing: 8

            Repeater {
                model: 12
                delegate: Thumbnail {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 110
                    title: "Image " + (index + 1)
                }
            }
        }
    }
}
