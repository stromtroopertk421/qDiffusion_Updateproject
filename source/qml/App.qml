import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import gui 1.0

ApplicationWindow {
    id: root
    visible: true
    width: 1100
    height: 600
    color: "#1a1a1a"
    title: "qDiffusion"
    flags: Qt.Window | Qt.WindowStaysOnTopHint

    property string viewState: "splash"

    function loadCoordinator() {
        root.flags = Qt.Window
        root.requestActivate()
        if (typeof COORDINATOR !== "undefined" && COORDINATOR) {
            COORDINATOR.load()
        }
    }

    Connections {
        target: COORDINATOR

        function onShow() {
            root.viewState = "installer"
        }

        function onProceed() {
            root.viewState = "main"
        }
    }

    Loader {
        id: contentLoader
        anchors.fill: parent
        sourceComponent: root.viewState === "installer" ? installerView : (root.viewState === "main" ? mainView : null)
    }

    Item {
        id: splashLayer
        anchors.fill: parent
        visible: root.viewState === "splash"

        Rectangle {
            anchors.fill: parent
            color: root.color
        }

        BusyIndicator {
            id: splashSpinner
            anchors.centerIn: parent
            running: splashLayer.visible
            width: 84
            height: 84
        }
    }

    Component {
        id: installerView
        Installer {
            window: root
            spinner: splashSpinner
        }
    }

    Component {
        id: mainView
        Main {
            window: root
            spinner: splashSpinner
        }
    }

    Component.onCompleted: {
        Qt.callLater(root.loadCoordinator)
    }
}
