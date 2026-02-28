import QtQuick 2.15
import QtQuick.Controls 2.15
import gui 1.0

ApplicationWindow {
    id: root
    visible: true
    width: 1100
    height: 600
    color: "#1a1a1a"
    title: "qDiffusion"
    flags: Qt.Window | Qt.WindowStaysOnTopHint

    function createWindowComponent(url) {
        var component = Qt.createComponent(url)
        var finishCreate = function() {
            if (component.status === Component.Error) {
                console.error("ERROR", component.errorString())
                return
            }

            if (component.status !== Component.Ready) {
                return
            }

            var object = component.createObject(root, { window: root, spinner: null })
            if (object === null) {
                console.error("ERROR", "Failed to create object for", url, component.errorString())
            }
        }

        if (component.status === Component.Loading) {
            component.statusChanged.connect(finishCreate)
            return
        }

        finishCreate()
    }

    function handleShow() {
        createWindowComponent("qrc:/Installer.qml")
    }

    contentItem: Item {
        Image {
            opacity: 0.5
            id: spinner
            source: "icons/loading.svg"
            width: 80
            height: 80
            sourceSize: Qt.size(width, height)
            anchors.centerIn: parent
            smooth: true
            antialiasing: true
        }
    }

    function handleProceed() {
        createWindowComponent("qrc:/Main.qml")
    }

    Component.onCompleted: {
        root.flags = Qt.Window
        root.requestActivate()
        if (typeof COORDINATOR !== "undefined" && COORDINATOR) {
            COORDINATOR.show.connect(root.handleShow)
            COORDINATOR.proceed.connect(root.handleProceed)
            COORDINATOR.load()
        }
    }
}
