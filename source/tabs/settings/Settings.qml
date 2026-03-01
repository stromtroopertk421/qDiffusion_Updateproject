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
            text: "Settings"
            font.pixelSize: 22
            font.bold: true
        }

        TabBar {
            id: tabs
            Layout.fillWidth: true
            SettingsButton { text: "Program" }
            SettingsButton { text: "Host" }
            SettingsButton { text: "Remote" }
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: tabs.currentIndex

            ProgramSettings {}
            HostSettings {}
            RemoteSettings {}
        }

        RowLayout {
            Button {
                text: "Apply"
                onClicked: SETTINGS.apply()
            }
            Button {
                text: "Reset"
                onClicked: SETTINGS.reset()
            }
        }
    }
}
