import QtQuick 2.15
import QtQuick.Controls 2.15
import gui 1.0

ApplicationWindow {
    id: root
    visible: true
    width: 1100
    height: 600
    color: "#1a1a1a"
    title: (typeof TRANSLATOR !== "undefined" && TRANSLATOR && TRANSLATOR.instance) ? TRANSLATOR.instance.translate("qDiffusion", "Title") : "qDiffusion"
    flags: Qt.Window | Qt.WindowStaysOnTopHint

    function handleShow() {
        var component = Qt.createComponent("qrc:/Installer.qml")
        if (component.status !== Component.Ready) {
            console.log("ERROR", component.errorString())
        } else {
            component.incubateObject(root, { window: root, spinner: null })
        }
    }

    function handleProceed() {
        var component = Qt.createComponent("qrc:/Main.qml")
        if (component.status !== Component.Ready) {
            console.log("ERROR", component.errorString())
        } else {
            component.incubateObject(root, { window: root, spinner: null })
        }
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
