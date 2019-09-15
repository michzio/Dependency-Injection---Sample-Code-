//
//  DISignedInContainer.swift
//  Koober_iOS
//
//  Created by Michal Ziobro on 14/09/2019.
//  Copyright © 2019 Razeware LLC. All rights reserved.
//

import Foundation
import KooberKit
import KooberUIKit

import SwinjectAutoregistration
import Swinject

public class DISignedInContainer {
    
    public class func get(parent: Container) -> Container {
        
        let container = Container(parent: parent)
        
        container.register(Container.self, name: "pickmeup") { r in
            return DIPickMeUpContainer.get(parent: container)
        }
        
        //container.autoregister(SignedInViewModel.self, initializer: SignedInViewModel.init)
        container.autoregister(ImageCache.self, initializer: InBundleImageCache.init)
        container.autoregister(Locator.self, initializer: FakeLocator.init)
        
        // Getting Users Location
        container.register(DeterminedPickUpLocationResponder.self) { r in
            return r.resolve(SignedInViewModel.self)!
        }
        container.register(GettingUsersLocationViewModel.self) { r in
            return GettingUsersLocationViewModel(determinedPickUpLocationResponder: r.resolve(DeterminedPickUpLocationResponder.self)!, locator: r.resolve(Locator.self)!)
        }
        container.register(GettingUsersLocationViewController.self) { r in
            return GettingUsersLocationViewController(viewModel: r.resolve(GettingUsersLocationViewModel.self)!)
        }

        // Pick Me Up
        container.register(PickMeUpViewController.self) { (r: Resolver, location: Location) in
           
            return PickMeUpViewController(location: location, pickMeUpContainer: r.resolve(Container.self, name: "pickmeup")! )
        }
        
        // Waiting For Pickup
        container.register(WaitingForPickupViewModel.self) { r in
            return WaitingForPickupViewModel(goToNewRideNavigator: r.resolve(SignedInViewModel.self)!)
        }
        container.register(WaitingForPickupViewController.self) { r in
            
            return WaitingForPickupViewController(viewModel: r.resolve(WaitingForPickupViewModel.self)!)
        }
        
        // Profile
        container.register(NotSignedInResponder.self) { r in
            return r.resolve(MainViewModel.self)!
        }
        container.register(DoneWithProfileResponder.self) { r in
            return r.resolve(SignedInViewModel.self)!
        }
        
        container.register(ProfileViewModel.self) {  (r: Resolver, userSession: UserSession) in
            return ProfileViewModel(userSession: userSession, notSignedInResponder: r.resolve(NotSignedInResponder.self)!, doneWithProfileResponder: r.resolve(DoneWithProfileResponder.self)!, userSessionRepository: r.resolve(UserSessionRepository.self)!)
        }
        container.register(ProfileContentViewController.self) { (r: Resolver, userSession: UserSession) in
            return ProfileContentViewController(viewModel: r.resolve(ProfileViewModel.self, argument: userSession)!)
        }
        container.register(ProfileViewController.self) { (r: Resolver, userSession: UserSession) in
            return ProfileViewController(contentViewController: r.resolve(ProfileContentViewController.self, argument: userSession)!)
        }
        
        return container
    }
}
