//
//  rxswiftsandboxTests.swift
//  rxswiftsandboxTests
//
//  Created by hrfm mr on 2021/01/30.
//

import XCTest
import RxSwift
@testable import rxswiftsandbox

enum TestError: Error {
    case test
}

class rxswiftsandboxTests: XCTestCase {
    private let disposeBag = DisposeBag()

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

    /// `retry` operator
    /// retryはエラー発生時にobserverに即座に通知せず、
    /// 自動でストリームのre-subscribeを行う
    func testErrorRetry() throws {
        let onNextExp = expectation(description: "onNext invocations")
        onNextExp.expectedFulfillmentCount = 3
        let errObservable = Observable<String>.create { observer -> Disposable in
            // エラー発生しても自動subscribeがretry count分行われるので、
            // このonNextがretry試行回数分流れる
            observer.onNext("aaa")
            observer.onError(TestError.test)
            print("Error encountered")
            observer.onNext("bbb")
            observer.onCompleted()
            return Disposables.create()
        }
        errObservable
            .retry(3)
            .subscribe { str in
                print("onNext: \(str)")
                onNextExp.fulfill()
            } onError: { error in
                print("onError: \(error)")
            } onCompleted: {
                print("onCompleted")
            } onDisposed: {
                print("onDisposed")
            }
            .disposed(by: disposeBag)
        wait(for: [onNextExp], timeout: 5)
    }
}
