
import SwiftUI

public struct Slide<Header: View, Content: View, Footer: View, Notes: View>: View {

    @Environment(\.slideStyle) private var style
    @Environment(\.currentSlide) private var currentSlide
    private let id = SlideID()
    private let content: Content
    private let header: Header
    private let footer: Footer
    private let notes: () -> Notes

    public init(
        @ViewBuilder content: () -> Content,
        @ViewBuilder header: () -> Header,
        @ViewBuilder footer: () -> Footer,
        @ViewBuilder notes: @escaping () -> Notes
    ) {
        self.content = content()
        self.header = header()
        self.footer = footer()
        self.notes = notes
    }

    public var body: some View {
        Group {
            if id == currentSlide {
                let configuration = SlideConfiguration(
                    content: content,
                    header: header,
                    footer: footer)

                AnyView(style.resolve(configuration: configuration))
            } else {
                Color.clear
            }
        }
        .register(slide: SlideInfo(id: id, notes: notes))
    }
}

// MARK: - Initialisers

extension Slide {

    public init(
        header: LocalizedStringKey,
        footer: LocalizedStringKey,
        @ViewBuilder content: () -> Content
    ) where Header == Text, Footer == Text, Notes == EmptyView {
        self.init {
            content()
        } header: {
            Text(header)
        } footer: {
            Text(footer)
        } notes: {
            EmptyView()
        }
    }

    public init(
        header: LocalizedStringKey,
        footer: LocalizedStringKey,
        notes: LocalizedStringKey,
        @ViewBuilder content: () -> Content
    ) where Header == Text, Footer == Text, Notes == Text {
        self.init {
            content()
        } header: {
            Text(header)
        } footer: {
            Text(footer)
        } notes: {
            Text(notes)
        }
    }

    public init(
        @ViewBuilder content: () -> Content,
        @ViewBuilder header: () -> Header
    ) where Footer == EmptyView, Notes == EmptyView {
        self.init(
            content: content,
            header: header,
            footer: EmptyView.init,
            notes: EmptyView.init)
    }

    public init(
        @ViewBuilder content: () -> Content,
        @ViewBuilder header: () -> Header,
        @ViewBuilder notes: @escaping () -> Notes
    ) where Footer == EmptyView {
        self.init(
            content: content,
            header: header,
            footer: EmptyView.init,
            notes: notes)
    }

    public init(
        header: LocalizedStringKey,
        @ViewBuilder content: () -> Content
    ) where Header == Text, Footer == EmptyView, Notes == EmptyView {
        self.init {
            content()
        } header: {
            Text(header)
        }
    }

    public init(
        header: LocalizedStringKey,
        @ViewBuilder content: () -> Content,
        @ViewBuilder notes: @escaping () -> Notes
    ) where Header == Text, Footer == EmptyView {
        self.init {
            content()
        } header: {
            Text(header)
        } notes: {
            notes()
        }
    }

    public init(
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) where Header == EmptyView, Notes == EmptyView {
        self.init(
            content: content,
            header: EmptyView.init,
            footer: footer,
            notes: EmptyView.init)
    }

    public init(
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer,
        @ViewBuilder notes: @escaping () -> Notes
    ) where Header == EmptyView {
        self.init(
            content: content,
            header: EmptyView.init,
            footer: footer,
            notes: notes)
    }

    public init(
        footer: LocalizedStringKey,
        @ViewBuilder content: () -> Content
    ) where Header == EmptyView, Footer == Text, Notes == EmptyView {
        self.init {
            content()
        } footer: {
            Text(footer)
        }
    }

    public init(
        footer: LocalizedStringKey,
        notes: LocalizedStringKey,
        @ViewBuilder content: () -> Content
    ) where Header == EmptyView, Footer == Text, Notes == Text {
        self.init {
            content()
        } footer: {
            Text(footer)
        } notes: {
            Text(notes)
        }
    }

    public init(
        @ViewBuilder content: () -> Content
    ) where Header == EmptyView, Footer == EmptyView, Notes == EmptyView {
        self.init(
            content: content,
            header: EmptyView.init,
            footer: EmptyView.init,
            notes: EmptyView.init)
    }

    public init(
        @ViewBuilder content: () -> Content,
        @ViewBuilder notes: @escaping () -> Notes
    ) where Header == EmptyView, Footer == EmptyView {
        self.init(
            content: content,
            header: EmptyView.init,
            footer: EmptyView.init,
            notes: notes)
    }
}

// MARK: - Plain Style

extension SlideStyle where Self == PlainSlideStyle {

    public static var plain: Self { PlainSlideStyle() }
}

public struct PlainSlideStyle: SlideStyle {

    public func makeBody(configuration: Configuration) -> some View {
        VStack {

            configuration.header
                .font(.system(size: 60, weight: .bold))
                .padding(20)

            configuration.content
                .font(.system(size: 30, weight: .regular))
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            configuration.footer
                .font(.system(size: 20, weight: .regular))
                .padding(20)
        }
        .background(.white)
    }
}

// MARK: - Style

public protocol SlideStyle: DynamicProperty {

    typealias Configuration = SlideConfiguration
    associatedtype Body: View

    @ViewBuilder func makeBody(configuration: Configuration) -> Body
}

extension View {

    public func slideStyle(_ style: some SlideStyle) -> some View {
        environment(\.slideStyle, style)
    }
}

extension Scene {

    public func slideStyle(_ style: some SlideStyle) -> some Scene {
        environment(\.slideStyle, style)
    }
}

// MARK: Configuration

public struct SlideConfiguration {

    public struct Content: View {
        fileprivate let base: AnyView
        public var body: some View { base }
    }

    public struct Header: View {
        fileprivate let base: AnyView
        public var body: some View { base }
    }

    public struct Footer: View {
        fileprivate let base: AnyView
        public var body: some View { base }
    }

    public let content: Content
    public let header: Header
    public let footer: Footer

    fileprivate init(
        content: some View,
        header: some View,
        footer: some View
    ) {
        self.content = Content(base: AnyView(content))
        self.header = Header(base: AnyView(header))
        self.footer = Footer(base: AnyView(footer))
    }
}

// MARK: Environment

private struct SlideStyleKey: EnvironmentKey {
    static var defaultValue: any SlideStyle = .plain
}

extension EnvironmentValues {

    fileprivate var slideStyle: any SlideStyle {
        get { self[SlideStyleKey.self] }
        set { self[SlideStyleKey.self] = newValue }
    }
}

// MARK: Resolution

extension SlideStyle {

    fileprivate func resolve(configuration: Configuration) -> some View {
        ResolvedSlideStyle(style: self, configuration: configuration)
    }
}

private struct ResolvedSlideStyle<Style: SlideStyle>: View {

    let style: Style
    let configuration: Style.Configuration

    var body: some View {
        style.makeBody(configuration: configuration)
    }
}
