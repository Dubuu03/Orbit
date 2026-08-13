import SwiftUI

struct ContentView: View {
    @State private var runner: WorkspaceRunner
    private let workspace: Workspace

    init(
        configuration: AppConfiguration = .default,
        store: WorkspaceStore? = nil
    ) {
        let resolvedStore = store ?? WorkspaceStore.defaultStore(configuration: configuration)
        self.workspace = resolvedStore.workspaces.first ?? Workspace(name: "Work", actions: [])
        _runner = State(initialValue: WorkspaceRunner(configuration: configuration))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header
            actionList
            logList
        }
        .padding(24)
        .frame(minWidth: 560, minHeight: 520)
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Orbit")
                    .font(.title.bold())
                Text("Work Workspace")
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                Task {
                    await runner.run(workspace)
                }
            } label: {
                Label(buttonTitle, systemImage: "play.fill")
            }
            .buttonStyle(.borderedProminent)
            .disabled(runner.runState == .running)
        }
    }

    private var actionList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Actions")
                .font(.headline)

            ForEach(runner.actionStates.isEmpty ? workspace.actions.map { ActionExecutionState(action: $0) } : runner.actionStates) { state in
                HStack(spacing: 10) {
                    Image(systemName: iconName(for: state.status))
                        .foregroundStyle(color(for: state.status))
                        .frame(width: 18)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(state.title)
                        if let message = state.message {
                            Text(message)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    if !state.isCritical {
                        Text("Optional")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var logList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Log")
                .font(.headline)

            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(runner.logMessages.enumerated()), id: \.offset) { _, message in
                        Text(message)
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .frame(minHeight: 120)
        }
    }

    private var buttonTitle: String {
        switch runner.runState {
        case .running:
            return "Running"
        case .completed:
            return "Run Again"
        case .failed, .idle:
            return "Run Work"
        }
    }

    private func iconName(for status: ActionExecutionStatus) -> String {
        switch status {
        case .pending:
            return "circle"
        case .running:
            return "clock"
        case .success:
            return "checkmark.circle.fill"
        case .failed:
            return "xmark.circle.fill"
        case .skipped:
            return "minus.circle.fill"
        }
    }

    private func color(for status: ActionExecutionStatus) -> Color {
        switch status {
        case .pending:
            return .secondary
        case .running:
            return .blue
        case .success:
            return .green
        case .failed:
            return .red
        case .skipped:
            return .orange
        }
    }
}

#Preview {
    ContentView()
}
