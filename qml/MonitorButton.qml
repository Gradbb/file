//Copyright (c) 2018 QIDI B.V.
//QIDI is released under the terms of the LGPLv3 or higher.

import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1
import QtQuick.Dialogs 1.1
import QtQuick.Layouts 1.1

import QD 1.1 as QD
import QIDI 1.0 as QIDI

Item
{
    id: base;
    QD.I18nCatalog { id: catalog; name: "qidi"}

    height: childrenRect.height + QD.Theme.getSize("thick_margin").height

    property bool printerConnected: QIDI.MachineManager.printerConnected
    property bool printerAcceptsCommands: printerConnected && QIDI.MachineManager.printerOutputDevices[0].acceptsCommands
    property var activePrinter: printerConnected ? QIDI.MachineManager.printerOutputDevices[0].activePrinter : null
    property var activePrintJob: activePrinter ? activePrinter.activePrintJob: null
    property real progress:
    {
        if(!printerConnected)
        {
            return 0
        }
        if(activePrinter == null)
        {
            return 0
        }
        if(activePrintJob == null)
        {
            return 0
        }
        if(activePrintJob.timeTotal == 0)
        {
            return 0  // Prevent devision by 0
        }
        return activePrintJob.timeElapsed / activePrintJob.timeTotal * 100
    }

    property int backendState: QD.Backend.state

    property bool showProgress: {
        // determine if we need to show the progress bar + percentage
        if(activePrintJob == null)
        {
            return false;
        }

        switch(base.activePrintJob.state)
        {
            case "printing":
            case "paused":
            case "pausing":
            case "resuming":
                return true;
            case "pre_print":  // heating, etc.
            case "wait_cleanup":
            case "offline":
            case "abort":  // note sure if this jobState actually occurs in the wild
            case "error":  // after clicking abort you apparently get "error"
            case "ready":  // ready to print or getting ready
            case "":  // ready to print or getting ready
            default:
                return false;
        }
    }

    property variant statusColor:
    {
        if(!printerConnected || !printerAcceptsCommands || activePrinter == null)
        {
            return QD.Theme.getColor("text");
        }

        switch(activePrinter.state)
        {
            case "maintenance":
                return QD.Theme.getColor("status_busy");
            case "error":
                return QD.Theme.getColor("status_stopped");
        }
        if(base.activePrintJob == null)
        {
            return QD.Theme.getColor("text");
        }
        switch(base.activePrintJob.state)
        {
            case "printing":
            case "pre_print":
            case "wait_cleanup":
            case "pausing":
            case "resuming":
                return QD.Theme.getColor("status_busy");
            case "ready":
            case "":
                return QD.Theme.getColor("status_ready");
            case "paused":
                return QD.Theme.getColor("status_paused");
            case "error":
                return QD.Theme.getColor("status_stopped");
            case "offline":
                return QD.Theme.getColor("status_offline");
            default:
                return QD.Theme.getColor("text");
        }
    }

    property bool activity: QIDIApplication.platformActivity;
    property string fileBaseName
    property string statusText:
    {
        if(!printerConnected)
        {
            return catalog.i18nc("@label:MonitorStatus", "Not connected to a printer");
        }
        if(!printerAcceptsCommands)
        {
            return catalog.i18nc("@label:MonitorStatus", "Printer does not accept commands");
        }

        var printerOutputDevice = QIDI.MachineManager.printerOutputDevices[0]
        if(activePrinter == null)
        {
            return "";
        }
        if(activePrinter.state == "maintenance")
        {
            return catalog.i18nc("@label:MonitorStatus", "In maintenance. Please check the printer");
        }

        if(base.activePrintJob == null)
        {
            return " "
        }

        switch(base.activePrintJob.state)
        {
            case "offline":
                return catalog.i18nc("@label:MonitorStatus", "Lost connection with the printer");
            case "printing":
                return catalog.i18nc("@label:MonitorStatus", "Printing...");
            //TODO: Add text for case "pausing".
            case "paused":
                return catalog.i18nc("@label:MonitorStatus", "Paused");
            //TODO: Add text for case "resuming".
            case "pre_print":
                return catalog.i18nc("@label:MonitorStatus", "Preparing...");
            case "wait_cleanup":
                return catalog.i18nc("@label:MonitorStatus", "Please remove the print");
            case "error":
                return printerOutputDevice.errorText;
            default:
                return " ";
        }
    }

    Label
    {
        id: statusLabel
        width: parent.width - 2 * QD.Theme.getSize("thick_margin").width
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.leftMargin: QD.Theme.getSize("thick_margin").width

        color: base.statusColor
        font: QD.Theme.getFont("large_bold")
        text: statusText
    }

    Label
    {
        id: percentageLabel
        anchors.top: parent.top
        anchors.right: progressBar.right

        color: base.statusColor
        font: QD.Theme.getFont("large_bold")
        text: Math.round(progress) + "%"
        visible: showProgress
    }

    ProgressBar
    {
        id: progressBar;
        minimumValue: 0;
        maximumValue: 100;
        value: 0;

        //Doing this in an explicit binding since the implicit binding breaks on occasion.
        Binding
        {
            target: progressBar;
            property: "value";
            value: base.progress;
        }

        visible: showProgress;
        indeterminate:
        {
            if(!printerConnected)
            {
                return false;
            }
            if(base.activePrintJob == null)
            {
                return false
            }
            switch(base.activePrintJob.state)
            {
                case "pausing":
                case "resuming":
                    return true;
                default:
                    return false;
            }
        }
        style: QD.Theme.styles.progressbar;

        property string backgroundColor: QD.Theme.getColor("progressbar_background");
        property string controlColor: base.statusColor;

        width: parent.width - 2 * QD.Theme.getSize("thick_margin").width;
        height: QD.Theme.getSize("progressbar").height;
        anchors.top: statusLabel.bottom;
        anchors.topMargin: Math.round(QD.Theme.getSize("thick_margin").height / 4);
        anchors.left: parent.left;
        anchors.leftMargin: QD.Theme.getSize("thick_margin").width;
    }

    Row
    {
        id: buttonsRow
        height: abortButton.height
        anchors.top: progressBar.bottom
        anchors.topMargin: QD.Theme.getSize("thick_margin").height
        anchors.right: parent.right
        anchors.rightMargin: QD.Theme.getSize("thick_margin").width
        spacing: QD.Theme.getSize("default_margin").width

        Row
        {
            id: additionalComponentsRow
            spacing: QD.Theme.getSize("default_margin").width
        }

        Component.onCompleted: {
            buttonsRow.updateAdditionalComponents("monitorButtons")
        }

        Connections
        {
            target: QIDIApplication
            function onAdditionalComponentsChanged() { buttonsRow.updateAdditionalComponents("monitorButtons") }
        }

        function updateAdditionalComponents (areaId) {
            if(areaId == "monitorButtons") {
                for (var component in QIDIApplication.additionalComponents["monitorButtons"]) {
                    QIDIApplication.additionalComponents["monitorButtons"][component].parent = additionalComponentsRow
                }
            }
        }

        Button
        {
            id: pauseResumeButton

            height: QD.Theme.getSize("save_button_save_to_button").height

            property bool userClicked: false
            property string lastJobState: ""

            visible: printerConnected && activePrinter != null &&activePrinter.canPause
            enabled: (!userClicked) && printerConnected && printerAcceptsCommands && activePrintJob != null &&
                     (["paused", "printing"].indexOf(activePrintJob.state) >= 0)

            text: {
                if (!printerConnected || activePrintJob == null)
                {
                   return catalog.i18nc("@label", "Pause");
                }

                if (activePrintJob.state == "paused")
                {
                    return catalog.i18nc("@label", "Resume");
                }
                else
                {
                    return catalog.i18nc("@label", "Pause");
                }
            }
            onClicked:
            {
                if(activePrintJob == null)
                {
                    return // Do nothing!
                }
                if(activePrintJob.state == "paused")
                {
                    activePrintJob.setState("print");
                }
                else if(activePrintJob.state == "printing")
                {
                    activePrintJob.setState("pause");
                }
            }

            style: QD.Theme.styles.print_setup_action_button
        }

        Button
        {
            id: abortButton

            visible: printerConnected && activePrinter != null && activePrinter.canAbort
            enabled: printerConnected && printerAcceptsCommands && activePrintJob != null &&
                     (["paused", "printing", "pre_print"].indexOf(activePrintJob.state) >= 0)

            height: QD.Theme.getSize("save_button_save_to_button").height

            text: catalog.i18nc("@label", "Abort Print")
            onClicked: confirmationDialog.visible = true

            style: QD.Theme.styles.print_setup_action_button
        }

        MessageDialog
        {
            id: confirmationDialog

            title: catalog.i18nc("@window:title", "Abort print")
            icon: StandardIcon.Warning
            text: catalog.i18nc("@label", "Are you sure you want to abort the print?")
            standardButtons: StandardButton.Yes | StandardButton.No
            Component.onCompleted: visible = false
            onYes: activePrintJob.setState("abort")
        }
    }
}
