import QtQuick

Image {
    id: icon
    property string name: ""
    property string tone: "fg"
    property int size: 14
    source: Qt.resolvedUrl("icons/" + tone + "/" + name + ".svg")
    onStatusChanged: if (status === Image.Error) console.warn("Icon asset missing:", source)
    sourceSize.width: size * 2
    sourceSize.height: size * 2
    width: size
    height: size
    fillMode: Image.PreserveAspectFit
    smooth: true
}
