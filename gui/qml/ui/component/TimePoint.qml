import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

import FluentUI 1.0

import "qrc:/ui/global"
import "../global"

Item {
    id: item
    implicitWidth: 120
    implicitHeight: 65
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.minimumWidth: 0
    Layout.preferredWidth: 120

    property string functionName

    signal checkStateChanged

    function setChecked(state) {
        button.checked = state;
    }

    FluText {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: button.top
        anchors.bottomMargin: 6
        anchors.margins: 4
        text: item.functionName
        color: button.checked ? FluTheme.primaryColor : FluTheme.fontPrimaryColor
        font.bold: button.checked
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
    }

    FluRadioButton {
        id: button
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.bottom
        anchors.verticalCenterOffset: -14
        width: 28
        height: 28
        size: checked ? 24 : 18
        Accessible.name: item.functionName
        clickListener: function() { item.checkStateChanged(); }
    }
}
