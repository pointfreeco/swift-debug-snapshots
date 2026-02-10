extension String {
  func indenting(by count: Int) -> String {
    indenting(with: String(repeating: " ", count: count))
  }

  fileprivate func indenting(with prefix: String) -> String {
    guard !prefix.isEmpty else { return self }
    return """
      \(prefix)\
      \(split(separator: "\n", omittingEmptySubsequences: false).joined(separator: "\n\(prefix)"))
      """
  }
}
