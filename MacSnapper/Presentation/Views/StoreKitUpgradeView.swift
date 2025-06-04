import SwiftUI
import StoreKit

/// Real StoreKit upgrade view for MacSnapper Pro
/// Uses actual App Store products and pricing for real revenue generation
@available(macOS 12.0, *)
struct StoreKitUpgradeView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @StateObject private var storeKitService = StoreKitSubscriptionService()

    // MARK: - State

    @State private var selectedProduct: Product?

    // MARK: - Body

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    headerSection

                    // Feature Comparison
                    featureComparisonSection

                    // Real Products from App Store
                    if !storeKitService.availableProducts.isEmpty {
                        productsSection
                    } else {
                        loadingProductsSection
                    }

                    // Action Buttons
                    actionButtonsSection

                    // Footer
                    footerSection
                }
                .padding()
            }
            .navigationTitle("Upgrade to Pro")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 500, minHeight: 700)
        .onAppear {
            // Auto-select annual plan if available
            if selectedProduct == nil {
                selectedProduct = storeKitService.availableProducts.first {
                    $0.id.contains("annual")
                }
            }
        }
        .alert("Error", isPresented: .constant(storeKitService.lastError != nil)) {
            Button("OK") {
                storeKitService.clearError()
            }
        } message: {
            Text(storeKitService.lastError?.localizedDescription ?? "")
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "crown.fill")
                .font(.system(size: 64))
                .foregroundStyle(.orange.gradient)

            Text("MacSnapper Pro")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Unlock the full potential of window management")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Feature Comparison Section

    private var featureComparisonSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What's Included")
                .font(.title2)
                .fontWeight(.bold)

            VStack(spacing: 12) {
                ForEach(storeKitService.getPremiumFeatures(), id: \.self) { feature in
                    FeatureRow(
                        feature: feature,
                        isIncluded: true
                    )
                }
            }
        }
    }

    // MARK: - Real Products Section

    private var productsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose Your Plan")
                .font(.title2)
                .fontWeight(.bold)

            VStack(spacing: 12) {
                ForEach(storeKitService.availableProducts, id: \.id) { product in
                    RealProductCard(
                        product: product,
                        isSelected: selectedProduct?.id == product.id
                    ) {
                        selectedProduct = product
                    }
                }
            }
        }
    }

    // MARK: - Loading Products Section

    private var loadingProductsSection: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)

            Text("Loading subscription options...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(height: 100)
    }

    // MARK: - Action Buttons Section

    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            // Purchase button
            if let selectedProduct = selectedProduct {
                Button {
                    Task {
                        let success = await storeKitService.purchase(selectedProduct)
                        if success {
                            dismiss()
                        }
                    }
                } label: {
                    HStack {
                        Text("Subscribe for \(selectedProduct.displayPrice)")
                            .fontWeight(.semibold)

                        if storeKitService.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(storeKitService.isLoading)
            }

            // Trial button
            if case .free = storeKitService.subscriptionStatus {
                Button {
                    Task {
                        await storeKitService.startTrial()
                        dismiss()
                    }
                } label: {
                    Text("Start 7-Day Free Trial")
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                }
                .buttonStyle(.bordered)
                .disabled(storeKitService.isLoading)
            }

            // Restore button
            Button("Restore Purchase") {
                Task {
                    await storeKitService.restorePurchases()
                }
            }
            .foregroundColor(.secondary)
            .disabled(storeKitService.isLoading)
        }
    }

    // MARK: - Footer Section

    private var footerSection: some View {
        VStack(spacing: 8) {
            Text("• Cancel anytime in App Store settings")
            Text("• Premium features available immediately")
            Text("• Secure payment via Apple")
            Text("• Works across all your devices")
        }
        .font(.caption)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
    }
}

// MARK: - Real Product Card

@available(macOS 12.0, *)
struct RealProductCard: View {
    let product: Product
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(product.displayName)
                            .font(.headline)
                            .fontWeight(.semibold)

                        if product.id.contains("annual") {
                            Text("BEST VALUE")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(.orange)
                                .foregroundColor(.white)
                                .cornerRadius(4)
                        }
                    }

                    Text(product.description)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if product.id.contains("annual") {
                        Text("Save 33% vs monthly")
                            .font(.caption)
                            .foregroundColor(.green)
                            .fontWeight(.medium)
                    }
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text(product.displayPrice)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(product.id.contains("monthly") ? "per month" : "per year")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(isSelected ? .blue.opacity(0.1) : .clear)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? .blue : .secondary.opacity(0.3), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Feature Row Component
// Note: FeatureRow is defined in UpgradeView.swift and reused here

// MARK: - Preview

@available(macOS 12.0, *)
#Preview {
    StoreKitUpgradeView()
}