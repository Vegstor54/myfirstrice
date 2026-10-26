pragma Singleton
import QtQuick
import Quickshell

Singleton {
    readonly property color primary: "#b4c5ff"
    readonly property color primaryContainer: "#334478"
    readonly property color secondary: "#c1c5dd"
    readonly property color secondaryContainer: "#414659"
    readonly property color tertiary: "#e2bbdb"
    readonly property color tertiaryContainer: "#5b3d58"
    readonly property color surface: "#121318"
    readonly property color surfaceVariant: "#45464f"
    readonly property color surfaceContainer: "#1e1f25"
    readonly property color surfaceContainerHigh: "#292a2f"
    readonly property color surfaceContainerHighest: "#34343a"
    readonly property color error: "#ffb4ab"
    readonly property color errorContainer: "#93000a"
    readonly property color text: "#e3e2e9"
    readonly property color textOnPrimary: "#1b2d60"
    // Граница кнопок, плиток и дорожек ползунков: считается от цвета текста, поэтому видна и в тёмной, и в светлой теме
    readonly property color border: Qt.alpha(text, 0.35)
    // Заглушённая заливка ползунка: непрозрачная, чтобы не темнела под ручкой
    readonly property color mutedFill: Qt.tint(surfaceContainerHighest, Qt.alpha(text, 0.5))
}
