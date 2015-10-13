//
//  TokenEditForm.swift
//  Authenticator
//
//  Copyright (c) 2015 Matt Rubin
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of
//  this software and associated documentation files (the "Software"), to deal in
//  the Software without restriction, including without limitation the rights to
//  use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
//  the Software, and to permit persons to whom the Software is furnished to do so,
//  subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//  FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//  IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

import OneTimePasswordLegacy

protocol TokenEditFormDelegate: class {
    func editFormDidCancel(form: TokenEditForm)
    func form(form: TokenEditForm, didEditToken token: OTPToken)
}

class TokenEditForm: NSObject, TokenForm {
    weak var presenter: TokenFormPresenter?
    private weak var delegate: TokenEditFormDelegate?

    private struct State {
        var issuer: String
        var name: String

        var isValid: Bool {
            return !(issuer.isEmpty && name.isEmpty)
        }
    }

    private var state: State {
        didSet {
            presenter?.formValuesDidChange(self)
        }
    }

    private let issuerCell = OTPTextFieldCell()
    private let accountNameCell = OTPTextFieldCell()

    var viewModel: TableViewModel {
        return TableViewModel(
            title: "Edit Token",
            leftBarButton: BarButtonViewModel(style: .Cancel) { [weak self] in
                self?.cancel()
            },
            rightBarButton: BarButtonViewModel(style: .Done, enabled: state.isValid) { [weak self] in
                self?.submit()
            },
            sections: [
                [
                    issuerCell,
                    accountNameCell,
                ]
            ]
        )
    }

    private var issuerRowModel: TextFieldRowModel {
        return IssuerRowModel(
            initialValue: state.issuer,
            changeAction: { [weak self] (newIssuer) -> () in
                self?.state.issuer = newIssuer
            }
        )
    }

    private var nameRowModel: TextFieldRowModel {
        return NameRowModel(
            initialValue: state.name,
            returnKeyType: .Done,
            changeAction: { [weak self] (newName) -> () in
                self?.state.name = newName
            }
        )
    }

    let token: OTPToken

    init(token: OTPToken, delegate: TokenEditFormDelegate) {
        self.token = token
        self.delegate = delegate
        state = State(issuer: token.issuer, name: token.name)

        super.init()
        // Configure cells
        issuerCell.updateWithRowModel(issuerRowModel)
        accountNameCell.updateWithRowModel(nameRowModel)

        issuerCell.delegate = self
        accountNameCell.delegate = self
    }

    func unfocus() {
        issuerCell.textField.resignFirstResponder()
        accountNameCell.textField.resignFirstResponder()
    }

    func cancel() {
        delegate?.editFormDidCancel(self)
    }

    func submit() {
        if (!state.isValid) { return }

        if (token.name != state.name ||
            token.issuer != state.issuer) {
                self.token.name = state.name
                self.token.issuer = state.issuer
                self.token.saveToKeychain()
        }

        delegate?.form(self, didEditToken: token)
    }
}

extension TokenEditForm: OTPTextFieldCellDelegate {
    func textFieldCellDidReturn(textFieldCell: OTPTextFieldCell) {
        if textFieldCell == issuerCell {
            accountNameCell.textField.becomeFirstResponder()
        } else if textFieldCell == accountNameCell {
            accountNameCell.textField.resignFirstResponder()
            submit()
        }
    }
}
