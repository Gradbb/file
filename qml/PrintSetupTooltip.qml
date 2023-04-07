// Copyright (c) 2020 QIDI B.V.
// QIDI is released under the terms of the LGPLv3 or higher.

import QtQuick 2.7
import QtQuick.Controls 2.3

import QD 1.0 as QD

QD.PointingRectangle
{
    id: base
    property real sourceWidth: 0
    width: QD.Theme.getSize("tooltip").width
    height: textScroll.height + QD.Theme.getSize("tooltip_margins").height * 2
    color: QD.Theme.getColor("tooltip")

    arrowSize: QD.Theme.getSize("default_arrow").width

    opacity: 0

    Behavior on opacity
    {
        NumberAnimation { duration: 100; }
    }

    property alias text: label.text

    function show(position)
    {
        if(position.y + base.height > parent.height)
        {
            x = position.x - base.width;
            y = parent.height - base.height;
        } else
        {
            var new_x = x = position.x - base.width

            // If the tooltip would fall out of the screen, display it on the other side.
            if(new_x < 0)
            {
                new_x = x + sourceWidth + base.width
            }

            x = new_x

            y = position.y - QD.Theme.getSize("tooltip_arrow_margins").height;
            if(y < 0)
            {
                position.y += -y;
                y = 0;
            }
        }
        base.opacity = 1;
        target = Qt.point(position.x + 1, position.y + Math.round(QD.Theme.getSize("tooltip_arrow_margins").height / 2))
    }

    function hide()
    {
        base.opacity = 0;
    }

    MouseArea
    {
        enabled: parent.opacity > 0
        visible: enabled
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        hoverEnabled: true
        onHoveredChanged:
        {
            if(containsMouse && base.opacity > 0)
            {
                base.show(Qt.point(target.x - 1, target.y - QD.Theme.getSize("tooltip_arrow_margins").height / 2)); //Same arrow position as before.
            }
            else
            {
                base.hide();
            }
        }

        ScrollView
        {
            id: textScroll
            width: parent.width
            height: Math.min(label.height, base.parent.height)

            ScrollBar.horizontal: ScrollBar {
                active: false //Only allow vertical scrolling. We should grow vertically only, but due to how the label is positioned it allocates space in the ScrollView horizontally.
            }

            Label
            {
                id: label
                x: QD.Theme.getSize("tooltip_margins").width
                y: QD.Theme.getSize("tooltip_margins").height
                width: base.width - QD.Theme.getSize("tooltip_margins").width * 2

                wrapMode: Text.Wrap;
                textFormat: Text.RichText
                font: QD.Theme.getFont("default");
                color: QD.Theme.getColor("tooltip_text");
                renderType: Text.NativeRendering
            }
        }
    }
}
