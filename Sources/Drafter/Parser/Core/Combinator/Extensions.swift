//
//  Extensions.swift
//  Drafter
//
//  Created by LZephyr on 2017/10/31.
//

import Foundation

extension Parser {
    
    /// 多次重复该parser直到失败为止，将结果保存在数组中返回，如果结果数组为空则返回错误
    var many: Parser<[T]> {
        return Parser<[T]> { (tokens) -> Result<([T], Tokens)> in
            var result = [T]()
            var remainder = tokens
            while true {
                switch self.parse(remainder) {
                case .success(let (r, rest)):
                    result.append(r)
                    remainder = rest
                case .failure(let error):
                    if result.count == 0 {
                        return .failure(error)
                    } else {
                        #if DEBUG
                            print("many parse stop: \(error)")
                        #endif
                        return .success((result, remainder))
                    }
                }
            }
        }
    }
    
    /// 解析一串由指定标签分隔的值，返回包含所有成功解析的值, 至少有两个结果才会返回成功
    func separateBy<U>(_ p: Parser<U>) -> Parser<[T]> {
        return curry({ $0 + [$1] }) <^> (self <* p).many <*> self
    }
    
    /// 解析包含在指定标签之间的值: p self p
    func between<A, B>(_ left: Parser<A>, _ right: Parser<B>) -> Parser<T> {
        return left *> self <* right
    }
    
    /// 仅当self成功，other失败时才会返回成功，other不会消耗任何输入
    func notFollowedBy<U>(_ other: Parser<U>) -> Parser<T> {
        return self.flatMap { result in
            Parser<T> { (tokens) -> Result<(T, Tokens)> in
                if case .failure(_) = other.parse(tokens) { // other失败才会返回成功
                    return .success((result, tokens))
                } else {
                    return .failure(.custom("notFollowedBy fail"))
                }
            }
        }
    }
}