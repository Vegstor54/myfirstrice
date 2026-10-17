pragma Singleton
import QtQuick
import Quickshell

Singleton {
    readonly property color primary: "{{colors.primary.default.hex}}"
    readonly property color primaryContainer: "{{colors.primary_container.default.hex}}"
    readonly property color secondary: "{{colors.secondary.default.hex}}"
    readonly property color secondaryContainer: "{{colors.secondary_container.default.hex}}"
    readonly property color tertiary: "{{colors.tertiary.default.hex}}"
    readonly property color tertiaryContainer: "{{colors.tertiary_container.default.hex}}"
    readonly property color surface: "{{colors.surface.default.hex}}"
    readonly property color surfaceVariant: "{{colors.surface_variant.default.hex}}"
    readonly property color surfaceContainer: "{{colors.surface_container.default.hex}}"
    readonly property color surfaceContainerHigh: "{{colors.surface_container_high.default.hex}}"
    readonly property color surfaceContainerHighest: "{{colors.surface_container_highest.default.hex}}"
    readonly property color error: "{{colors.error.default.hex}}"
    readonly property color errorContainer: "{{colors.error_container.default.hex}}"
    readonly property color text: "{{colors.on_surface.default.hex}}"
    readonly property color textOnPrimary: "{{colors.on_primary.default.hex}}"
}
