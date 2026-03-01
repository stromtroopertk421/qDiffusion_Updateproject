import QtQuick
import QtQuick.Controls

import gui 1.0

SText {
    id: control

    property var defaultText: null

    property variant bindMap: null
    property var bindKey: null

    property alias text: control.text

    property var readonly: true

    function display(text) {
        return text
    }

    Connections {
        target: bindMap
        function onUpdated(key) {
            if(key == bindKey) {
                var v = control.bindMap.get(control.bindKey)
                if(v != control.text) {
                    control.text = control.display(v)
                }
            }
        }
    }

    Component.onCompleted: {
        if(control.bindMap != null && control.bindKey != null) {
            control.text = control.display(control.bindMap.get(control.bindKey))
        }
        if(control.defaultText == null) {
            control.defaultText = control.text;
        }
    }

    onTextChanged: {
        if (!readonly) {
            if(control.bindMap != null && control.bindKey != null) {
                control.bindMap.set(control.bindKey, control.text)
            }
        }
    }
}