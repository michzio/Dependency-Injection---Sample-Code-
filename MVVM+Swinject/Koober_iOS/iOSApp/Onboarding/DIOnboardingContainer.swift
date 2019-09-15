//
//  DIOnboardingContainer.swift
//  Koober_iOS
//
//  Created by Michal Ziobro on 14/09/2019.
//  Copyright © 2019 Razeware LLC. All rights reserved.
//

import Foundation
import KooberKit
import Swinject
import SwinjectAutoregistration

public class DIOnboardingContainer {
    
    public class func get(parent: Container) -> Container {
        
        let container = Container(parent: parent)
        
        container.autoregister(GoToSignUpNavigator.self, initializer: OnboardingViewModel.init)
        container.autoregister(GoToSignInNavigator.self, initializer: OnboardingViewModel.init)
        container.autoregister(WelcomeViewModel.self, initializer: WelcomeViewModel.init).inObjectScope(.transient)
        container.autoregister(WelcomeViewController.self, initializer: WelcomeViewController.init).inObjectScope(.weak)
        
        container.autoregister(SignedInResponder.self, initializer: MainViewModel.init)
        container.register(SignInViewModel.self) { r in
            return SignInViewModel(userSessionRepository: r.resolve(UserSessionRepository.self)!, signedInResponder: r.resolve(SignedInResponder.self)!)
        }.inObjectScope(.transient)
        container.autoregister(SignUpViewController.self, initializer: SignUpViewController.init)
        
        container.register(SignUpViewModel.self) { r in
            return SignUpViewModel(userSessionRepository: r.resolve(UserSessionRepository.self)!, signedInResponder: r.resolve(SignedInResponder.self)!)
        }.inObjectScope(.transient)
        container.autoregister(SignInViewController.self, initializer: SignInViewController.init)
        
        return container 
    }
}
