import SwiftUI

@MainActor
struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel

    let dismiss: () async -> Void
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                VStack(spacing: 10) {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .foregroundColor(Color(UIColor.systemGray4))
                        .frame(width: 120, height: 120)
                    
                    VStack(spacing: 0) {
                        Text(viewModel.user?.name ?? "User Name")
                            .font(.title3)
                            .redacted(reason: viewModel.user?.name == nil ? .placeholder : [])
                        Text((viewModel.user?.id.rawValue).map { id in "@\(id)" } ?? "@ididid")
                            .font(.body)
                            .foregroundColor(Color(UIColor.systemGray))
                            .redacted(reason: viewModel.user?.id == nil ? .placeholder : [])
                    }
                    
                    let introduction = viewModel.user?.introduction ?? "Introduction. Introduction. Introduction. Introduction. Introduction. Introduction."
                    if let attributedIntroduction = try? AttributedString(markdown: introduction) {
                        Text(attributedIntroduction)
                            .font(.body)
                            .redacted(reason: viewModel.user?.introduction == nil ? .placeholder : [])
                    } else {
                        Text(introduction)
                            .font(.body)
                            .redacted(reason: viewModel.user?.introduction == nil ? .placeholder : [])
                    }
                    
                    // リロードボタン
                    Button {
                        Task {
                            await viewModel.loadUser()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isReloading)
                }
                .padding()
                
                Spacer()
                
                // ログアウトボタン
                Button("Logout") {
                    Task {
                        // 処理が二重に実行されるのを防ぐ。
                        if viewModel.isLoggingOut { return }
                        
                        // 処理中はログアウトボタン押下を受け付けない。
                        viewModel.isLoggingOut = false
                        
                        // Activity Indicator を表示。
                        viewModel.presentsActivityIndocator = true
                        
                        // API を叩いて処理を実行。
                        await viewModel.logOut()
                        
                        // Activity Indicator を非表示に。
                        viewModel.presentsActivityIndocator = false
                        
                        // LoginViewController に遷移。
                        await dismiss()
                        
                        // この View から遷移するのでボタンの押下受け付けは再開しない。
                        // 遷移アニメーション中に処理が実行されることを防ぐ。
                    }
                }
                .disabled(viewModel.isLoggingOut)
                .padding(.bottom, 30)
            }
        }
        .alert(
            "認証エラー",
            isPresented: $viewModel.presentsAuthenticationErrorAlert,
            actions: {
                Button("OK") {
                    Task {
                        // LoginViewController に遷移。
                        await dismiss()
                    }
                }
            },
            message: { Text("再度ログインして下さい。") }
        )
        .alert(
            "ネットワークエラー",
            isPresented: $viewModel.presentsNetworkErrorAlert,
            actions: { Text("閉じる") },
            message: { Text("通信に失敗しました。ネットワークの状態を確認して下さい。") }
        )
        .alert(
            "サーバーエラー",
            isPresented: $viewModel.presentsServerErrorAlert,
            actions: { Text("閉じる") },
            message: { Text("しばらくしてからもう一度お試し下さい。") }
        )
        .alert(
            "システムエラー",
            isPresented: $viewModel.presentsSystemErrorAlert,
            actions: { Text("閉じる") },
            message: { Text("エラーが発生しました。") }
        )
        .activityIndicatorCover(isPresented: viewModel.presentsActivityIndocator)
        .task {
            await viewModel.loadUser()
        }
    }
}
