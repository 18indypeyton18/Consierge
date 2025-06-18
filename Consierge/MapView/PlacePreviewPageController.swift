//
//  PlacePreviewPageController.swift
//  Consierge
//
//  Created by Austin McLaughlin on 2/18/25.
//

import UIKit

// This controller wraps a UIPageViewController and holds an array of places.

class PlacePreviewPageController: UIViewController {
    var places: [Place] = []
    // Reference to MapViewController (to use its storyboard, picGetter, etc.)
    weak var mapViewController: MapViewController?

    var pageVC: UIPageViewController!
    private var previewControllers: [PlacePreviewController] = []
    private var pageControl: UIPageControl!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupPageViewController()
        setupPageControl()
        setupConstraints()
        pageVC.dataSource = self
        pageVC.delegate = self
    }

    func setupPageViewController() {
        pageVC = UIPageViewController(transitionStyle: .scroll,
                                      navigationOrientation: .horizontal,
                                      options: nil)
        pageVC.view.frame = view.bounds
        addChild(pageVC)
        view.addSubview(pageVC.view)
        pageVC.didMove(toParent: self)
        
        // Create a preview controller for each place.
        previewControllers = places.map { place in
            let preview = PlacePreviewController()
            preview.place = place
            preview.containerPageController = self
            return preview
        }
        if let first = previewControllers.first {
            pageVC.setViewControllers([first], direction: .forward, animated: false, completion: nil)
        }
    }
    
    func setupPageControl() {
        pageControl = UIPageControl()
        pageControl.numberOfPages = previewControllers.count
        pageControl.currentPage = 0
        pageControl.pageIndicatorTintColor = UIColor.lightGray
        pageControl.currentPageIndicatorTintColor = UIColor.darkGray
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        
        // Add the page control to the container view.
        view.addSubview(pageControl)
        
        // Constrain the page control to the bottom of the view with some margin.
        NSLayoutConstraint.activate([
            pageControl.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10),
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    func setupConstraints() {
        NSLayoutConstraint.activate([
            // The pageVC.view fills the container view, but stops above the pageControl.
            pageVC.view.topAnchor.constraint(equalTo: view.topAnchor),
            pageVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pageVC.view.bottomAnchor.constraint(equalTo: pageControl.topAnchor, constant: 10),
            
            // The pageControl is pinned to the bottom with left/right margins and a fixed height.
            pageControl.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageControl.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pageControl.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -5),
            pageControl.heightAnchor.constraint(equalToConstant: 15)
        ])
    }
}

extension PlacePreviewPageController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let currentVC = viewController as? PlacePreviewController,
              let index = previewControllers.firstIndex(of: currentVC),
              index > 0 else { return nil }
        return previewControllers[index - 1]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let currentVC = viewController as? PlacePreviewController,
              let index = previewControllers.firstIndex(of: currentVC),
              index < previewControllers.count - 1 else { return nil }
        return previewControllers[index + 1]
    }
}

extension PlacePreviewPageController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController,
                            didFinishAnimating finished: Bool,
                            previousViewControllers: [UIViewController],
                            transitionCompleted completed: Bool) {
        if completed,
           let currentVC = pageViewController.viewControllers?.first as? PlacePreviewController,
           let index = previewControllers.firstIndex(of: currentVC) {
            pageControl.currentPage = index
        }
    }
}
