import UIKit

// MainViewController - is object under construction OUC for AppDelegate.rootViewController
// it is top level object graph

// DEPENDENCY INJECTION

/***************************************************************
 * A. ON-DEMAND approach
 * good for teaching DI, and in small apps, not in real-world apps
 * to create OUC, first it is needed to create all its dependencies
 ***************************************************************/

// 1.0
protocol SignedInResponder {
    
}

protocol NotSignedInResponder {
    
}

protocol UserSessionCoding { }
class UserSessionPropertyListCoder : UserSessionCoding { }

protocol UserSessionDataStore { }
class KeychainUserSessionDataStore : UserSessionDataStore {
    public init(userSessionCoder: UserSessionCoding) { }
}
class FileUserSessionDataStore : UserSessionDataStore { }

protocol AuthRemoteAPI { }
class FakeAuthRemoteAPI : AuthRemoteAPI { }

protocol UserSessionRepository { }
class KooberUserSessionRepository : UserSessionRepository {
    public init(dataStore: UserSessionDataStore,
                remoteAPI: AuthRemoteAPI) { }
}

class MainViewModel : NotSignedInResponder, SignedInResponder {
    
}

class LaunchViewModel {
    public init(userSessionRepository: UserSessionRepository,
                notSignedInResponder: NotSignedInResponder,
                signedInResponder: SignedInResponder) { }
}

class LaunchViewController {
    public init(viewModel: LaunchViewModel) { }
}

class MainViewController {
    public init(viewModel: MainViewModel, launchViewController: LaunchViewController) { }
}

// 2 x dependencies : MainView Model, LaunchViewController

// 1.1
let mainViewModel = MainViewModel()

// 1.2
// LaunchViewController has transitive dependencies
// decomposing large objects into SINGLE RESPONSIBILITY objects
// results in DEEP OBJECT GRAPHS

// KooberUserSessionRepository is stateful - app scope
// use global constant for that

// 1.2.1
let globalUserSessionRepository : UserSessionRepository = {
    
    // compile time substitution of types
    // conditional compilation techniques
    // set in scheme build settings -> ACTIVE COMPILATION CONDITIONS
    #if FILEBASED_USER_SESSION_DATASTORE
        let userSessionDataStore = FileUserSessionDataStore()
    #else
        let userSessionCoding = UserSessionPropertyListCoder()
    
        let userSessionDataStore = KeychainUserSessionDataStore(userSessionCoder: userSessionCoding)
    #endif

    let authRemoteAPI = FakeAuthRemoteAPI()
    
    return KooberUserSessionRepository(dataStore: userSessionDataStore, remoteAPI: authRemoteAPI)
}()

// 1.3
// inside application didFinishLaunching goes construction of OUC
func applicationLaunching_ON_DEMAND() {
    let launchViewModel = LaunchViewModel(userSessionRepository: globalUserSessionRepository, notSignedInResponder: mainViewModel, signedInResponder: mainViewModel)

    let launchViewController = LaunchViewController(viewModel: launchViewModel)
    let mainViewController = MainViewController(viewModel: mainViewModel, launchViewController: launchViewController)

    // window.frame = UIScreen.main.bounds
    // window.makeKeyAndVisible()
    // window.rootViewController = mainViewController
}


// 2.0 parent view controller creating its child view controller using on-demand approach

// need to create all OnboardingViewController's dependencies
protocol GoToSignUpNavigator { }
protocol GoToSignInNavigator { }

class OnboardingViewModel : GoToSignInNavigator, GoToSignUpNavigator {}
class WelcomeViewModel {
    public init(goToSignUpNavigator: GoToSignUpNavigator,
                goToSignInNavigator: GoToSignInNavigator) { }
}
class SignInViewModel {
    public init(userSessionRepository: UserSessionRepository,
                signedInResponder: SignedInResponder) { }
}
class SignUpViewModel {
    public init(userSessionRepository: UserSessionRepository,
                signedInResponder: SignedInResponder) { }
}

class WelcomeViewController {
    public init(viewModel: WelcomeViewModel) { }
}

class SignInViewController {
    public init(viewModel: SignInViewModel) { }
}

class SignUpViewController {
    public init(viewModel: SignUpViewModel) { }
}

class OnboardingViewController {
    public init(viewModel: OnboardingViewModel,
                welcomeViewController: WelcomeViewController,
                signInViewController: SignInViewController,
                signUpViewController: SignUpViewController) { }
}

