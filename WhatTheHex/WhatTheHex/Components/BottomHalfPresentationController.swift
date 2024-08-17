//
//  BottomHalfPresentationController.swift
//  WhatTheHex
//
//  Created by Ivan Evačić on 18.08.2024..
//

import UIKit

class BottomHalfPresentationController: UIPresentationController {

    override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView = containerView else { return .zero }

        let halfHeight = containerView.bounds.height / 2
        return CGRect(x: 0,
                      y: containerView.bounds.height - halfHeight,
                      width: containerView.bounds.width,
                      height: halfHeight)
    }

    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()

        // Add a dimming view to the background
        containerView?.insertSubview(dimmingView, at: 0)
        dimmingView.alpha = 0

        // Animate the dimming view alongside the presentation
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            self.dimmingView.alpha = 0.5
        }, completion: nil)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        dimmingView.addGestureRecognizer(tapGesture)
    }
    
    @objc func handleTapGesture(_ gesture: UITapGestureRecognizer) {
        // Dismiss the presented view controller when the dimming view is tapped
        presentedViewController.dismiss(animated: true, completion: nil)
    }

    override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()

        // Animate the dimming view out alongside the dismissal
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            self.dimmingView.alpha = 0
        }, completion: { _ in
            self.dimmingView.removeFromSuperview()
        })
    }

    // Dimming view to cover the background
    lazy var dimmingView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0, alpha: 0.5)
        view.frame = containerView?.bounds ?? .zero
        return view
    }()
}

