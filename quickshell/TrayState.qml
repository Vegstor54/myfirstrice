pragma Singleton
import Quickshell

// Общее состояние меню трея для всех мониторов: чей значок открыт и на каком экране.
// Открытым бывает только одно меню на всю оболочку (BarTray.qml).
Singleton {
    property var openItem: null
    property string screenName: ""
}