// using ON-DEMAND approach you find long methods like this all over the place
// the only pros is this is unit testable, thanks to loosely-coupling of objects
func presentOnboarding() {
    
    let onboardingViewModel = OnboardingViewModel()
    
    let welcomeViewModel = WelcomeViewModel(
        goToSignUpNavigator: onboardingViewModel,
        goToSignInNavigator: onboardingViewModel
    )
    let welcomeViewController = WelcomeViewController(viewModel: welcomeViewModel)
    
    let signInViewModel = SignInViewModel(
        userSessionRepository: globalUserSessionRepository,
        signedInResponder: mainViewModel
    )
    let signInViewController = SignInViewController(viewModel: signInViewModel)
    
    let signUpViewModel = SignUpViewModel(
        userSessionRepository: globalUserSessionRepository,
        signedInResponder: mainViewModel
    )
    let signUpViewController = SignUpViewController(viewModel: signUpViewModel)
    
    let onboardingViewController = OnboardingViewController(
        viewModel: onboardingViewModel,
        welcomeViewController: welcomeViewController,
        signInViewController: signInViewController,
        signUpViewController: signUpViewController
    )
    
    //present(onboardingViewController, animated: true) { ... }
    //self.onboardingViewController = onboardingViewController
}

/***************************************************************
 * B. FACTORIES approach
 * uses factories class - no state, only factories methods (could be static)
 * ex. ObjectFactories
 * factory delegate or factory closures injecting
 * to give other objects power to create objects
 ***************************************************************/

// centralized factories class
class ObjectFactories {
    
    // factories needed to create a UserSessionRepository
    
    func makeUserSessionRepository() -> UserSessionRepository {
        let dataStore = makeUserSessionDataStore()
        let remoteAPI = makeAuthRemoteAPI()
        return KooberUserSessionRepository(dataStore: dataStore, remoteAPI: remoteAPI)
    }
    
    func makeUserSessionDataStore() -> UserSessionDataStore {
        
        #if FILEBASED_USER_SESSION_DATASTORE
            return FileUserSessionDataStore()
        #else
            let coder = makeUserSessionCoder()
            return KeychainUserSessionDataStore(userSessionCoder: coder)
        #endif
    }
    
    func makeUserSessionCoder() -> UserSessionCoding {
        return UserSessionPropertyListCoder()
    }
    
    func makeAuthRemoteAPI() -> AuthRemoteAPI {
        return FakeAuthRemoteAPI()
    }
}

class SignedInViewController {
    public init() { }
}

// here is real needed initializer with factory closures
// used to create child view controller in main view controller
extension MainViewController {
    
    public convenience init(viewModel: MainViewModel,
                launchViewController: LaunchViewController,
                // factory closure that creates OnboardingViewController
                onboardingViewControllerFactory: @escaping () -> OnboardingViewController,
                // factory closure that creates SignedInViewController
                signedInViewControllerFactory: @escaping () -> SignedInViewController) {
        self.init(viewModel: viewModel, launchViewController: launchViewController)
    }
}

extension ObjectFactories {
    
    // factories to create MainViewController
    
    func makeMainViewModel() -> MainViewModel {
        return MainViewModel()
    }
}

// Main View Model is stateful (long-lived), use global constant
let globalMainViewModel : MainViewModel  = {
   
    let objectFactories = ObjectFactories()
    
    let mainViewModel = objectFactories.makeMainViewModel()
    
    return mainViewModel
}()

// global shared instance (long-lived)
let _globalUserSessionRepository : UserSessionRepository = {
    
    let objectFactories = ObjectFactories()
    
    let userSessionRepository = objectFactories.makeUserSessionRepository()
    
    return userSessionRepository
}()

extension ObjectFactories {
    
    func makeOboardingViewController(userSessionRepository: UserSessionRepository, signedInResponder: SignedInResponder) -> OnboardingViewController {
        fatalError()
    }
    
    // TODO
}

extension ObjectFactories {
    
    // in factories approach you need to pass long-lived dependencies via params
    // as factories class is statless and it does not know where this obejcts live
    func makeMainViewController(
        viewModel: MainViewModel,
        userSessionRepository: UserSessionRepository) -> MainViewController {
        
        let launchViewController = makeLaunchViewController(
            userSessionRepository: userSessionRepository,
            notSignedInResponder: viewModel,
            signedInResponder: viewModel
        )
        
        let onboardingViewControllerFactory : () -> OnboardingViewController = {
            // return new Onboarding View Controller here
            // factories class is stateless, therefor
            // there's no chance for a retain cycle here.
            return self.makeOboardingViewController(userSessionRepository: userSessionRepository, signedInResponder: viewModel)
        }
        
        let signedInViewControllerFactory : () -> SignedInViewController = {
            // TODO
            fatalError()
        }
        
        return MainViewController(
            viewModel: viewModel,
            launchViewController: launchViewController,
            onboardingViewControllerFactory: onboardingViewControllerFactory,
            signedInViewControllerFactory: signedInViewControllerFactory)
    }
    
