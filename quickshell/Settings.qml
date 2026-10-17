pragma Singleton
import Quickshell
import Quickshell.Io

Singleton {
    property alias barColor: adapter.barColor

    FileView {
        path: Quickshell.env("HOME") + "/.config/quickshell/settings.json"
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()

        JsonAdapter {
            id: adapter
            property string barColor: "primaryContainer"
        }
    }
}
