import QtQuick
import QtQuick.Controls

ApplicationWindow {
    id: root
    visible: true
    width: 1100
    height: 600
    color: "#1a1a1a"
    title: "qDiffusion"
    flags: Qt.Window | Qt.WindowStaysOnTopHint

    property Item spinner: null

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

            var object = component.createObject(root, { window: root, spinner: root.spinner })
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

    Component {
        id: spinnerComponent

        Image {
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
        root.spinner = spinnerComponent.createObject(root.contentItem)
        if (root.spinner === null) {
            console.error("ERROR", "Failed to create splash spinner")
        }

        root.requestActivate()
        if (typeof COORDINATOR !== "undefined" && COORDINATOR) {
            COORDINATOR.show.connect(root.handleShow)
            COORDINATOR.proceed.connect(root.handleProceed)
            COORDINATOR.load()
        }
    }
}
