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

    function createSpinner() {
        var spinnerQml = 'import QtQuick\nImage {\n' +
            '    opacity: 0.5\n' +
            '    source: "icons/loading.svg"\n' +
            '    width: 80\n' +
            '    height: 80\n' +
            '    sourceSize: Qt.size(width, height)\n' +
            '    anchors.centerIn: parent\n' +
            '    smooth: true\n' +
            '    antialiasing: true\n' +
            '}'

        root.spinner = Qt.createQmlObject(spinnerQml, root.contentItem, "SplashSpinner")
        if (root.spinner === null) {
            console.error("ERROR", "Failed to create splash spinner")
        }
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
