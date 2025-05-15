//
//  Copyright © 2015 Tomas Linhart. All rights reserved.
//

import CGtk

public class ApplicationWindow: Window {
    public convenience init(application: Application) {
        self.init(
            gtk_application_window_new(application.applicationPointer)
        )
    }

    @GObjectProperty(named: "show-menubar") public var showMenuBar: Bool
}
