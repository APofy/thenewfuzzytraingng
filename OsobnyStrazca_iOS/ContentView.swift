import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var fallGuard: FallGuardManager

    var body: some View {
        NavigationStack {
            VStack(spacing: 22) {
                Image(systemName: fallGuard.alarmActive ? "exclamationmark.shield.fill" : "shield.lefthalf.filled")
                    .font(.system(size: 46, weight: .regular))
                    .accessibilityHidden(true)

                Text("Osobný Strážca")
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)

                Text("Systém monitorovania pádov")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                VStack(spacing: 0) {
                    statusRow(
                        title: "Pripojenie Bluetooth",
                        value: fallGuard.connectionText,
                        symbol: fallGuard.isConnected ? "checkmark.circle.fill" : "antenna.radiowaves.left.and.right",
                        isGood: fallGuard.isConnected
                    )

                    Divider().padding(.leading, 16)

                    statusRow(
                        title: "Stav systému",
                        value: fallGuard.statusText,
                        symbol: fallGuard.alarmActive ? "exclamationmark.triangle.fill" : "checkmark.shield.fill",
                        isGood: !fallGuard.alarmActive
                    )
                }
                .background(Color(uiColor: .secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Posledná zaznamenaná udalosť")
                        .font(.headline)
                    Text(fallGuard.lastEventText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if let time = fallGuard.lastEventDate {
                        Text(time.formatted(date: .omitted, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color(uiColor: .secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))

                if fallGuard.alarmActive {
                    Button(role: .destructive) {
                        fallGuard.cancelAlarm()
                    } label: {
                        Label("Potvrdiť a zrušiť alarm", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }

                Button {
                    fallGuard.startScanning()
                } label: {
                    Label(fallGuard.isConnected ? "Pripojené" : "Vyhľadať zariadenie", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(fallGuard.isConnected)

                Spacer(minLength: 0)
            }
            .padding(20)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(uiColor: .systemBackground))
            .toolbar(.hidden, for: .navigationBar)
        }
        .task {
            fallGuard.requestNotificationPermission()
            fallGuard.startScanning()
        }
    }

    private func statusRow(title: String, value: String, symbol: String, isGood: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(isGood ? .green : .orange)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.subheadline.weight(.medium))
                Text(value).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            Circle()
                .fill(isGood ? Color.green : Color.orange)
                .frame(width: 8, height: 8)
        }
        .padding(16)
    }
}
