import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    anchors.fill: parent

    function releaseFocus() {
        forceActiveFocus()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        Label {
            text: "Basic"
            font.pixelSize: 22
            font.bold: true
        }

        RowLayout {
            spacing: 8
            Button {
                text: "Generate"
                onClicked: BASIC.generate()
            }
            Button {
                text: "Enqueue"
                onClicked: BASIC.enqueue()
            }
            Button {
                text: "Cancel"
                onClicked: BASIC.cancel()
            }
            Button {
                text: "Build Model"
                onClicked: BASIC.doBuildModel()
            }
        }

        BasicAreas {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        BasicInputs {
            Layout.fillWidth: true
            Layout.preferredHeight: 140
        }

        BasicOutputs {
            Layout.fillWidth: true
            Layout.preferredHeight: 180
        }

        Label {
            Layout.fillWidth: true
            text: "Advanced Basic tab features are being migrated to Qt 6.10.2 and may be temporarily unavailable."
            wrapMode: Text.WordWrap
            opacity: 0.75
        }
    }
}
