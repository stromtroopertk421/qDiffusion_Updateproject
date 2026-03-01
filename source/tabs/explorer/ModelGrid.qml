import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Frame {
    id: root

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8

        Label {
            text: "Models"
            font.bold: true
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Column {
                width: parent.width
                spacing: 8

                Repeater {
                    model: 6
                    delegate: ModelCard {
                        width: parent.width
                        modelName: "Model " + (index + 1)
                    }
                }
            }
        }
    }
}
