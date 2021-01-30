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
    
    /// `catchError` operator
    /// エラー検知時に、任意のデータに置き換える(Reactive ExtensionsでいうところのflatMapError)
    func testCatchError() throws {
        let onNextExp = expectation(description: "onNext invocations")
        onNextExp.expectedFulfillmentCount = 2
        let onNextExpectedResult = ["aaa", "zzz"]
        var onNextExpectedActual = [String]()
        let errObservable = Observable<String>.create { observer -> Disposable in
            observer.onNext("aaa")
            observer.onError(TestError.test)
            observer.onCompleted()
            return Disposables.create()
        }
        errObservable
            .catchError({ error -> Observable<String> in
                switch error {
                case is TestError:
                    return .just("zzz")
                default:
                    return .empty()
                }
            })
            .subscribe { str in
                print("onNext: \(str)")
                onNextExpectedActual.append(str)
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
        XCTAssertEqual(onNextExpectedResult, onNextExpectedActual)
    }
    
    /// `materialize`
    /// ストリームをEvent<T>へ変換
    /// 正常系/異常系へのストリーム分岐ができる
    /// 異常系(Error)をハンドリングするためのストリームをつくれる
    /// catchErrorでflatMapされた値を受け取るでなく、元のエラーをsubscribe側でハンドリングしたいときに便利
    /// materializeされたObservableからelements/errorsの分岐には以下Extensionをつかうと便利
    /// https://github.com/RxSwiftCommunity/RxSwiftExt#errors-elements
    /// https://github.com/RxSwiftCommunity/RxSwiftExt/blob/main/Source/RxSwift/materialized+elements.swift
    func testMaterialize() {
        let expOnNext = expectation(description: "onNext")
        expOnNext.expectedFulfillmentCount = 1
        let expOnError = expectation(description: "onError")
        expOnError.expectedFulfillmentCount = 1
        let observable = Observable<String>.create { observer -> Disposable in
            observer.onNext("aaa")
            observer.onError(TestError.test)
            return Disposables.create()
        }
        let result = observable.materialize()
        // 正常系(エラーが流れないストリーム)
        let elements = result
            .compactMap { $0.element }
        // 異常系(エラーをイベントとして流すストリーム)
        let errors = result
            .compactMap { $0.error }
        
        elements
            .subscribe(onNext: { str in
                print("onNext: \(str)")
                expOnNext.fulfill()
            })
            .disposed(by: disposeBag)
        
        errors
            .subscribe(onNext: { error in
                print("onError: \(error)")
                expOnError.fulfill()
            })
            .disposed(by: disposeBag)
        wait(for: [expOnNext, expOnError], timeout: 5)
    }
}

