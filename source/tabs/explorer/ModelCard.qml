import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Frame {
    id: root
    property string modelName: "Unnamed model"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8

        Label {
            text: root.modelName
            font.bold: true
            elide: Text.ElideRight
        }

        Label {
            text: "Model preview/metadata is being migrated."
            wrapMode: Text.WordWrap
            opacity: 0.8
        }

        Button {
            text: "Select"
            onClicked: EXPLORER.selectModel(root.modelName)
        }
    }
}
