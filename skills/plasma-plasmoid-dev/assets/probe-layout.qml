// Offline layout probe. Run with:
//   QT_QPA_PLATFORM=offscreen QT_FORCE_STDERR_LOGGING=1 timeout 20 qml6 probe-layout.qml
//
// Layouts are computed even without a window, so this prints the real widths
// and heights the layout engine assigns. That is how you find a bar that
// collapsed to 1px because a sibling text column ate the space.
//
// Notes:
//  - console.log only reaches the terminal with QT_FORCE_STDERR_LOGGING=1.
//  - grabToImage does not reliably fire under the offscreen platform; measure
//    instead of screenshotting.
//  - Keep a plain Item root: no Window/ApplicationWindow needed.
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: win
    width: 378      // set to the popup content width you expect
    height: 400

    property var meters: [
        { label: "Rolling", used: 24000000,   limit: 1200000000, note: "Resets in 3h 57m" },
        { label: "Weekly",  used: 121384598,  limit: 3000000000, note: "Resets in 6d 10h" },
        { label: "Monthly", used: 2485719677, limit: 6000000000, note: "Resets in 19d 21h" }
    ]
    function fraction(m) { return Math.max(0, Math.min(1, m.used / m.limit)); }

    ColumnLayout {
        id: body
        width: parent.width
        spacing: Kirigami.Units.largeSpacing

        Repeater {
            model: win.meters

            delegate: RowLayout {
                required property var modelData
                Layout.fillWidth: true
                spacing: Kirigami.Units.largeSpacing

                // The trap: a label without Layout.maximumWidth reports the full
                // text width as implicit width and starves the bar below.
                ColumnLayout {
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 7
                    Layout.maximumWidth: Kirigami.Units.gridUnit * 7
                    spacing: 0
                    QQC2.Label { text: modelData.label }
                    QQC2.Label {
                        Layout.fillWidth: true
                        text: modelData.note
                        // NOT `font: Kirigami.Theme.smallFont`: on some themes that
                        // is the same size as the default font and you get no
                        // hierarchy at all. Step the point size down instead.
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize - 1
                        opacity: 0.6
                        elide: Text.ElideRight
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.minimumWidth: Kirigami.Units.gridUnit * 4
                    implicitHeight: Math.round(Kirigami.Units.gridUnit * 0.55)
                    radius: height / 2
                    color: "#333333"
                    Rectangle {
                        height: parent.height
                        radius: parent.radius
                        width: win.fraction(modelData) <= 0
                            ? 0
                            // Floor a small non-zero share to the radius so it
                            // reads as a sliver, not a slider knob; keep 0 at 0.
                            : Math.max(parent.radius, parent.width * win.fraction(modelData))
                        color: "#4ec26a"
                    }
                }

                QQC2.Label {
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                    Layout.maximumWidth: Kirigami.Units.gridUnit * 5
                    text: Math.round(win.fraction(modelData) * 100) + "% used"
                    horizontalAlignment: Text.AlignRight
                }
            }
        }
    }

    Timer {
        interval: 300
        running: true
        onTriggered: {
            console.log("gridUnit", Kirigami.Units.gridUnit,
                        "largeSpacing", Kirigami.Units.largeSpacing,
                        "smallSpacing", Kirigami.Units.smallSpacing);
            console.log("body implicitHeight", body.implicitHeight, "height", body.height);
            for (let r = 0; r < body.children.length; r++) {
                const row = body.children[r];
                if (!row.children || row.children.length < 3) continue;
                console.log("row", r,
                            "labelW", row.children[0].width,
                            "trackW", row.children[1].width,
                            "fillW", row.children[1].children[0].width,
                            "pctW", row.children[2].width);
            }
            Qt.quit();
        }
    }
}
