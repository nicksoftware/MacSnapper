import SwiftUI

/// Premium upgrade view for MacSnapper Pro
/// Beautiful, professional subscription interface highlighting premium features
struct UpgradeView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var subscriptionService: SubscriptionService

    // MARK: - State

    @State private var selectedPlan: SubscriptionPlan = .annual

    // MARK: - Body

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    headerSection

                    // Feature Comparison
                    featureComparisonSection

                    // Pricing Plans
                    pricingPlansSection

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
                ForEach(PremiumFeature.allCases, id: \.self) { feature in
                    FeatureRow(
                        feature: feature,
                        isIncluded: true
                    )
                }
            }
        }
    }

    // MARK: - Pricing Plans Section

    private var pricingPlansSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose Your Plan")
                .font(.title2)
                .fontWeight(.bold)

            VStack(spacing: 12) {
                ForEach(SubscriptionPlan.allCases, id: \.self) { plan in
                    PricingPlanCard(
                        plan: plan,
                        isSelected: selectedPlan == plan
                    ) {
                        selectedPlan = plan
                    }
                }
            }
        }
    }

    // MARK: - Action Buttons Section

    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            // Primary action button
            Button {
                Task {
                    await subscriptionService.activatePremium()
                    dismiss()
                }
            } label: {
                HStack {
                    Text("Upgrade to Pro")
                        .fontWeight(.semibold)

                    if subscriptionService.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(subscriptionService.isLoading)

            // Trial button
            if case .free = subscriptionService.subscriptionStatus {
                Button {
                    Task {
                        await subscriptionService.startTrial()
                        dismiss()
                    }
                } label: {
                    Text("Start 7-Day Free Trial")
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                }
                .buttonStyle(.bordered)
                .disabled(subscriptionService.isLoading)
            }

            // Restore button
            Button("Restore Purchase") {
                Task {
                    await subscriptionService.restorePurchase()
                }
            }
            .foregroundColor(.secondary)
            .disabled(subscriptionService.isLoading)
        }
    }

    // MARK: - Footer Section

    private var footerSection: some View {
        VStack(spacing: 8) {
            Text("• Cancel anytime in App Store settings")
            Text("• Premium features available immediately")
            Text("• Secure payment via Apple")
        }
        .font(.caption)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
    }
}

// MARK: - Feature Row Component

struct FeatureRow: View {
    let feature: PremiumFeature
    let isIncluded: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isIncluded ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(isIncluded ? .green : .red)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text(feature.displayName)
                    .font(.body)
                    .fontWeight(.medium)

                Text(feature.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Pricing Plan Card

struct PricingPlanCard: View {
    let plan: SubscriptionPlan
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(plan.displayName)
                            .font(.headline)
                            .fontWeight(.semibold)

                        if plan.isPopular {
                            Text("POPULAR")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(.orange)
                                .foregroundColor(.white)
                                .cornerRadius(4)
                        }
                    }

                    Text(plan.description)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let savings = plan.savings {
                        Text(savings)
                            .font(.caption)
                            .foregroundColor(.green)
                            .fontWeight(.medium)
                    }
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text(plan.price)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(plan.period)
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

// MARK: - Subscription Plan Enum

enum SubscriptionPlan: CaseIterable {
    case monthly
    case annual

    var displayName: String {
        switch self {
        case .monthly: return "Monthly"
        case .annual: return "Annual"
        }
    }

    var description: String {
        switch self {
        case .monthly: return "Perfect for trying out premium features"
        case .annual: return "Best value for long-term productivity"
        }
    }

    var price: String {
        switch self {
        case .monthly: return "$4.99"
        case .annual: return "$39.99"
        }
    }

    var period: String {
        switch self {
        case .monthly: return "per month"
        case .annual: return "per year"
        }
    }

    var savings: String? {
        switch self {
        case .monthly: return nil
        case .annual: return "Save 33% vs monthly"
        }
    }

    var isPopular: Bool {
        switch self {
        case .monthly: return false
        case .annual: return true
        }
    }
}

// MARK: - Preview

#Preview {
    UpgradeView()
        .environmentObject(DIContainer.shared.subscriptionService)
}