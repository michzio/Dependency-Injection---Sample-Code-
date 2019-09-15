//
//  DIMainContainer.swift
//  Koober_iOS
//
//  Created by Michal Ziobro on 14/09/2019.
//  Copyright © 2019 Razeware LLC. All rights reserved.
//

import Foundation
import KooberKit
import Swinject
import SwinjectAutoregistration

public class DIMainContainer {
    
    public class func get(parent: Container) -> Container {
        
        let container = Container(parent: parent, defaultObjectScope: .container)
        
        container.register(Container.self, name: "onboarding") { r in
            return DIOnboardingContainer.get(parent: container)
        }
        container.register(Container.self, name: "signedin") { r in
            return DISignedInContainer.get(parent: container)
        }
        
        container.autoregister(OnboardingViewModel.self, initializer: OnboardingViewModel.init).inObjectScope(.weak)
        
        container.register(OnboardingViewController.self) { r in
            return OnboardingViewController(viewModel: r.resolve(OnboardingViewModel.self)!, onboardingContainer: r.resolve(Container.self, name: "onboarding")! )
        }.inObjectScope(.transient)
        
        container.autoregister(SignedInViewModel.self, initializer: SignedInViewModel.init).inObjectScope(.weak)
        container.register(SignedInViewController.self) { (r : Resolver, userSession : UserSession) in
            return SignedInViewController(viewModel: r.resolve(SignedInViewModel.self)!, userSession: userSession, signedinContainer: r.resolve(Container.self, name: "signedin")!)
        }.inObjectScope(.transient)
        
        return container
    }
}
