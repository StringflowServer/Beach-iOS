
import UIKit
//Tab bar view controller to custmize Tab
class ChatterTabBarController: UITabBarController {
    //Delegate Methods
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    override func  tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        if item.tag == 0 {
            
            let tabbar:UITabBarController = self as UITabBarController
            tabbar.selectedIndex = 0
            let navC = tabbar.viewControllers![0] as! UINavigationController
            navC.popToRootViewController(animated: false)
        }
        if item.tag == 1 {
            
            let tabbar:UITabBarController = self as UITabBarController
            tabbar.selectedIndex = 1
            let navC = tabbar.viewControllers![1] as! UINavigationController
            navC.popToRootViewController(animated: false)
        }
        
        print("selected item is \(item)")
    }
    
}
