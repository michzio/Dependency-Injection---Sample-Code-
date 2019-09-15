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
        
        container.register(GoToSignUpNavigator.self) { r in
            return r.resolve(OnboardingViewModel.self)!
        }
        container.register(GoToSignInNavigator.self) { r in
            return r.resolve(OnboardingViewModel.self)!
        }
        
        container.autoregister(WelcomeViewModel.self, initializer: WelcomeViewModel.init).inObjectScope(.transient)
        container.autoregister(WelcomeViewController.self, initializer: WelcomeViewController.init).inObjectScope(.weak)
        
        container.register(SignedInResponder.self) { r in
            return r.resolve(MainViewModel.self)!
        }
        
        container.register(SignInViewModel.self) { r in
            return SignInViewModel(userSessionRepository: r.resolve(UserSessionRepository.self)!, signedInResponder: r.resolve(SignedInResponder.self)!)
        }.inObjectScope(.transient)
        container.autoregister(SignInViewController.self, initializer: SignInViewController.init).inObjectScope(.transient)
        
        container.register(SignUpViewModel.self) { r in
            return SignUpViewModel(userSessionRepository: r.resolve(UserSessionRepository.self)!, signedInResponder: r.resolve(SignedInResponder.self)!)
        }.inObjectScope(.transient)
        container.autoregister(SignUpViewController.self, initializer: SignUpViewController.init)
        
        return container 
    }
}
