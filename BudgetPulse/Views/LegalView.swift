//
//  LegalView.swift
//  BudgetPulse
//

import SwiftUI

// MARK: - Privacy Policy View

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(L("privacy_policy"))
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text(L("last_updated"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    // Sections
                    legalSection(
                        title: L("privacy_section_1_title"),
                        content: L("privacy_section_1_content")
                    )

                    legalSection(
                        title: L("privacy_section_2_title"),
                        content: L("privacy_section_2_content")
                    )

                    legalSection(
                        title: L("privacy_section_3_title"),
                        content: L("privacy_section_3_content")
                    )

                    legalSection(
                        title: L("privacy_section_4_title"),
                        content: L("privacy_section_4_content")
                    )

                    legalSection(
                        title: L("privacy_section_5_title"),
                        content: L("privacy_section_5_content")
                    )

                    // Contact
                    VStack(alignment: .leading, spacing: 8) {
                        Text(L("contact_us"))
                            .font(.headline)

                        Text(L("privacy_contact_content"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L("done")) {
                        dismiss()
                    }
                }
            }
        }
    }

    private func legalSection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            Text(content)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Terms of Use View

struct TermsOfUseView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(L("terms_of_use"))
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text(L("last_updated"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    // Sections
                    legalSection(
                        title: L("terms_section_1_title"),
                        content: L("terms_section_1_content")
                    )

                    legalSection(
                        title: L("terms_section_2_title"),
                        content: L("terms_section_2_content")
                    )

                    legalSection(
                        title: L("terms_section_3_title"),
                        content: L("terms_section_3_content")
                    )

                    legalSection(
                        title: L("terms_section_4_title"),
                        content: L("terms_section_4_content")
                    )

                    legalSection(
                        title: L("terms_section_5_title"),
                        content: L("terms_section_5_content")
                    )

                    legalSection(
                        title: L("terms_section_6_title"),
                        content: L("terms_section_6_content")
                    )

                    // Contact
                    VStack(alignment: .leading, spacing: 8) {
                        Text(L("contact_us"))
                            .font(.headline)

                        Text(L("terms_contact_content"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L("done")) {
                        dismiss()
                    }
                }
            }
        }
    }

    private func legalSection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            Text(content)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Disclaimer View

struct DisclaimerView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(L("disclaimer"))
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text(L("last_updated"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    // Sections
                    legalSection(
                        title: L("disclaimer_section_1_title"),
                        content: L("disclaimer_section_1_content")
                    )

                    legalSection(
                        title: L("disclaimer_section_2_title"),
                        content: L("disclaimer_section_2_content")
                    )

                    legalSection(
                        title: L("disclaimer_section_3_title"),
                        content: L("disclaimer_section_3_content")
                    )

                    legalSection(
                        title: L("disclaimer_section_4_title"),
                        content: L("disclaimer_section_4_content")
                    )
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L("done")) {
                        dismiss()
                    }
                }
            }
        }
    }

    private func legalSection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            Text(content)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview("Privacy Policy") {
    PrivacyPolicyView()
}

#Preview("Terms of Use") {
    TermsOfUseView()
}

#Preview("Disclaimer") {
    DisclaimerView()
}
