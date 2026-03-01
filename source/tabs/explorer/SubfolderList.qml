import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import gui

import "../compat"
import "../../style"
import "../../components"

ListView {
    id: root
    interactive: false
    width: parent.width
    height: contentHeight
    property var index: 0
    property var mode: ""

    signal move(string model, string folder, string subfolder)

    model: Sql {
        query: "SELECT DISTINCT folder FROM models WHERE category = '" + root.mode + "' AND folder != '' ORDER BY folder ASC;"
    }

    delegate: Item {
        required property string modelData

        x: 10
        width: root.width - 2*x
        height: 25
        SColumnButton {
            id: button
            label: parent.modelData
            height: 25
            width: parent.width
            active: EXPLORER.currentTab == root.mode && EXPLORER.currentFolder == parent.modelData
            onPressed: {
                EXPLORER.setCurrent(root.mode, parent.modelData)
            }
            AdvancedDropArea {
                id: basicDrop
                anchors.fill: parent
                onContainsDragChanged: {
                    if(containsDrag) {
                        dragTimer.start()
                    } else {
                        dragTimer.stop()
                    }
                }
                Timer {
                    id: dragTimer
                    interval: 200
                    onTriggered: {
                        EXPLORER.setCurrent(root.mode, parent.modelData)
                    }
                }
                onDropped: {
                    var model = EXPLORER.onDrop(mimeData)
                    if(model != "") {
                        root.move(model, root.mode, parent.modelData)
                    }
                }
            }
        }
    }
}
