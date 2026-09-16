import SwiftUI

struct ContentView: View {
    @EnvironmentObject var monitor: ClipboardMonitor
    @State private var hoveredItemID: UUID?
    @FocusState private var searchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            header
            searchBar

            if monitor.filteredItems.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(monitor.filteredItems) { item in
                            ClipboardItemRow(
                                item: item,
                                isHovered: hoveredItemID == item.id
                            )
                            .onHover { hovering in
                                hoveredItemID = hovering ? item.id : nil
                            }
                            .onTapGesture {
                                monitor.copyToClipboard(item)
                                NSApp.keyWindow?.close()
                            }
                        }
                    }
                    .padding(8)
                }
            }

            footer
        }
        .frame(width: 380, height: 480)
        .background(.ultraThinMaterial)
        .onAppear { searchFocused = true }
    }

    private var header: some View {
        HStack {
            Image(systemName: "doc.on.clipboard.fill")
                .foregroundStyle(.tint)
            Text("Clipboard")
                .font(.system(size: 14, weight: .semibold))
            Spacer()
            Text("\(monitor.items.count)")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.15), in: Capsule())
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private var searchBar: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .font(.system(size: 12))
            TextField("Search…", text: $monitor.searchQuery)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .focused($searchFocused)
            if !monitor.searchQuery.isEmpty {
                Button {
                    monitor.searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal, 14)
        .padding(.bottom, 8)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: monitor.searchQuery.isEmpty ? "clipboard" : "magnifyingglass")
                .font(.system(size: 32))
                .foregroundStyle(.tertiary)
            Text(monitor.searchQuery.isEmpty ? "No items copied yet" : "No results")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var footer: some View {
        HStack {
            Button(role: .destructive) {
                monitor.clearHistory(keepPinned: true)
            } label: {
                Text("Clear history")
                    .font(.system(size: 11))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)

            Spacer()

            Text("⌘⇧V to open")
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.primary.opacity(0.03))
    }
}