    func makeLaunchViewController(
        userSessionRepository: UserSessionRepository,
        notSignedInResponder: NotSignedInResponder,
        signedInResponder: SignedInResponder) -> LaunchViewController {
        
        let viewModel = makeLaunchViewModel(
            userSessionRepository: userSessionRepository,
            notSignedInResponder: notSignedInResponder,
            signedInResponder: signedInResponder
        )
        
        return LaunchViewController(viewModel: viewModel)
    }
    
    func makeLaunchViewModel(
        userSessionRepository: UserSessionRepository,
        notSignedInResponder: NotSignedInResponder,
        signedInResponder: SignedInResponder) -> LaunchViewModel {
        
        return LaunchViewModel(userSessionRepository: userSessionRepository, notSignedInResponder: notSignedInResponder, signedInResponder: signedInResponder)
    }
}

// inside application didFinishLaunching goes construction of OUC
func applicationLaunching_FACTORIES_CLASS() {
    
    let mainViewModel = globalMainViewModel
    let userSessionRepository = _globalUserSessionRepository
    let objectFactories = ObjectFactories()
    
    let mainViewController = objectFactories.makeMainViewController(viewModel: mainViewModel, userSessionRepository: userSessionRepository)
    
    // window.frame = UIScreen.main.bounds
    // window.makeKeyAndVisible()
    // window.rootViewController = mainViewController
}

// method in Main View Controller
func presentOnboarding_FACTORIES_CLASS() {
    //let onboardingViewController = makeOnboardingViewController()
    
    //present(onboardingViewController, animated: true) { ... }
    //self.onboardingViewController = onboardingViewController
}

/***************************************************************
 * C. SINGLE DEPENDENCY CONTAINER approach
 * factories class need to go from being stateless to stateful
 * with long-lived dependencies as properties initialized in init()
 ***************************************************************/

// 1.0 - shared, long-lived user session repository
class DependencyContainer {
    
    // long-lived dependencies
    let userSessionRepository : UserSessionRepository
    let mainViewModel : MainViewModel
    
    var onboardingViewModel : OnboardingViewModel?
    
    // init long-lived dependencies here
    init() {
        
        // Swift does not allow initializer to call a method
        // on self until all stored properties are initialized
        // so we define factory methods inside init()
        func makeUserSessionRepository() -> UserSessionRepository {
            let dataStore = makeUserSessionDataStore()
            let remoteAPI = makeAuthRemoteAPI()
            return KooberUserSessionRepository(dataStore: dataStore, remoteAPI: remoteAPI)
        }
        
        func makeUserSessionDataStore() -> UserSessionDataStore {
            
            #if FILEBASED_USER_SESSION_DATASTORE
                return FileUserSessionDataStore()
            #else
                let coder = makeUserSessionCoder()
                return KeychainUserSessionDataStore(userSessionCoder: coder)
            #endif
        }
        
        func makeUserSessionCoder() -> UserSessionCoding {
            return UserSessionPropertyListCoder()
        }
        
        func makeAuthRemoteAPI() -> AuthRemoteAPI {
            return FakeAuthRemoteAPI()
        }
        
        func makeMainViewModel() -> MainViewModel {
            return MainViewModel()
        }
        
        self.userSessionRepository = makeUserSessionRepository()
        self.mainViewModel = makeMainViewModel()
    }
    
    // Onboarding View Controller factory methods
    // factory methods no longer have params
    // as container has all information needed to create dependencies
    // it creates ephemeral dependencies using other factory methods
    // and access long-lived dependencies as its stored properties
    
    func makeOnboardingViewController() -> OnboardingViewController {
        
        // creates new view model instance each time new view controller is created
        // scope of live is shorter than app scope
        // can be refactored do SCOPED DEPENDENCY CONTAINERS
        // by introducing containers hierarchy
        self.onboardingViewModel = makeOnboardingViewModel()
        
        let welcomeViewController = makeWelcomeViewController()
        let signInViewController = makeSignInViewController()
        let signUpViewController = makeSignUpViewController()
        
        return OnboardingViewController(
            viewModel: onboardingViewModel!,
            welcomeViewController: welcomeViewController,
            signInViewController: signInViewController,
            signUpViewController: signUpViewController)
    }
    
