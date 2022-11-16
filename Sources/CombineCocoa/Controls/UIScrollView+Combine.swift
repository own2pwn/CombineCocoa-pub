//
//  UIScrollView+Combine.swift
//  CombineCocoa
//
//  Created by Joan Disho on 09/08/2019.
//  Copyright © 2020 Combine Community. All rights reserved.
//

#if canImport(Combine)
import UIKit
import Combine

@available(iOS 13.0, *)
public extension UIScrollView {
    /// A publisher emitting content offset changes from this UIScrollView.
    var contentOffsetPublisher: AnyPublisher<CGPoint, Never> {
        publisher(for: \.contentOffset)
            .eraseToAnyPublisher()
    }

    var willBeginDraggingPublisher: AnyPublisher<Void, Never> {
        let selector = #selector(UIScrollViewDelegate.scrollViewWillBeginDragging(_:))
        return delegateProxy.interceptSelectorPublisher(selector)
            .map { _ in }
            .eraseToAnyPublisher()
    }

    var didScrollPublisher: AnyPublisher<Void, Never> {
        return contentOffsetPublisher
            .map { _ in }
            .eraseToAnyPublisher()
    }

    var didEndDraggingPublisher: AnyPublisher<Bool, Never> {
        let selector = #selector(UIScrollViewDelegate.scrollViewDidEndDragging(_:willDecelerate:))
        return delegateProxy.interceptSelectorPublisher(selector)
            .map { (args: [Any]) -> Bool in
                if args.count >= 2, let decelerate = args[1] as? Bool {
                    return decelerate
                }
                return false
            }.eraseToAnyPublisher()
    }

    /// A publisher emitting if the bottom of the UIScrollView is reached.
    ///
    /// - parameter offset: A threshold indicating how close to the bottom of the UIScrollView this publisher should emit.
    ///                     Defaults to 0
    /// - returns: A publisher that emits when the bottom of the UIScrollView is reached within the provided threshold.
    func reachedBottomPublisher(offset: CGFloat = 0) -> AnyPublisher<Void, Never> {
        contentOffsetPublisher
            .map { [weak self] contentOffset -> Bool in
                guard let self = self else { return false }
                let visibleHeight = self.frame.height - self.contentInset.top - self.contentInset.bottom
                let yDelta = contentOffset.y + self.contentInset.top
                let threshold = max(offset, self.contentSize.height - visibleHeight)
                return yDelta > threshold
            }
            .removeDuplicates()
            .filter { $0 }
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    private var delegateProxy: ScrollViewDelegateProxy {
        .createDelegateProxy(for: self)
    }
}

@available(iOS 13.0, *)
private class ScrollViewDelegateProxy: DelegateProxy, UIScrollViewDelegate, DelegateProxyType {
    func setDelegate(to object: UIScrollView) {
        object.delegate = self
    }
}

#endif
