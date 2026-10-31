import Foundation
import Combine
import CoreBluetooth
import UserNotifications

final class FallGuardManager: NSObject, ObservableObject {
    private let serviceUUID = CBUUID(string: "7b2a0001-9e7d-4c3a-8f12-6d5e4a3b2100")
    private let eventUUID = CBUUID(string: "7b2a0002-9e7d-4c3a-8f12-6d5e4a3b2100")
    private let commandUUID = CBUUID(string: "7b2a0003-9e7d-4c3a-8f12-6d5e4a3b2100")

    @Published private(set) var isConnected = false
    @Published private(set) var alarmActive = false
    @Published private(set) var statusText = "Čaká sa na ESP32"
    @Published private(set) var lastEventText = "Zatiaľ nebola zaznamenaná žiadna udalosť."
    @Published private(set) var lastEventDate: Date?
    @Published private(set) var connectionText = "Vyhľadáva sa zariadenie…"

    private var central: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var eventCharacteristic: CBCharacteristic?
    private var commandCharacteristic: CBCharacteristic?
    private var shouldReconnect = true
    private var isScanning = false

    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: .main, options: [CBCentralManagerOptionShowPowerAlertKey: true])
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func startScanning() {
        shouldReconnect = true
        guard central.state == .poweredOn, !isConnected, !isScanning else { return }
        connectionText = "Vyhľadáva sa zariadenie…"
        isScanning = true
        central.scanForPeripherals(withServices: [serviceUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    }

    func cancelAlarm() {
        sendCommand("CANCEL")
        alarmActive = false
        statusText = "Alarm bol zrušený"
        lastEventText = "Požiadavka na zrušenie alarmu odoslaná"
        lastEventDate = Date()
    }

    private func sendCommand(_ command: String) {
        guard let peripheral, let characteristic = commandCharacteristic,
              let data = command.data(using: .utf8) else { return }
        let writeType: CBCharacteristicWriteType = characteristic.properties.contains(.write) ? .withResponse : .withoutResponse
        peripheral.writeValue(data, for: characteristic, type: writeType)
    }

    private func handleEvent(_ rawValue: String) {
        let event = rawValue.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        lastEventDate = Date()

        switch event {
        case "SYSTEM_PRIPRAVENY":
            statusText = "Systém je pripravený"
            lastEventText = "Systém je pripravený"
        case "PAD_DETEKTOVANY", "FALL_DETECTED":
            alarmActive = true
            statusText = "Pád zaznamenaný – skontrolujte používateľa"
            lastEventText = "Pád zaznamenaný"
            sendLocalNotification(
                title: "Pád zaznamenaný",
                body: "Zariadenie zaznamenalo možný pád. Skontrolujte, či je používateľ v poriadku."
            )
            sendCommand("ACK")
        case "TEST_ALARM_TLACIDLO":
            alarmActive = true
            statusText = "Pomoc bola privolaná"
            lastEventText = "Používateľ privolal pomoc tlačidlom"
            sendLocalNotification(
                title: "Žiadosť o pomoc – Osobný Strážca",
                body: "Používateľ aktivoval tlačidlo na privolanie pomoci. Skontrolujte, či potrebuje pomoc."
            )
            sendCommand("ACK")
        case "ALARM_ZRUSENY":
            alarmActive = false
            statusText = "Alarm bol zrušený"
            lastEventText = "Alarm bol zrušený"
        default:
            statusText = "Prijatá udalosť"
            lastEventText = "Prijatá neznáma udalosť"
        }
    }

    private func sendLocalNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    private func reconnectOrScan() {
        guard shouldReconnect, central.state == .poweredOn else { return }
        connectionText = "Opätovné pripájanie…"
        if let peripheral {
            central.connect(peripheral, options: nil)
        } else {
            startScanning()
        }
    }
}

extension FallGuardManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            startScanning()
        case .poweredOff:
            isConnected = false
            connectionText = "Bluetooth je vypnutý"
        case .unauthorized:
            isConnected = false
            connectionText = "Bluetooth nemá povolenie"
        case .unsupported:
            isConnected = false
            connectionText = "Bluetooth LE nie je podporované"
        case .resetting:
            connectionText = "Bluetooth sa reštartuje…"
        case .unknown:
            connectionText = "Kontroluje sa Bluetooth…"
        @unknown default:
            connectionText = "Neznámy stav Bluetooth"
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        guard self.peripheral == nil || self.peripheral?.identifier != peripheral.identifier else { return }
        self.peripheral = peripheral
        self.peripheral?.delegate = self
        central.stopScan()
        isScanning = false
        connectionText = "Pripája sa…"
        central.connect(peripheral, options: nil)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        isConnected = true
        connectionText = "Pripojené k \(peripheral.name ?? "ESP32")"
        statusText = "Načítava sa stav systému…"
        peripheral.discoverServices([serviceUUID])
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        isConnected = false
        connectionText = "Pripojenie zlyhalo – skúša sa znova"
        self.peripheral = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in self?.reconnectOrScan() }
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        isConnected = false
        eventCharacteristic = nil
        commandCharacteristic = nil
        connectionText = "Odpojené – opätovné pripájanie…"
        statusText = "Čaká sa na ESP32"
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in self?.reconnectOrScan() }
    }
}

extension FallGuardManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil, let services = peripheral.services else { return }
        for service in services where service.uuid == serviceUUID {
            peripheral.discoverCharacteristics([eventUUID, commandUUID], for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil, let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            if characteristic.uuid == eventUUID {
                eventCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
                peripheral.readValue(for: characteristic)
            } else if characteristic.uuid == commandUUID {
                commandCharacteristic = characteristic
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic.uuid == eventUUID, error == nil, characteristic.isNotifying {
            connectionText = "Pripojené k \(peripheral.name ?? "ESP32")"
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil, characteristic.uuid == eventUUID, let data = characteristic.value else { return }
        if let message = String(data: data, encoding: .utf8) {
            handleEvent(message)
        }
    }
}
