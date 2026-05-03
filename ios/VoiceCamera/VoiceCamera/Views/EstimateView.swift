import SwiftUI

struct EstimateView: View {
    @EnvironmentObject private var store: SessionStore

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Estimate mode", isOn: $store.session.estimateMode)
                    TextField("Assumptions", text: $store.session.estimate.assumptions, axis: .vertical)
                        .lineLimit(3...8)
                }

                Section("Line Items") {
                    ForEach($store.session.estimate.lineItems) { $item in
                        EstimateLineEditor(item: $item)
                    }
                    .onDelete { offsets in
                        store.session.estimate.lineItems.remove(atOffsets: offsets)
                    }

                    Button {
                        store.session.estimate.lineItems.append(
                            EstimateLineItem(description: "", quantity: 1, unit: "each", unitCost: 0)
                        )
                    } label: {
                        Label("Add line item", systemImage: "plus")
                    }
                }

                Section("Total") {
                    HStack {
                        Text("Estimate total")
                        Spacer()
                        Text(currency(store.session.estimate.total))
                            .fontWeight(.semibold)
                    }
                }

                Section("Share") {
                    ShareLink(item: estimateText) {
                        Label("Share estimate text", systemImage: "square.and.arrow.up")
                    }
                }
            }
            .navigationTitle("Estimate")
        }
    }

    private var estimateText: String {
        var lines = [
            store.session.title,
            "Estimate draft",
            "",
            store.session.estimate.assumptions,
            ""
        ]

        for item in store.session.estimate.lineItems {
            lines.append("\(item.description.isEmpty ? "Line item" : item.description): \(currency(item.total))")
        }

        lines.append("")
        lines.append("Total: \(currency(store.session.estimate.total))")
        return lines.joined(separator: "\n")
    }
}

struct EstimateLineEditor: View {
    @Binding var item: EstimateLineItem

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField("Description", text: $item.description)

            HStack {
                TextField("Qty", value: decimalBinding(\.quantity), format: .number)
                    .keyboardType(.decimalPad)
                TextField("Unit", text: $item.unit)
                TextField("Unit cost", value: decimalBinding(\.unitCost), format: .number)
                    .keyboardType(.decimalPad)
            }

            HStack {
                Text("Line total")
                Spacer()
                Text(currency(item.total))
                    .foregroundStyle(.secondary)
            }
            .font(.caption)
        }
    }

    private func decimalBinding(_ keyPath: WritableKeyPath<EstimateLineItem, Decimal>) -> Binding<Double> {
        Binding<Double>(
            get: { NSDecimalNumber(decimal: item[keyPath: keyPath]).doubleValue },
            set: { item[keyPath: keyPath] = Decimal($0) }
        )
    }
}

func currency(_ value: Decimal) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    return formatter.string(from: value as NSDecimalNumber) ?? "$0.00"
}
