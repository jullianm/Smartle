//
//  Animator.swift
//  Smartle
//
//  Created by jullianm on 2018-10-21.
//  Copyright © 2018 jullianm. All rights reserved.
//

import UIKit

class Animator: NSObject, UIViewControllerAnimatedTransitioning, UIViewControllerInteractiveTransitioning {
    
    var anim : UIViewImplicitlyAnimating?
    var tbc: UITabBarController!
    var interacting = false
    var context : UIViewControllerContextTransitioning?
    
    func transitionDuration(using ctx: UIViewControllerContextTransitioning?)
        -> TimeInterval {
            return 0.4
    }
    func animateTransition(using ctx: UIViewControllerContextTransitioning) {
        let anim = interruptibleAnimator(using: ctx)
        anim.startAnimation()
    }
    
    func interruptibleAnimator(using ctx: UIViewControllerContextTransitioning)
        -> UIViewImplicitlyAnimating {
            if self.anim != nil {
                return self.anim!
            }
            let vc1 = ctx.viewController(forKey:.from)!
            let vc2 = ctx.viewController(forKey:.to)!
            let con = ctx.containerView
            let r1start = ctx.initialFrame(for: vc1)
            let r2end = ctx.finalFrame(for: vc2)
            let v1 = ctx.view(forKey:.from)!
            let v2 = ctx.view(forKey:.to)!
            let ix1 = tbc.viewControllers!.index(of:vc1)!
            let ix2 = tbc.viewControllers!.index(of:vc2)!
            let dir : CGFloat = ix1 < ix2 ? 1 : -1
            var r1end = r1start
            r1end.origin.x -= r1end.size.width * dir
            var r2start = r2end
            r2start.origin.x += r2start.size.width * dir
            v2.frame = r2start
            con.addSubview(v2)
            let anim = UIViewPropertyAnimator(duration: 0.4, curve: .linear) {
                v1.frame = r1end
                v2.frame = r2end
            }
            anim.addCompletion { _ in
                ctx.completeTransition(true)
            }

            self.anim = anim
            return anim
    }
    func animationEnded(_ transitionCompleted: Bool) {
        self.interacting = false
        self.context = nil
        self.anim = nil
    }
    func startInteractiveTransition(_ ctx:UIViewControllerContextTransitioning){
        self.anim = self.interruptibleAnimator(using: ctx)
        self.context = ctx
    }
}
