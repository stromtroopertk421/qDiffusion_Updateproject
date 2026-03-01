pragma Singleton
import QtQuick

QtObject {
    id: common

    readonly property real pointValue: 9.3
    readonly property real pointLabel: 9.4

    readonly property color bg00: "#1a1a1a"
    readonly property color bg00_5: "#1c1c1c"
    readonly property color bg0: "#1d1d1d"
    readonly property color bg0_5: "#202020"
    readonly property color bg1: "#242424"
    readonly property color bg1_5: "#272727"
    readonly property color bg2: "#2a2a2a"
    readonly property color bg2_5: "#2e2e2e"
    readonly property color bg3: "#303030"
    readonly property color bg3_5: "#393939"
    readonly property color bg4: "#404040"
    readonly property color bg5: "#505050"
    readonly property color bg6: "#606060"
    readonly property color bg7: "#707070"

    readonly property color fg0: "#ffffff"
    readonly property color fg1: "#eeeeee"
    readonly property color fg1_5: "#cccccc"
    readonly property color fg2: "#aaaaaa"
    readonly property color fg3: "#909090"

    readonly property var keys_basic: ["Ctrl+1", "F1"]
    readonly property var keys_models: ["Ctrl+2", "F2"]
    readonly property var keys_gallery: ["Ctrl+3", "F3"]
    readonly property var keys_merge: ["Ctrl+4", "F4"]
    readonly property var keys_train: ["Ctrl+5", "F5"]
    readonly property var keys_settings: ["Ctrl+0", "F12"]
    readonly property var keys_generate: ["Ctrl+`"]
    readonly property var keys_cancel: ["Ctrl+Backspace", "Ctrl+Escape", "Alt+`"]

    property var overlay: null

    readonly property FontLoader cantarellRegular: FontLoader { source: "qrc:/fonts/Cantarell-Regular.ttf" }
    readonly property FontLoader cantarellBold: FontLoader { source: "qrc:/fonts/Cantarell-Bold.ttf" }
    readonly property FontLoader sourceCodeRegular: FontLoader { source: "qrc:/fonts/SourceCodePro-Regular.ttf" }

    readonly property string sansFont: cantarellRegular.name !== "" ? cantarellRegular.name : "Cantarell"
    readonly property string monoFont: sourceCodeRegular.name !== "" ? sourceCodeRegular.name : "Source Code Pro"

    function accent(hue) {
        return Qt.hsva(hue, 0.65, 0.55, 1.0)
    }
}
