//
//  OmnibarScreenAutocomplete.swift
//  Ello
//
//  Created by Colin Gray on 2/2/2016.
//  Copyright (c) 2016 Ello. All rights reserved.
//

// MARK: UITextViewDelegate
extension OmnibarScreen: UITextViewDelegate {
    private func throttleAutoComplete(textView: UITextView, range: NSRange) {
        self.autoCompleteThrottle { [weak self] in
            let autoComplete = AutoComplete()
            // deleting characters yields a range.length > 0, go back 1 character for deletes
            let location = range.length > 0 && range.location > 0 ? range.location - 1 : range.location
            let text = textView.text
            if let match = autoComplete.check(text, location: location) {
                self?.autoCompleteVC.load(match) { count in
                    if text != textView.text { return }

                    if count > 0 {
                        self?.showAutoComplete(textView, count: count)
                    }
                    else if count == 0 {
                        self?.hideAutoComplete(textView)
                    }
                }
            } else {
                self?.hideAutoComplete(textView)
            }
        }
    }

    public func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText: String) -> Bool {
        if autoCompleteShowing && emojiKeyboardShowing() {
            return false
        }

        throttleAutoComplete(textView, range: range)
        nextTick { self.textViewDidChange(textView) }
        return true
    }

    public func textViewDidChange(textView: UITextView) {
        if let path = currentTextPath
            where regionsTableView.cellForRowAtIndexPath(path) != nil
        {
            var currentText = textView.attributedText
            if currentText.string.characters.count == 0 {
                currentText = ElloAttributedString.style("")
                textView.typingAttributes = ElloAttributedString.attrs()
                boldButton.selected = false
                italicButton.selected = false
            }

            updateText(currentText, atPath: path)
        }
        updateButtons()
    }

    public func textViewDidChangeSelection(textView: UITextView) {
        let font = textView.typingAttributes[NSFontAttributeName] as? UIFont
        let fontName = font?.fontName ?? "AtlasGrotesk-Regular"

        switch fontName {
        case UIFont.editorItalicFont().fontName:
            boldButton.selected = false
            italicButton.selected = true
        case UIFont.editorBoldFont().fontName:
            boldButton.selected = true
            italicButton.selected = false
        case UIFont.editorBoldItalicFont().fontName:
            boldButton.selected = true
            italicButton.selected = true
        default:
            boldButton.selected = false
            italicButton.selected = false
        }

        if let _ = textView.typingAttributes[NSLinkAttributeName] as? NSURL {
            linkButton.selected = true
            linkButton.enabled = true
        }
        else if let selection = textView.selectedTextRange
        where selection.empty {
            linkButton.selected = false
            linkButton.enabled = false
        }
        else {
            linkButton.selected = false
            linkButton.enabled = true
        }
    }

    private func emojiKeyboardShowing() -> Bool {
        return textView.textInputMode?.primaryLanguage == nil || textView.textInputMode?.primaryLanguage == "emoji"
    }

    func hideAutoComplete(textView: UITextView) {
        if autoCompleteShowing {
            autoCompleteShowing = false
            textView.autocorrectionType = .Yes
            textView.inputAccessoryView = keyboardButtonView
            textView.resignFirstResponder()
            textView.becomeFirstResponder()
        }
    }

    private func showAutoComplete(textView: UITextView, count: Int) {
        if !autoCompleteShowing {
            autoCompleteShowing = true
            textView.autocorrectionType = .No
            let container = UIView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: 1))
            container.addSubview(autoCompleteContainer)
            textView.inputAccessoryView = container
            textView.resignFirstResponder()
            textView.becomeFirstResponder()
        }

        let height = AutoCompleteCell.cellHeight() * min(CGFloat(3.5), CGFloat(count))
        let constraintIndex = textView.inputAccessoryView?.constraints.indexOf { $0.firstAttribute == .Height }
        if let index = constraintIndex,
            inputAccessoryView = textView.inputAccessoryView,
            constraint = inputAccessoryView.constraints.safeValue(index)
        {
            constraint.constant = height
            inputAccessoryView.setNeedsUpdateConstraints()
            inputAccessoryView.frame.size.height = height
            inputAccessoryView.setNeedsLayout()
        }
        autoCompleteContainer.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: height)
        autoCompleteVC.view.frame = autoCompleteContainer.bounds
    }
}


extension OmnibarScreen: AutoCompleteDelegate {
    public func itemSelected(item: AutoCompleteItem) {
        if let name = item.result.name {
            let prefix: String
            let suffix: String
            if item.type == .Username {
                prefix = "@"
                suffix = ""
            }
            else {
                prefix = ":"
                suffix = ":"
            }

            let newText = textView.text.stringByReplacingCharactersInRange(item.match.range, withString: "\(prefix)\(name)\(suffix) ")
            let currentText = ElloAttributedString.style(newText)
            textView.attributedText = currentText
            textViewDidChange(textView)
            updateButtons()
            hideAutoComplete(textView)
        }
    }
}