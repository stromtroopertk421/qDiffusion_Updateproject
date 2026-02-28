import QtQuick 2.15
import QtQuick.Window 2.15
import gui 1.0

Window {
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

            var object = component.createObject(root, { window: root, spinner: spinner })
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

    Item {
        id: splashLayer
        anchors.fill: parent

        Image {
            id: spinner
            opacity: 0.5
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
