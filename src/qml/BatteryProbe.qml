import QtQuick 1.1
import QtMobility.systeminfo 1.1

// Battery level from Qt Mobility (loaded with a Loader: if the module is
// missing, the app treats the battery as fine).
Item {
    property int level: info.batteryLevel
    property bool charging: info.currentPowerState == DeviceInfo.WallPowerChargingBattery
                            || info.currentPowerState == DeviceInfo.WallPower
    DeviceInfo {
        id: info
        monitorBatteryLevelChanges: true
        monitorPowerStateChanges: true
    }
}
