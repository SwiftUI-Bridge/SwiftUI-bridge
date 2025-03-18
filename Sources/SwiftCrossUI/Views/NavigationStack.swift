// import Gtk

// /// Type to indicate the root of the NavigationStack. This is internal to prevent root accidentally showing instead
// /// of a detail view.
// struct NavigationStackRootPath: Codable {}

// /// A view that displays a root view and enables you to present additional views over the root view.
// ///
// /// Use .navigationDestination(for:destination:) on this view instead of its children unlike Apples SwiftUI API.
// public struct NavigationStack<Detail: View>: View {
//     public var body: NavigationStackContent<Detail>

//     /// The type of transition to use when a new navigation destination is displayed.
//     private var transitionType: StackTransitionType
//     /// The duration of transition to use (in milliseconds).
//     private var transitionMilliseconds: Int
//     private var path: Binding<NavigationPath>

//     /// Creates a navigation stack with heterogeneous navigation state that you can control.
//     ///
//     /// - Parameters:
//     ///   - path: A `Binding` to the navigation state for this stack.
//     ///   - root: The view to display when the stack is empty.
//     public init(
//         path: Binding<NavigationPath>,
//         @ViewContentBuilder _ root: @escaping () -> Detail
//     ) {
//         self.path = path
//         transitionType = .slideLeftRight
//         transitionMilliseconds = 300
//         body = NavigationStackContent(path, []) { element in
//             if element is NavigationStackRootPath {
//                 return root()
//             } else {
//                 return nil
//             }
//         }
//     }

//     /// Associates a destination view with a presented data type for use within a navigation stack.
//     ///
//     /// Add this view modifer to describe the view that the stack displays when presenting a particular
//     /// kind of data. Use a `NavigationLink` to present the data. You can add more than one navigation
//     /// destination modifier to the stack if it needs to present more than one kind of data.
//     ///
//     /// - Parameters:
//     ///   - data: The type of data that this destination matches.
//     ///   - destination: A view builder that defines a view to display when the stack’s navigation
//     ///     state contains a value of type data. The closure takes one argument, which is the value
//     ///     of the data to present.
//     public func navigationDestination<D: Codable, C: View>(
//         for data: D.Type, @ViewContentBuilder destination: @escaping (D) -> C
//     ) -> NavigationStack<EitherView<Detail, C>> {
//         return NavigationStack<EitherView<Detail, C>>(
//             previous: self,
//             destination: destination
//         )
//     }

//     /// Sets the transition to use when changing navigation destinations.
//     ///
//     /// - Parameters:
//     ///   - transition: The type of animation that will be used for transitions between pages in the
//     ///     stack.
//     ///   - duration: Duration of the transition animation in seconds.
//     public func navigationTransition(_ transition: StackTransitionType, duration: Double)
//         -> some View
//     {
//         var view = self
//         view.transitionType = transition
//         view.transitionMilliseconds = Int(duration * 1000)
//         return view
//     }

//     public func asWidget(_ children: NavigationStackChildren<Detail>) -> GtkStack {
//         return children.storage.container
//     }

//     public func update(_ widget: GtkStack, children: Content.Children) {
//         widget.transitionType = transitionType
//         widget.transitionDuration = transitionMilliseconds
//     }

//     /// Add a destination for a specific path element
//     private init<PreviousDetail: View, NewDetail: View, Component: Codable>(
//         previous: NavigationStack<PreviousDetail>,
//         destination: @escaping (Component) -> NewDetail?
//     ) where Detail == EitherView<PreviousDetail, NewDetail> {
//         path = previous.path
//         transitionType = previous.transitionType
//         transitionMilliseconds = previous.transitionMilliseconds
//         body = NavigationStackContent(path, previous.body.destinationTypes + [Component.self]) {
//             if let previous = previous.body.child($0) {
//                 // Either root or previously defined destination returned a view
//                 return EitherView(previous)
//             } else if let component = $0 as? Component, let new = destination(component) {
//                 // This destination returned a detail view for the current element
//                 return EitherView(new)
//             } else {
//                 // Possibly a future .navigationDestination will handle this path element
//                 return nil
//             }
//         }
//     }
// }

