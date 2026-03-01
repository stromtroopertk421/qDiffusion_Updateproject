import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import gui

import "style"
import "components"

FocusReleaser {
    id: root

    property var window
    property var spinner

    anchors.fill: parent

    Component.onCompleted: {
        if (spinner) {
            spinner.visible = false
        }
    }

    function tr(str, file = "Installer.qml") {
        return TRANSLATOR.instance.translate(str, file)
    }

    function packageVisible(packageName) {
        return packageName !== "pip" && packageName !== "wheel"
    }

    function packageLabel(packageName) {
        return String(packageName).split(" @ ")[0]
    }

    Connections {
        target: COORDINATOR

        function onProceed() {
            choice.disabled = true
            installButton.disabled = true
        }

        function onOutput(output) {
            outputArea.text += output + "\n"
            outputArea.area.cursorPosition = Math.max(0, outputArea.text.length - 1)
        }
    }

    Rectangle {
        anchors.fill: parent
        color: COMMON.bg00

        ColumnLayout {
            anchors.centerIn: parent
            width: 300
            height: parent.height - 200
            spacing: 8

            SText {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                text: root.tr("Requirements")
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                pointSize: 10.8
                color: COMMON.fg1
            }

            OChoice {
                id: choice
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                label: root.tr("Mode")
                disabled: COORDINATOR.disable
                currentIndex: COORDINATOR.mode
                entries: COORDINATOR.modes

                onCurrentIndexChanged: {
                    if (COORDINATOR.mode !== currentIndex) {
                        COORDINATOR.mode = currentIndex
                    }
                }

                function display(text) {
                    return root.tr(text)
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 200
                border.color: COMMON.bg4
                color: "transparent"

                ListView {
                    id: packageList
                    anchors.fill: parent
                    anchors.margins: 1
                    clip: true
                    model: COORDINATOR.packages
                    boundsBehavior: Flickable.StopAtBounds

                    ScrollBar.vertical: SScrollBarV {
                        totalLength: packageList.contentHeight
                        showLength: packageList.height
                    }

                    delegate: Rectangle {
                        required property string modelData
                        required property int index

                        readonly property bool rowVisible: root.packageVisible(modelData)

                        width: packageList.width
                        height: rowVisible ? 20 : 0
                        visible: rowVisible
                        color: index % 2 === 0 ? COMMON.bg0 : COMMON.bg00

                        Rectangle {
                            anchors.fill: parent
                            color: "green"
                            opacity: 0.1
                            visible: COORDINATOR.installed.includes(modelData)
                        }

                        Rectangle {
                            anchors.fill: parent
                            color: "yellow"
                            opacity: 0.1
                            visible: COORDINATOR.installing === modelData

                            onVisibleChanged: {
                                if (visible) {
                                    packageList.positionViewAtIndex(index, ListView.Contain)
                                }
                            }
                        }

                        SText {
                            width: parent.width
                            height: 20
                            text: root.packageLabel(modelData)
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignHCenter
                            pointSize: 9.8
                            color: COMMON.fg1
                        }
                    }
                }
            }

            SButton {
                id: installButton
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                label: COORDINATOR.disable
                    ? root.tr("Cancel")
                    : (COORDINATOR.packages.length === 0 ? root.tr("Proceed") : root.tr("Install"))

                onPressed: {
                    if (!COORDINATOR.disable) {
                        outputArea.text = ""
                    }
                    COORDINATOR.install()
                }
            }

            SText {
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                visible: COORDINATOR.needRestart
                text: root.tr("Restart required")
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                pointSize: 9.8
                color: COMMON.fg2
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 30
            }

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: parent.width * 3
                Layout.preferredHeight: 120
                border.width: 1
                border.color: COMMON.bg4
                color: "transparent"

                SText {
                    id: versionLabel
                    anchors.bottom: versionCheck.bottom
                    anchors.right: versionCheck.left
                    rightPadding: 7
                    text: root.tr("Enforce versions?")
                    pointSize: 9.8
                    color: COMMON.fg2
                    opacity: 0.9
                }

                Rectangle {
                    id: versionCheck
                    anchors.bottom: parent.top
                    anchors.bottomMargin: 5
                    anchors.right: parent.right
                    height: versionLabel.height
                    width: height
                    border.width: 1
                    border.color: COMMON.bg4
                    color: "transparent"

                    Image {
                        anchors.centerIn: parent
                        width: Math.max(0, parent.width - 4)
                        height: width
                        source: "qrc:/icons/tick.svg"
                        sourceSize: Qt.size(width, height)
                        visible: COORDINATOR.enforceVersions
                    }

                    MouseArea {
                        anchors.fill: parent
                        onPressed: COORDINATOR.enforceVersions = !COORDINATOR.enforceVersions
                    }
                }

                STextArea {
                    id: outputArea
                    anchors.fill: parent
                    area.color: COMMON.fg2
                    pointSize: 9.8
                    monospace: true
                }
            }
        }
    }
}
