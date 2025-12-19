import SwiftUI

#if canImport(FoundationModels)
import FoundationModels

@available(iOS 26.0, *)
struct PillAdvisorView: View {
    @State private var viewModel = PillAdvisorViewModel()
    @State private var inputText = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // 헤더
            header

            // 가용성 체크
            switch viewModel.modelAvailability {
            case .checking:
                ProgressView("모델 확인 중...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .available:
                availableView

            case .unavailable(let reason):
                unavailableView(reason: reason)
            }
        }
        .background(Color(.systemGroupedBackground))
        .task {
            await viewModel.initializeSession()
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "pills.fill")
                    .foregroundColor(.blue)
                Text("피임약 AI 어드바이저")
                    .font(.headline)
                Spacer()
            }
            .padding()

            DisclaimerBanner()
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Available View

    private var availableView: some View {
        VStack(spacing: 0) {
            // 대화 내역
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // 시작 메시지
                        if viewModel.messages.isEmpty {
                            welcomeMessage
                        }

                        // 메시지들
                        ForEach(viewModel.messages) { message in
                            MessageBubbleView(message: message)
                                .id(message.id)
                        }

                        // 현재 생성 중인 조언 (Streaming)
                        if let currentAdvice = viewModel.currentAdvice {
                            StreamingAdviceView(advice: currentAdvice)
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) { _ in
                    if let last = viewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            Divider()

            // 추천 질문 (대화 시작 전에만)
            if viewModel.messages.isEmpty && !viewModel.isResponding {
                predefinedQuestionsView
            }

            // 에러 메시지
            if let error = viewModel.errorMessage {
                ErrorBanner(message: error) {
                    viewModel.errorMessage = nil
                }
            }

            // 입력 영역
            inputArea
        }
    }

    // MARK: - Welcome Message

    private var welcomeMessage: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("👋 안녕하세요!")
                .font(.title3)
                .fontWeight(.semibold)

            Text("피임약 복용에 관해 궁금한 점을 물어보세요.")
                .foregroundColor(.secondary)

            Text("아래 버튼을 누르거나 직접 질문을 입력할 수 있습니다.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    // MARK: - Predefined Questions

    private var predefinedQuestionsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(PillAdvisorViewModel.PredefinedQuestion.allCases, id: \.self) { question in
                    Button {
                        Task {
                            await viewModel.askPredefined(question)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "questionmark.circle.fill")
                                .font(.caption)
                            Text(question.displayText)
                                .font(.subheadline)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Input Area

    private var inputArea: some View {
        HStack(spacing: 12) {
            TextField("질문을 입력하세요", text: $inputText)
                .textFieldStyle(.roundedBorder)
                .focused($isInputFocused)
                .disabled(viewModel.isResponding)

            Button {
                sendMessage()
            } label: {
                Image(systemName: viewModel.isResponding ? "stop.circle.fill" : "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundColor(canSend ? .blue : .gray)
            }
            .disabled(!canSend && !viewModel.isResponding)
        }
        .padding()
        .background(Color(.systemBackground))
    }

    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func sendMessage() {
        guard canSend else { return }

        let message = inputText
        inputText = ""
        isInputFocused = false

        Task {
            await viewModel.ask(question: message)
        }
    }

    // MARK: - Unavailable View

    private func unavailableView(reason: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)

            Text("AI 기능을 사용할 수 없습니다")
                .font(.title2)
                .fontWeight(.semibold)

            Text(reason)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("다시 확인") {
                viewModel.checkAvailability()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Message Bubble View

@available(iOS 26.0, *)
struct MessageBubbleView: View {
    let message: PillAdvisorViewModel.Message

    var body: some View {
        HStack {
            if message.isUser { Spacer() }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 8) {
                Text(message.text)
                    .padding(12)
                    .background(message.isUser ? Color.blue : Color(.secondarySystemGroupedBackground))
                    .foregroundColor(message.isUser ? .white : .primary)
                    .cornerRadius(16)

                // 조언 카드 (AI 메시지에만)
                if !message.isUser, let advice = message.advice {
                    AdviceCardView(advice: advice)
                }

                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            if !message.isUser { Spacer() }
        }
    }
}

// MARK: - Streaming Advice View

@available(iOS 26.0, *)
struct StreamingAdviceView: View {
    let advice: PillAdvice.PartiallyGenerated

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ProgressView()
                    .scaleEffect(0.8)
                Text("생성 중...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let answer = advice.answer {
                Text(answer)
                    .font(.body)
                    .foregroundColor(.primary)
            }

            if let warning = advice.warning {
                VStack(alignment: .leading, spacing: 4) {
                    Text("[주의]")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                    Text(warning)
                        .font(.subheadline)
                        .foregroundColor(.orange)
                }
                .padding(12)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(12)
        .transition(.opacity.combined(with: .scale))
    }
}

// MARK: - Advice Card View

@available(iOS 26.0, *)
struct AdviceCardView: View {
    let advice: PillAdvice.PartiallyGenerated

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let warning = advice.warning {
                VStack(alignment: .leading, spacing: 4) {
                    Text("[주의]")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                    Text(warning)
                        .font(.subheadline)
                        .foregroundColor(.orange)
                }
                .padding(12)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

// MARK: - Supporting Views

struct DisclaimerBanner: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle")
                .foregroundColor(.blue)
            Text("교육 목적의 정보입니다. 개인 맞춤 조언은 의료 전문가와 상담하세요.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.blue.opacity(0.1))
    }
}

struct ErrorBanner: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(message)
                .font(.subheadline)
            Spacer()
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.white)
            }
        }
        .padding()
        .background(Color.red)
        .foregroundColor(.white)
    }
}

// MARK: - Preview

@available(iOS 26.0, *)
#Preview {
    NavigationStack {
        PillAdvisorView()
            .navigationTitle("AI 어드바이저")
    }
}

#endif
