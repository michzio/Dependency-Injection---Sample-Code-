//
//  DIAppContainer.swift
//  Koober_iOS
//
//  Created by Michal Ziobro on 14/09/2019.
//  Copyright © 2019 Razeware LLC. All rights reserved.
//

import Foundation
import KooberKit
import Swinject
import SwinjectAutoregistration

public class DIAppContainer {
    
    public class func get() -> Container {
        
        let container = Container()
        
        container.register(Container.self, name: "main") { r in
            return DIMainContainer.get(parent: container)
        }
        
        container.autoregister(UserSessionCoding.self, initializer: UserSessionPropertyListCoder.init)
        container.autoregister(AuthRemoteAPI.self, initializer: FakeAuthRemoteAPI.init)
        
        #if USER_SESSION_DATASTORE_FILEBASED
        container.autoregister(UserSessionDataStore.self, initializer: FileUserSessionDataStore.init)
        #else
        container.autoregister(UserSessionDataStore.self, initializer: KeychainUserSessionDataStore.init)
        #endif
        container.autoregister(UserSessionRepository.self, initializer: KooberUserSessionRepository.init)
        container.autoregister(MainViewModel.self, initializer: MainViewModel.init).inObjectScope(.container)
        
        container.register(LaunchViewModel.self) { r in
            return LaunchViewModel(userSessionRepository: r.resolve(UserSessionRepository.self)!, notSignedInResponder: r.resolve(MainViewModel.self)!, signedInResponder: r.resolve(MainViewModel.self)!)
        }.inObjectScope(.transient)
        
        container.register(LaunchViewController.self) { r in
            let vc = LaunchViewController(viewModel: r.resolve(LaunchViewModel.self)!)
            return vc
        }
        
        container.register(MainViewController.self) { r in
            let vc = MainViewController( viewModel: r.resolve(MainViewModel.self)!,
                                        launchViewController: r.resolve(LaunchViewController.self)!,
                                        mainContainer: r.resolve(Container.self, name: "main")! )
            return vc
        }
        
        return container
    }
}
