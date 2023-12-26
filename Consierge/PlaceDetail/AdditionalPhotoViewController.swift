//
//  AdditionalPhotoViewController.swift
//  Consierge
//
//  Created by Austin McLaughlin on 2/6/24.
//

import UIKit

class AdditionalPhotoViewController: UIViewController {
    
    
    var picIndex: Int = 0
    var photos: [UIImage]?
    
    var imageScale = 1.0
    
    @IBOutlet var placePic: UIImageView!
    
    
    @IBOutlet var progressBar: UIProgressView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGRs()
        if let photos = photos {
            placePic.image = photos[picIndex]
            print(photos)
            print(picIndex)
        }
    }
    
    func setupGRs() {
        //if user is viewing the Place's images setup Swipe right and Swipe left to progress through the pictures
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(swipedLeft))
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(swipedRight))
        swipeLeft.direction = .left
        swipeRight.direction = .right
        self.view.addGestureRecognizer(swipeLeft)
        self.view.addGestureRecognizer(swipeRight)
        let zoom = UIPinchGestureRecognizer(target: self, action: #selector(self.pinched))
        placePic.addGestureRecognizer(zoom)
        updateProgressBar()
    }
    
    
    @objc func swipedLeft() {
        if let photos = photos, (picIndex+1) < photos.count {
            picIndex += 1
            UIView.transition(with: placePic, duration: 0.5, options: .transitionCrossDissolve, animations: { () -> Void in
                self.placePic.image = photos[self.picIndex]
            }, completion: nil)
        }
        updateProgressBar()
    }
    @objc func swipedRight() {
        if let photos = photos, picIndex != 0 {
            picIndex -= 1
            UIView.transition(with: placePic, duration: 0.5, options: .transitionCrossDissolve, animations: { () -> Void in
                self.placePic.image = photos[self.picIndex]
            }, completion: nil)
        }
        updateProgressBar()
    }
    
    @objc func pinched(sender: UIPinchGestureRecognizer) {
        guard let view = sender.view else { return }

        // When the pinch begins, store the current scale
        if sender.state == .began {
            let currentScale = self.placePic.frame.size.width / self.placePic.bounds.size.width
            var newScale = currentScale*sender.scale
            // Ensure the new scale is within a sensible range
            newScale = max(newScale, 1) // Prevents zooming out too far
            newScale = min(newScale, 4) // Optionally, prevents zooming in too much
            let transform = CGAffineTransform(scaleX: newScale, y: newScale)
            self.placePic.transform = transform
            sender.scale = 1
        } else if sender.state == .changed {
            // Adjust the scale based on the pinch
            let currentScale = self.placePic.frame.size.width / self.placePic.bounds.size.width
            var newScale = currentScale*sender.scale
            // Again, ensure the new scale is within a sensible range
            newScale = max(newScale, 1) // Prevents zooming out too far
            newScale = min(newScale, 4) // Optionally, prevents zooming in too much
            let transform = CGAffineTransform(scaleX: newScale, y: newScale)
            self.placePic.transform = transform
            sender.scale = 1
        } else if sender.state == .ended || sender.state == .cancelled {
            // Once the gesture ends or is cancelled, reset the image
            UIView.animate(withDuration: 0.3) { [weak self] in
                self?.placePic.transform = .identity
            }
        }
    }
    
    func updateProgressBar() {
        //Progress bar to display the Index Path / The # of Photos
        
        let photoCount = photos?.count ?? 0
        let progress = Float(picIndex+1)/Float(photoCount)
        progressBar.setProgress(progress, animated: true)
    }
}
