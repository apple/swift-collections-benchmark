extension Sequence {
  public func kalimbaOrdered() -> [Element] {
    var kalimba: [Element] = []
    kalimba.reserveCapacity(underestimatedCount)
    var insertAtStart = false
    for element in self {
      if insertAtStart {
        kalimba.insert(element, at: 0)
      } else {
        kalimba.append(element)
      }
      insertAtStart.toggle()
    }
    return kalimba
  }
}

// import Collections

// extension Sequence {
//   public func kalimbaOrdered() -> Deque<Element> {
//     var kalimba: Deque<Element> = []
//     kalimba.reserveCapacity(underestimatedCount)
//     var insertAtStart = false
//     for element in self {
//       if insertAtStart {
//         kalimba.prepend(element)
//       } else {
//         kalimba.append(element)
//       }
//       insertAtStart.toggle()
//     }
//     return kalimba
//   }
// }