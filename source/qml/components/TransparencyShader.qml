import QtQuick

Item {
    id: root

    property real gridSize: 15.0
    property bool styled: true

    Canvas {
        id: checkerboard
        anchors.fill: parent
        renderStrategy: Canvas.Cooperative

        onPaint: {
            var ctx = getContext("2d")
            var w = width
            var h = height
            var size = Math.max(1, root.gridSize)

            ctx.reset()
            ctx.clearRect(0, 0, w, h)

            var dark = root.styled ? "#1c1c1c" : "#333333"
            var light = root.styled ? "#1e1e1e" : "#666666"

            for (var y = 0; y < h; y += size) {
                for (var x = 0; x < w; x += size) {
                    var odd = (Math.floor(x / size) + Math.floor(y / size)) % 2
                    ctx.fillStyle = odd ? light : dark
                    ctx.fillRect(x, y, size, size)
                }
            }

            if (root.styled) {
                ctx.strokeStyle = "#2b2b2b"
                ctx.lineWidth = 1
                for (x = 0; x <= w; x += size) {
                    ctx.beginPath()
                    ctx.moveTo(Math.round(x) + 0.5, 0)
                    ctx.lineTo(Math.round(x) + 0.5, h)
                    ctx.stroke()
                }
                for (y = 0; y <= h; y += size) {
                    ctx.beginPath()
                    ctx.moveTo(0, Math.round(y) + 0.5)
                    ctx.lineTo(w, Math.round(y) + 0.5)
                    ctx.stroke()
                }

                var majorStep = size * 2
                ctx.strokeStyle = "#3a3a3a"
                for (x = 0; x <= w; x += majorStep) {
                    ctx.beginPath()
                    ctx.moveTo(Math.round(x) + 0.5, 0)
                    ctx.lineTo(Math.round(x) + 0.5, h)
                    ctx.stroke()
                }
                for (y = 0; y <= h; y += majorStep) {
                    ctx.beginPath()
                    ctx.moveTo(0, Math.round(y) + 0.5)
                    ctx.lineTo(w, Math.round(y) + 0.5)
                    ctx.stroke()
                }
            }
        }
    }

    onGridSizeChanged: checkerboard.requestPaint()
    onStyledChanged: checkerboard.requestPaint()
    onWidthChanged: checkerboard.requestPaint()
    onHeightChanged: checkerboard.requestPaint()
}
