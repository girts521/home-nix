import QtQuick
import QtQuick.Effects
import "." as MockupComponents

Image {
    id: icon
    property string name: ""
    property string tone: "fg"
    property color tint: MockupComponents.Palette.toneColor(tone)
    property int size: 14
    // SVG icon variants are white monochrome masks; tint through MultiEffect.
    // Use the foreground mask for all variants and let tone select its palette color.
    source: Qt.resolvedUrl("icons/white/" + name + ".svg")
    layer.enabled: true
    layer.effect: MultiEffect {
        colorization: 1.0
        colorizationColor: icon.tint
    }
    onStatusChanged: if (status === Image.Error) console.warn("Icon asset missing:", source)
    sourceSize.width: size * 2
    sourceSize.height: size * 2
    width: size
    height: size
    fillMode: Image.PreserveAspectFit
    smooth: true
}
