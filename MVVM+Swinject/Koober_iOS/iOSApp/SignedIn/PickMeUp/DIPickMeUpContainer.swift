//
//  DIPickMeUpContainer.swift
//  Koober_iOS
//
//  Created by Michal Ziobro on 15/09/2019.
//  Copyright © 2019 Razeware LLC. All rights reserved.
//

import Foundation
import KooberUIKit
import KooberKit
import Swinject
import SwinjectAutoregistration

public class DIPickMeUpContainer {
    
    public class func get(parent: Container) -> Container {
    
        let container = Container(parent: parent)
        
        container.register(PickMeUpMapViewModel.self) { (r: Resolver, location: Location) in
            return PickMeUpMapViewModel(pickupLocation: location)
        }
        
        container.autoregister(NewRideRemoteAPI.self, initializer: FakeNewRideRemoteAPI.init)
        container.autoregister(NewRideRepository.self, initializer: KooberNewRideRepository.init)
        container.autoregister(RideOptionDataStore.self, initializer: RideOptionDataStoreInMemory.init)
        
        container.register(NewRideRequestAcceptedResponder.self) { r in
            return r.resolve(SignedInViewModel.self)!
        }
        
        // Ride Me Up
        container.register(PickMeUpViewModel.self) { (r: Resolver, location: Location) in
            return PickMeUpViewModel(pickupLocation: location, newRideRepository: r.resolve(NewRideRepository.self)!, newRideRequestAcceptedResponder: r.resolve(NewRideRequestAcceptedResponder.self)!, mapViewModel: r.resolve(PickMeUpMapViewModel.self, argument: location)!)
        }.inObjectScope(.container)
        
        container.register(PickMeUpMapViewModel.self) { (r: Resolver, location: Location) in
            return PickMeUpMapViewModel(pickupLocation: location)
        }
        
        container.register(PickMeUpMapViewController.self) { (r: Resolver, location: Location) in
            return PickMeUpMapViewController(viewModel: r.resolve(PickMeUpMapViewModel.self, argument: location)!, imageCache: r.resolve(ImageCache.self)!)
        }
        
        // Ride Option Picker
        container.autoregister(RideOptionRepository.self, initializer: KooberRideOptionRepository.init)
        container.register(RideOptionDeterminedResponder.self) { (r: Resolver, location: Location) in
            return r.resolve(PickMeUpViewModel.self, argument: location)!
        }
        container.register(RideOptionPickerViewModel.self) { (r: Resolver, location: Location) in
            return RideOptionPickerViewModel(repository: r.resolve(RideOptionRepository.self)!, rideOptionDeterminedResponder: r.resolve(RideOptionDeterminedResponder.self, argument: location)!)
        }
        container.register(RideOptionPickerViewController.self) { (r, location: Location) in
            
            return RideOptionPickerViewController(pickupLocation: location, imageCache: r.resolve(ImageCache.self)!, viewModel: r.resolve(RideOptionPickerViewModel.self, argument: location)!)
        }
        
        // Sending Ride Request
        container.register(SendingRideRequestViewController.self) { r in
            return SendingRideRequestViewController()
        }
        
        // Dropoff Location Picker
        container.register(LocationRepository.self) { r in
            return KooberLocationRepository(remoteAPI: r.resolve(NewRideRemoteAPI.self)!)
        }
        container.register(DropoffLocationDeterminedResponder.self) { (r: Resolver, location: Location) in
            return r.resolve(PickMeUpViewModel.self, argument: location)!
        }
        container.register(CancelDropoffLocationSelectionResponder.self) { (r: Resolver, location: Location) in
            return r.resolve(PickMeUpViewModel.self, argument: location)!
        }
        container.register(DropoffLocationPickerViewModel.self) { (r: Resolver, location: Location) in
            return DropoffLocationPickerViewModel(pickupLocation: location, locationRepository: r.resolve(LocationRepository.self)!, dropoffLocationDeterminedResponder: r.resolve(DropoffLocationDeterminedResponder.self, argument: location)!, cancelDropoffLocationSelectionResponder: r.resolve(CancelDropoffLocationSelectionResponder.self, argument: location)!)
        }
        container.register(DropoffLocationPickerContentViewController.self) { (r: Resolver, location: Location) in
            return DropoffLocationPickerContentViewController(pickupLocation: location, viewModel: r.resolve(DropoffLocationPickerViewModel.self, argument: location)!)
        }
        container.register(DropoffLocationPickerViewController.self) { (r: Resolver, location: Location) in
            return DropoffLocationPickerViewController(contentViewController: r.resolve(DropoffLocationPickerContentViewController.self, argument: location)!)
        }
        
        return container
    }
    
}
