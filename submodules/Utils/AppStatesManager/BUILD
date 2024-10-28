
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "AppStatesManager",
    module_name = "AppStatesManager",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    copts = [
        "-warnings-as-errors",
    ],
    deps = [
        "//submodules/SSignalKit/SwiftSignalKit:SwiftSignalKit",
        "//submodules/Postbox:Postbox",
        "//submodules/TelegramCore:TelegramCore",
        "//submodules/MtProtoKit:MtProtoKit",
        "//submodules/TelegramUIPreferences:TelegramUIPreferences",
        "//submodules/TelegramNotices:TelegramNotices",
         "//submodules/Utils/PeerSecretsManager",
    ],
    visibility = [
        "//visibility:public",
    ],
)