    func makeOnboardingViewModel() -> OnboardingViewModel {
        return OnboardingViewModel()
    }
    
    func makeWelcomeViewController() -> WelcomeViewController {
        let viewModel = makeWelcomeViewModel()
        return WelcomeViewController(viewModel: viewModel)
    }
    
    func makeWelcomeViewModel() -> WelcomeViewModel {
        return WelcomeViewModel(goToSignUpNavigator: self.onboardingViewModel!, goToSignInNavigator: self.onboardingViewModel!)
    }
    
    func makeSignInViewController() -> SignInViewController {
        let viewModel = makeSignInViewModel()
        return SignInViewController(viewModel: viewModel)
    }
    
    func makeSignInViewModel() -> SignInViewModel {
        return SignInViewModel(userSessionRepository: self.userSessionRepository, signedInResponder: self.mainViewModel)
    }
    
    func makeSignUpViewController() -> SignUpViewController {
        let viewModel = makeSignUpViewModel()
        return SignUpViewController(viewModel: viewModel)
    }
    
    func makeSignUpViewModel() -> SignUpViewModel {
        return SignUpViewModel(userSessionRepository: self.userSessionRepository, signedInResponder: self.mainViewModel)
    }
    
    // Launch View Controller factory methods
    func makeLaunchViewController() -> LaunchViewController {
        let viewModel = makeLaunchViewModel()
        return LaunchViewController(viewModel: viewModel)
    }
    
    func makeLaunchViewModel() -> LaunchViewModel {
        return LaunchViewModel(userSessionRepository: self.userSessionRepository, notSignedInResponder: self.mainViewModel, signedInResponder: self.mainViewModel)
    }
    
    // Main View Controller factory methods
    func makeMainViewController() -> MainViewController {
        let launchViewController = makeLaunchViewController()
        
        let onboardingViewControllerFactory = {
            return self.makeOnboardingViewController()
        }
        
        let signedInViewControllerFactory : () -> SignedInViewController = {
            // TODO
            //return self.makeSignedInViewController()
            fatalError()
        }
        
        return MainViewController(viewModel: self.mainViewModel, launchViewController: launchViewController, onboardingViewControllerFactory: onboardingViewControllerFactory, signedInViewControllerFactory: signedInViewControllerFactory)
    }
}

// inside application didFinishLaunching goes construction of OUC

// you should create only one instance of container
// containers are stateful unlike factories classes
let container = DependencyContainer()

func applicationLaunching_DEPENDENCY_CONTAINER() {
    
    let mainViewController = container.makeMainViewController()
    // window.frame = UIScreen.main.bounds
    // window.makeKeyAndVisible()
    // window.rootViewController = mainViewController
}


/***************************************************************
 * D. CONTAINER HIERARCHY approach
 * single app scoped container can be split into multiple containers
 * we can get rid of peasky optional shared properties (singletons)
 * in previous single container (ex. onboardingViewModel property)
 * in container hierarchy child container can access having longer lifespan
 * parent containers, but parent container cannot access child containers dependencies
 ***************************************************************/

// 1. APP SCOPED container class
// - remove onboarding factories from single container approach
class AppDependencyContainer {
    
    // long-lived dependencies
    let userSessionRepository : UserSessionRepository
    let mainViewModel : MainViewModel
    
    var onboardingViewModel : OnboardingViewModel?
    
    // init long-lived dependencies here
    init() {
        
        // Swift does not allow initializer to call a method
        // on self until all stored properties are initialized
        // so we define factory methods inside init()
        func makeUserSessionRepository() -> UserSessionRepository {
            let dataStore = makeUserSessionDataStore()
            let remoteAPI = makeAuthRemoteAPI()
            return KooberUserSessionRepository(dataStore: dataStore, remoteAPI: remoteAPI)
        }
        
        func makeUserSessionDataStore() -> UserSessionDataStore {
            
            #if FILEBASED_USER_SESSION_DATASTORE
            return FileUserSessionDataStore()
            #else
            let coder = makeUserSessionCoder()
            return KeychainUserSessionDataStore(userSessionCoder: coder)
            #endif
        }
        
        func makeUserSessionCoder() -> UserSessionCoding {
            return UserSessionPropertyListCoder()
        }
        
        func makeAuthRemoteAPI() -> AuthRemoteAPI {
            return FakeAuthRemoteAPI()
        }
        
        func makeMainViewModel() -> MainViewModel {
            return MainViewModel()
        }
        
        self.userSessionRepository = makeUserSessionRepository()
        self.mainViewModel = makeMainViewModel()
    }
    
