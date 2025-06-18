
import UIKit

protocol AskAIInputCollectionViewCellDelegate: AnyObject {
    func didSubmitPrompt(_ prompt: String)
    func didChangeText(isTyping: Bool)
}

class AskAIInputCollectionViewCell: UICollectionViewCell, UITextViewDelegate {
    
    static let reuseIdentifier = "AskAIInput"
    
    weak var delegate: AskAIInputCollectionViewCellDelegate?
    
    // Modified UITextView with updated appearance
    let textView: UITextView = {
        let tv = UITextView()
        tv.isScrollEnabled = false
        tv.font = UIFont.systemFont(ofSize: 16)
        
        tv.backgroundColor = UIColor.systemGray6
        
        tv.layer.cornerRadius = 10.0
        tv.layer.borderWidth = 0
        
        // Adjust text container inset to accommodate icon and placeholder
        tv.textContainerInset = UIEdgeInsets(top: 8, left: 36, bottom: 8, right: 8)
        tv.textContainer.lineFragmentPadding = 0 // Remove default padding
        tv.autocorrectionType = .no // Optional: Disable autocorrection
        return tv
    }()
    
    var placeholderLabel: UILabel = {
        let label = UILabel()
        label.text = "Ask AI"
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.lightGray
        return label
    }()
    
    private let searchIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "poweroutlet.type.b")
        imageView.tintColor = .gray
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubview(textView)
        textView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add placeholder label to textView
        textView.addSubview(placeholderLabel)
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Add search icon to textView
        textView.addSubview(searchIconImageView)
        searchIconImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Set constraints for textView
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            textView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            textView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            textView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
        
        // Set constraints for placeholderLabel
        NSLayoutConstraint.activate([
            placeholderLabel.centerYAnchor.constraint(equalTo: textView.centerYAnchor),
            placeholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: 36)
        ])
        
        // Set constraints for searchIconImageView
        NSLayoutConstraint.activate([
            searchIconImageView.centerYAnchor.constraint(equalTo: textView.centerYAnchor),
            searchIconImageView.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: 8),
            searchIconImageView.widthAnchor.constraint(equalToConstant: 20),
            searchIconImageView.heightAnchor.constraint(equalToConstant: 20)
        ])
        
        // Delegate and additional configurations
        textView.delegate = self
        textView.returnKeyType = .done
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Handle return key to submit prompt
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            let prompt = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !prompt.isEmpty {
                delegate?.didSubmitPrompt(prompt)
                textView.text = ""
                placeholderLabel.isHidden = false // Show placeholder
                delegate?.didChangeText(isTyping: false)
                return false
            }
        }
        return true
    }
    
    // Update placeholder visibility on text change
    @objc func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
        delegate?.didChangeText(isTyping: true)
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        delegate?.didChangeText(isTyping: true)
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        delegate?.didChangeText(isTyping: false)
    }
}