// public struct NavigationStackContent<Child: View>: ViewContent {
//     public typealias Children = NavigationStackChildren<Child>

//     public var path: Binding<NavigationPath>

//     public var destinationTypes: [any Codable.Type]

//     public var child: (any Codable) -> Child?

//     public var elements: [any Codable] {
//         let resolvedPath = path.wrappedValue.path(
//             destinationTypes: destinationTypes
//         )
//         return [NavigationStackRootPath()] + resolvedPath
//     }

//     func childOrCrash(for element: any Codable) -> Child {
//         guard let child = child(element) else {
//             fatalError(
//                 "Failed to find detail view for \"\(element)\", make sure you have called .navigationDestination for this type."
//             )
//         }

//         return child
//     }

//     internal init(
//         _ path: Binding<NavigationPath>,
//         _ destinationTypes: [any Codable.Type],
//         _ child: @escaping (any Codable) -> Child?
//     ) {
//         self.path = path
//         self.destinationTypes = destinationTypes
//         self.child = child
//     }
// }

// public struct NavigationStackChildren<Child: View>: ViewGraphNodeChildren {
//     public typealias Content = NavigationStackContent<Child>

//     class Storage {
//         /// When a view is popped we store it in here to remove from the stack
//         /// the next time views are added. This allows them to animate out.
//         var widgetsQueuedForRemoval: [Widget] = []
//         var nodes: [ViewGraphNode<Child>] = []
//         var container = GtkStack(transitionDuration: 300, transitionType: .slideLeftRight)
//     }

//     let storage = Storage()
//     /// This could be set to false for NavigationSplitView in the future
//     let alwaysShowTopView = true

//     public var widgets: [GtkWidget] {
//         return [storage.container]
//     }

//     public init(from content: Content) {
//         storage.nodes = content.elements
//             .map(content.childOrCrash)
//             .map(ViewGraphNode.init)

//         for (index, node) in storage.nodes.enumerated() {
//             storage.container.add(node.widget, named: pageName(for: index))
//         }
//     }

//     public func update(with content: Content) {
//         // content.elements is a computed property so only get it once
//         let contentElements = content.elements

//         // Remove queued pages
//         for widget in storage.widgetsQueuedForRemoval {
//             storage.container.remove(widget)
//         }
//         storage.widgetsQueuedForRemoval = []

//         // Update pages
//         for (i, node) in storage.nodes.enumerated() {

//             guard i < contentElements.count else {
//                 break
//             }
//             let index = contentElements.startIndex.advanced(by: i)
//             node.update(with: content.childOrCrash(for: contentElements[index]))
//         }

//         let remaining = contentElements.count - storage.nodes.count
//         if remaining > 0 {
//             // Add new pages
//             for i in storage.nodes.count..<(storage.nodes.count + remaining) {
//                 let node = ViewGraphNode(
//                     for: content.childOrCrash(for: contentElements[i])
//                 )
//                 storage.nodes.append(node)
//                 storage.container.add(node.widget, named: pageName(for: i))
//             }
//             // Animate showing the new top page
//             if alwaysShowTopView, let top = storage.nodes.last?.widget {
//                 storage.container.setVisible(top)
//             }
//         } else if remaining < 0 {
//             // Animate back to the last page that was not popped
//             if alwaysShowTopView, !contentElements.isEmpty {
//                 let top = storage.nodes[contentElements.count - 1]
//                 storage.container.setVisible(top.widget)
//             }

//             // Queue popped pages for removal
//             let unused = -remaining
//             for i in (storage.nodes.count - unused)..<storage.nodes.count {
//                 storage.widgetsQueuedForRemoval.append(storage.nodes[i].widget)
//             }
//             storage.nodes.removeLast(unused)
//         }
//     }

//     private func pageName(for index: Int) -> String {
//         return "NavigationStack page \(index)"
//     }
// }