    // Main View Controller factory methods
    func makeMainViewController() -> MainViewController {
        let launchViewController = makeLaunchViewController()
        
        let onboardingViewControllerFactory = {
            return self.makeOnboardingViewController()
        }
        
        let signedInViewControllerFactory : () -> SignedInViewController = {
            // TODO
            //return self.makeSignedInViewController()
            fatalError()
        }
        
        return MainViewController(viewModel: self.mainViewModel, launchViewController: launchViewController, onboardingViewControllerFactory: onboardingViewControllerFactory, signedInViewControllerFactory: signedInViewControllerFactory)
    }
    
    // Launch View Controller factory methods
    func makeLaunchViewController() -> LaunchViewController {
        let viewModel = makeLaunchViewModel()
        return LaunchViewController(viewModel: viewModel)
    }
    
    func makeLaunchViewModel() -> LaunchViewModel {
        return LaunchViewModel(userSessionRepository: self.userSessionRepository, notSignedInResponder: self.mainViewModel, signedInResponder: self.mainViewModel)
    }
    
    func makeOnboardingViewController() -> OnboardingViewController {
        
        let onboardingScopedContainer = OnboardingDependencyContainer(parent: self)
        
        return onboardingScopedContainer.makeOnboardingViewController()
    }
}


// ONBOARDING SCOPED dependency container
class OnboardingDependencyContainer {
    
    // injected from parent
    let userSessionRepository : UserSessionRepository
    let mainViewModel : MainViewModel
    
    // long-lived dependencies (onboarding scope)
    let onboardingViewModel: OnboardingViewModel
    
    init(parent: AppDependencyContainer) {
        
        func makeOnboardingViewModel() -> OnboardingViewModel {
            return OnboardingViewModel()
        }
        
        self.userSessionRepository = parent.userSessionRepository
        self.mainViewModel = parent.mainViewModel
        
        self.onboardingViewModel = makeOnboardingViewModel()
    }
    
    // OnboardingViewController factory methods
    func makeOnboardingViewController() -> OnboardingViewController {
        
        let welcomeViewController = makeWelcomeViewController()
        let signInViewController = makeSignInViewController()
        let signUpViewController = makeSignUpViewController()
        
        return OnboardingViewController(
            viewModel: onboardingViewModel,
            welcomeViewController: welcomeViewController,
            signInViewController: signInViewController,
            signUpViewController: signUpViewController)
    }
    
    func makeWelcomeViewController() -> WelcomeViewController {
        let viewModel = makeWelcomeViewModel()
        return WelcomeViewController(viewModel: viewModel)
    }
    
    func makeWelcomeViewModel() -> WelcomeViewModel {
        return WelcomeViewModel(goToSignUpNavigator: self.onboardingViewModel, goToSignInNavigator: self.onboardingViewModel)
    }
    
    func makeSignInViewController() -> SignInViewController {
        let viewModel = makeSignInViewModel()
        return SignInViewController(viewModel: viewModel)
    }
    
    func makeSignInViewModel() -> SignInViewModel {
        return SignInViewModel(userSessionRepository: self.userSessionRepository, signedInResponder: self.mainViewModel)
    }
    
    func makeSignUpViewController() -> SignUpViewController {
        let viewModel = makeSignUpViewModel()
        return SignUpViewController(viewModel: viewModel)
    }
    
    func makeSignUpViewModel() -> SignUpViewModel {
        return SignUpViewModel(userSessionRepository: self.userSessionRepository, signedInResponder: self.mainViewModel)
    }
}

// inside application didFinishLaunching goes construction of OUC
let appContainer = AppDependencyContainer()

// refactoring single container into container hierarchy doesn't change consumer code
func applicationLaunching_CONTAINER_HIERARCHY() {
    
    let mainViewController = appContainer.makeMainViewController()
    // window.frame = UIScreen.main.bounds
    // window.makeKeyAndVisible()
    // window.rootViewController = mainViewController
}

// DEPENDENCY INJECTION
// OUC = object-under-construction
// - testability & maintainability
// - Consumer needs OUC and OUC need transitive dependencies -> together object graph
// - accessing dependencies, determining & desigining substitutability
// - dependency patterns: Dependency Injection, Service Locator, Environment, Protocol extension
// - DI types: init(), property, method
// - DI approaches: on-demand, factories, single container, container hierarchy
// - if OUC need to multiple instances of dependency inject: factory closures or object conforming to factory delegate protocol
// - Dependency Injection libraries: Android -> Dagger 2, Swift -> Swinject 2
//   https://github.com/Swinject/Swinject/blob/master/Documentation/README.md


