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
            text: "Trainer"
            font.pixelSize: 22
            font.bold: true
        }

        RowLayout {
            Layout.fillWidth: true
            Button {
                text: "Start"
                onClicked: TRAINER.start()
            }
            Button {
                text: "Stop"
                onClicked: TRAINER.stop()
            }
            Button {
                text: "Refresh"
                onClicked: TRAINER.refresh()
            }
        }

        Frame {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Label {
                anchors.centerIn: parent
                text: "Training workflow panels and charts are being migrated to Qt 6.10.2."
                width: parent.width - 24
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
}
