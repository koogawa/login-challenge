//
//  HomeViewModel.swift
//  LoginChallenge
//
//  Created by koogawa on 2022/01/23.
//

import SwiftUI
import Entities
import APIServices
import Logging

@MainActor
private let logger: Logger = .init(label: String(reflecting: HomeView.self))

@MainActor
final class HomeViewModel: ObservableObject {
    // Input

    // Binding
    @State var isReloading: Bool = false
    @State var isLoggingOut: Bool = false
    @State var presentsActivityIndocator: Bool = false
    @State var presentsAuthenticationErrorAlert: Bool = false
    @State var presentsNetworkErrorAlert: Bool = false
    @State var presentsServerErrorAlert: Bool = false
    @State var presentsSystemErrorAlert: Bool = false

    // Output
    @Published fileprivate(set) var user: User?

    func loadUser() async {
        // 処理が二重に実行されるのを防ぐ。
        if isReloading { return }

        // 処理中はリロードボタン押下を受け付けない。
        isReloading = true

        do {
            // API を叩いて User を取得。
            let user = try await UserService.currentUser()

            // 取得した情報を View に反映。
            DispatchQueue.main.async {
            self.user = user
            }
        } catch let error as AuthenticationError {
            logger.info("\(error)")

            // エラー情報を表示。
            presentsAuthenticationErrorAlert = true
        } catch let error as NetworkError {
            logger.info("\(error)")

            // エラー情報を表示。
            presentsNetworkErrorAlert = true
        } catch let error as ServerError {
            logger.info("\(error)")

            // エラー情報を表示。
            presentsServerErrorAlert = true
        } catch {
            logger.info("\(error)")

            // エラー情報を表示。
            presentsSystemErrorAlert = true
        }

        // 処理が完了したのでリロードボタン押下を再度受け付けるように。
        isReloading = false
    }

    func logOut() async {
        await AuthService.logOut()
    }
}

