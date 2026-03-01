import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import gui

import "style"
import "components"

FocusReleaser {
    property var window
    property var spinner
    property bool firstShowHandled: false
    anchors.fill: parent
    layer.enabled: true
    opacity: 0.0

    NumberAnimation on opacity {
        id: opacityAnimator
        from: 0
        to: 1
        duration: 250
        onFinished: {
            layer.enabled = false
            spinner.visible = false
        }
    }
    
    function runInitialShow() {
        if (firstShowHandled)
            return

        firstShowHandled = true
        window.title = Qt.binding(function() { return TRANSLATOR.instance.translate(GUI.title, "Title"); })
        opacityAnimator.start()
    }

    onVisibleChanged: {
        if (visible)
            runInitialShow()
    }

    Component.onCompleted: {
        if (visible)
            runInitialShow()
    }

    Timer {
        id: raiseTimer
        interval: 50
        onTriggered: {
            window.flags = Qt.Window
            window.requestActivate()
        }
    }

    Connections {
        target: GUI
        function onRaiseToTop() {
            window.flags = Qt.Window | Qt.WindowStaysOnTopHint
            raiseTimer.start()
        }
    }


    Rectangle {
        id: root
        anchors.fill: parent
        color: COMMON.bg0
    }

    WindowBar {
        id: windowBar
        anchors.left: root.left
        anchors.right: root.right
    }

    TabBar {
        id: tabBar
        anchors.left: root.left
        anchors.right: root.right
        anchors.top: windowBar.bottom
    }

    Rectangle {
        id: barDivider
        anchors.left: root.left
        anchors.right: root.right
        anchors.top: tabBar.bottom

        height: 5
        color: COMMON.bg4
    }

    ErrorDialog {
        id: errorDialog
    }

    StackLayout {
        id: stackLayout
        anchors.left: root.left
        anchors.right: root.right
        anchors.top: barDivider.bottom
        anchors.bottom: statusBar.top

        currentIndex: {
            var tabIndex = GUI.tabNames.indexOf(GUI.currentTab)
            return tabIndex >= 0 ? tabIndex : 0
        }

        function releaseFocus() {
            keyboardFocus.forceActiveFocus()
        }

        onCurrentIndexChanged: {
            releaseFocus()
        }

        Repeater {
            model: GUI.tabSources

            Loader {
                id: tabLoader
                required property string modelData
                property string tabError: ""
                property Component tabComponent: Qt.createComponent(modelData)

                Component {
                    id: errorTabComponent
                    Error {
                        error: tabError
                    }
                }

                active: true
                sourceComponent: tabComponent.status === Component.Ready ? tabComponent : errorTabComponent
                asynchronous: false

                function updateErrorState() {
                    if (tabComponent.status === Component.Error) {
                        tabError = tabComponent.errorString()
                        console.error("ERROR", "Failed to load tab", modelData, tabError)
                    }
                }

                onStatusChanged: {
                    if (status === Loader.Error)
                        console.error("ERROR", "Failed to instantiate tab view", modelData)
                }

                Component.onCompleted: updateErrorState()

                Connections {
                    target: tabComponent
                    function onStatusChanged() {
                        tabLoader.updateErrorState()
                    }
                }
            }
        }
    }

    StatusBar {
        id: statusBar
        anchors.left: root.left
        anchors.right: root.right
        anchors.bottom: root.bottom
        height: stackLayout.currentIndex == 0 ? 0 : 20
    }

    onReleaseFocus: {
        keyboardFocus.forceActiveFocus()
    }

    Shortcut {
        sequences: COMMON.keys_basic
        onActivated: GUI.currentTab = "Generate"
    }

    Shortcut {
        sequences: COMMON.keys_models
        onActivated: GUI.currentTab = "Models"
    }

    Shortcut {
        sequences: COMMON.keys_gallery
        onActivated: GUI.currentTab = "History"
    }

    Shortcut {
        sequences: COMMON.keys_merge
        onActivated: GUI.currentTab = "Merge"
    }

    /*Shortcut {
        sequences: COMMON.keys_train
        onActivated: GUI.currentTab = "Train"
    }*/

    Shortcut {
        sequences: COMMON.keys_settings
        onActivated: GUI.currentTab = "Settings"
    }

    Item {
        id: keyboardFocus
        Keys.onPressed: {
            event.accepted = true
            if(event.modifiers & Qt.ControlModifier) {
                switch(event.key) {
                default:
                    event.accepted = false
                    break;
                }
            } else {
                switch(event.key) {
                default:
                    event.accepted = false
                    break;
                }
            }
        }
        Keys.forwardTo: {
            var activeTab = stackLayout.itemAt(stackLayout.currentIndex)
            return activeTab ? [activeTab] : []
        }
    }

    Item {
        visible: overlay.children.length > 0
        anchors.fill: parent

        Rectangle {
            color: COMMON.bg0
            opacity: 0.5
            anchors.fill: parent
        }
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            hoverEnabled: true
        }

        Item {
            id: overlay
            width: parent.width
            height: stackLayout.height
            anchors.bottom: parent.bottom
            Component.onCompleted: {
                COMMON.overlay = overlay
            }
        }       
    }
}
